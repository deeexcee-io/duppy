#!/usr/bin/env bash
set -euo pipefail

blue="\033[0;94m"
green="\033[0;92m"
yellow="\033[0;93m"
red="\033[0;91m"
NC="\033[0m"

cat <<'EOF'
      _
     | |
   __| | _   _  _ __   _ __   _   _
  / _` || | | || '_ \ | '_ \ | | | |
 | (_| || |_| || |_) || |_) || |_| |
  \__,_| \__,_|| .__/ | .__/  \__, |
               | |    | |      __/ |
               |_|    |_|     |___/

download and upload python flask app

wrapped with bash

EOF

api_hist=""
NGROK_URL="http://127.0.0.1:4040/api/requests/http?limit=1"
PROJECT_DIR=""
APT_UPDATED=0
NGROK_PID=""
BASIC_AUTH="${DUPPY_BASIC_AUTH:-user:SuperPassword}"
LOG_FILE="/tmp/duppy_ngrok.log"
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_MODE=""
BIND_ADDRESS="127.0.0.1"
CERT_DIR="${SCRIPT_ROOT}/.tls"
CERT_FILE="${CERT_DIR}/duppy.crt"
KEY_FILE="${CERT_DIR}/duppy.key"

if [ -n "${VIRTUAL_ENV:-}" ]; then
    VENV_DIR="${VIRTUAL_ENV%/}"
    USING_USER_VENV=1
else
    VENV_DIR="${SCRIPT_ROOT}/duppy-venv"
    USING_USER_VENV=0
fi
PYTHON_BIN="${VENV_DIR}/bin/python3"

log_info() {
    printf "\n[${green}+${NC}] %s" "$1"
}

log_warn() {
    printf "\n[${yellow}*${NC}] %s" "$1"
}

log_error() {
    printf "\n[${red}!${NC}] %s" "$1"
}

command_exists() {
    command -v "$1" > /dev/null 2>&1
}

set_run_mode() {
    local mode=$1
    case "$mode" in
        internet)
            RUN_MODE="internet"
            BIND_ADDRESS="127.0.0.1"
            log_info "Internet mode selected (ngrok tunnel)"
            ;;
        local)
            RUN_MODE="local"
            BIND_ADDRESS="0.0.0.0"
            log_info "Local network mode selected"
            ;;
    esac
}

choose_run_mode() {
    if [ -n "${DUPPY_MODE:-}" ]; then
        local normalized="${DUPPY_MODE,,}"
        if [[ "$normalized" == "internet" || "$normalized" == "local" ]]; then
            set_run_mode "$normalized"
            return
        else
            log_error "Invalid DUPPY_MODE value '${DUPPY_MODE}'. Use 'internet' or 'local'."
            exit 1
        fi
    fi

    while true; do
        printf "\nSelect mode:\n  [1] Internet (ngrok tunnel)\n  [2] Local network only\n"
        read -r -p "[?] Enter choice [1/2]: " selection
        case "${selection:-1}" in
            ""|1)
                set_run_mode internet
                return
                ;;
            2)
                set_run_mode local
                return
                ;;
            *)
                log_warn "Invalid selection. Please choose 1 or 2."
                ;;
        esac
    done
}

run_privileged() {
    if command_exists sudo && [ "$EUID" -ne 0 ]; then
        sudo "$@"
    else
        "$@"
    fi
}

update_apt_cache_once() {
    if [ "$APT_UPDATED" -eq 0 ]; then
        log_info "Updating package index"
        if run_privileged apt-get update -y > /dev/null 2>&1; then
            APT_UPDATED=1
        else
            log_error "Cannot update package index. Exiting."
            exit 1
        fi
    fi
}

install_apt_package() {
    local package=$1
    update_apt_cache_once
    if run_privileged apt-get install -y "$package" > /dev/null 2>&1; then
        log_info "$package installed"
    else
        log_error "Failed to install $package"
        exit 1
    fi
}

ensure_command() {
    local cmd=$1
    local package=$2
    if command_exists "$cmd"; then
        return
    fi
    log_warn "$cmd not found. Installing $package."
    install_apt_package "$package"
}

install_python_module() {
    local module=$1
    log_info "Installing python module ${module}"
    if "$PYTHON_BIN" -m pip install "$module" > /dev/null 2>&1; then
        log_info "${module} installed"
    else
        log_error "Unable to install python module ${module}"
        exit 1
    fi
}

ensure_pip_in_venv() {
    if "$PYTHON_BIN" -m pip --version > /dev/null 2>&1; then
        return
    fi

    log_warn "Python virtual environment is missing pip, attempting to bootstrap it"
    if "$PYTHON_BIN" -m ensurepip --upgrade > /dev/null 2>&1; then
        log_info "pip installed in virtual environment"
    else
        log_error "Unable to install pip inside the virtual environment"
        exit 1
    fi
}

ensure_virtualenv() {
    if [ -x "$PYTHON_BIN" ]; then
        ensure_pip_in_venv
        if [ "$USING_USER_VENV" -eq 1 ]; then
            log_info "Using active python virtual environment at ${VENV_DIR}"
        else
            log_info "Using python virtual environment at ${VENV_DIR}"
        fi
        return
    fi

    if [ "$USING_USER_VENV" -eq 1 ]; then
        log_error "Active virtual environment at ${VENV_DIR} does not provide python3"
        exit 1
    fi

    log_info "Creating python virtual environment in ${VENV_DIR}"
    if python3 -m venv "$VENV_DIR" > /dev/null 2>&1; then
        log_info "Virtual environment created"
    else
        log_error "Unable to create python virtual environment"
        exit 1
    fi

    ensure_pip_in_venv
}

ensure_tls_certificate() {
    if [ -f "$CERT_FILE" ] && [ -f "$KEY_FILE" ]; then
        log_info "Using existing TLS certificate (${CERT_FILE})"
        return
    fi

    log_info "Generating self-signed TLS certificate for local mode"
    if mkdir -p "$CERT_DIR" && openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$KEY_FILE" -out "$CERT_FILE" -subj "/CN=duppy.local" > /dev/null 2>&1; then
        log_info "TLS certificate created at ${CERT_DIR}"
    else
        log_error "Failed to create TLS certificate in ${CERT_DIR}"
        exit 1
    fi
}

prompt_yes_no() {
    local prompt=$1
    local response
    while true; do
        read -r -p "[?] ${prompt} [y/n]: " response
        case "${response,,}" in
            y|yes) return 0 ;;
            n|no) return 1 ;;
            *) log_warn "Please enter yes or no." ;;
        esac
    done
}

install_ngrok() {
    log_info "Adding ngrok apt repository"
    if ! run_privileged curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc -o /etc/apt/trusted.gpg.d/ngrok.asc; then
        log_error "Failed to download ngrok signing key"
        exit 1
    fi
    if ! printf "deb https://ngrok-agent.s3.amazonaws.com buster main\n" | run_privileged tee /etc/apt/sources.list.d/ngrok.list > /dev/null; then
        log_error "Failed to configure ngrok repository"
        exit 1
    fi
    APT_UPDATED=0
    install_apt_package ngrok
}

configure_ngrok_auth() {
    local config_file="${HOME}/.config/ngrok/ngrok.yml"
    if [ -f "$config_file" ] && grep -q "authtoken" "$config_file" 2>/dev/null; then
        return
    fi

    log_info "Ngrok auth token not detected."
    read -r -p "[?] Enter ngrok auth token (leave blank to skip): " auth_token
    if [ -n "${auth_token:-}" ]; then
        if ngrok config add-authtoken "$auth_token" > /dev/null 2>&1; then
            log_info "Auth token added"
        else
            log_warn "Unable to add auth token automatically. Please configure it manually."
        fi
    fi
}

ensure_ngrok() {
    if command_exists ngrok; then
        log_info "ngrok already installed"
    else
        log_warn "ngrok is not installed"
        if prompt_yes_no "Install ngrok now?"; then
            install_ngrok
        else
            log_error "ngrok is required. Exiting."
            exit 1
        fi
    fi
    configure_ngrok_auth
}

ensure_gunicorn() {
    if "$PYTHON_BIN" -c "import gunicorn" > /dev/null 2>&1; then
        log_info "gunicorn already installed"
        return
    fi

    log_warn "gunicorn python module is not installed"
    if prompt_yes_no "Install gunicorn now?"; then
        install_python_module gunicorn
    else
        log_error "gunicorn is required. Exiting."
        exit 1
    fi
}

ensure_flask() {
    if "$PYTHON_BIN" -c "import flask" > /dev/null 2>&1; then
        log_info "Flask already installed"
        return
    fi
    install_python_module flask
}

ensure_base_dependencies() {
    ensure_command curl curl
    ensure_command jq jq
    ensure_command git git
    ensure_command pgrep procps
    ensure_command python3 python3
    ensure_command openssl openssl
    if ! python3 -m pip --version > /dev/null 2>&1; then
        log_warn "python3-pip not found. Installing."
        install_apt_package python3-pip
    fi
    if ! python3 -m venv --help > /dev/null 2>&1; then
        log_warn "python3-venv not found. Installing."
        install_apt_package python3-venv
    fi
}

resolve_project_dir() {
    local script_root="$SCRIPT_ROOT"

    if [ -f "${script_root}/Uploader.py" ]; then
        PROJECT_DIR="${script_root}"
        return
    fi

    if [ -d "${script_root}/duppy" ] && [ -f "${script_root}/duppy/Uploader.py" ]; then
        PROJECT_DIR="${script_root}/duppy"
        return
    fi

    log_info "Pulling duppy repository"
    if git clone https://github.com/deeexcee-io/duppy.git "${script_root}/duppy" > /dev/null 2>&1; then
        PROJECT_DIR="${script_root}/duppy"
        log_info "duppy repository cloned"
    else
        log_error "Unable to clone duppy repository"
        exit 1
    fi
}

start_gunicorn() {
    log_info "Starting gunicorn server"
    local gunicorn_args=(-D -w 2 -b "${BIND_ADDRESS}:8000" --chdir "$PROJECT_DIR")
    if [ "$RUN_MODE" == "local" ]; then
        ensure_tls_certificate
        gunicorn_args+=(--keyfile "$KEY_FILE" --certfile "$CERT_FILE")
    fi
    if "$PYTHON_BIN" -m gunicorn "${gunicorn_args[@]}" Uploader:Uploader > /dev/null 2>&1; then
        log_info "gunicorn started successfully"
    else
        log_error "gunicorn failed to start"
        exit 1
    fi
}

start_ngrok() {
    log_info "Starting ngrok tunnel on port 8000"
    ngrok http 8000 --basic-auth="$BASIC_AUTH" > "$LOG_FILE" 2>&1 &
    NGROK_PID=$!
    sleep 1
    if ps -p "$NGROK_PID" > /dev/null 2>&1; then
        log_info "ngrok started successfully (pid ${NGROK_PID})"
    else
        log_error "ngrok failed to start. Check ${LOG_FILE} for details."
        exit 1
    fi
}

get_ngrok_public_url() {
    local attempt
    local public_url=""
    for attempt in $(seq 1 15); do
        if response=$(curl -sf http://127.0.0.1:4040/api/tunnels); then
            public_url=$(echo "$response" | jq -r '.tunnels[0].public_url // empty')
            if [ -n "$public_url" ]; then
                printf "\n[${green}+${NC}] Public URL: ${green}%s${NC}" "$public_url"
                return
            fi
        fi
        sleep 1
    done
    log_warn "Unable to determine ngrok public URL"
}

check_ngrok_api() {
    local api_data=""
    if ! api_data=$(curl -sf "$NGROK_URL" 2> /dev/null); then
        return
    fi

    local latest_request
    local latest_response
    latest_request=$(echo "$api_data" | jq -r '.requests[0].request.uri // empty')
    latest_response=$(echo "$api_data" | jq -r '.requests[0].response.status // empty')

    if [ -z "$latest_request" ] || [ -z "$latest_response" ]; then
        return
    fi

    if [ "$api_data" == "$api_hist" ]; then
        return
    fi

    local request_path="$latest_request"
    request_path="${request_path%%\?*}"
    if [ -n "$request_path" ] && [ "$request_path" != "/" ]; then
        request_path="${request_path%/}"
    fi

    local upload_dir="${PROJECT_DIR}/upload"
    if [ "$request_path" == "/done" ]; then
        sleep 1
        if [ -d "$upload_dir" ]; then
            local uploaded_file
            uploaded_file=$(ls -1t "$upload_dir" 2> /dev/null | head -n 1)
            if [ -n "$uploaded_file" ]; then
                printf "\n[${green}+${NC}] New File Uploaded: ${green}%s${NC}" "$uploaded_file"
            fi
        fi
    elif [[ "$request_path" == /download/* ]]; then
        local downloaded_file="${request_path#/download/}"
        printf "\n[${green}+${NC}] New File Downloaded: ${green}%s${NC}" "$downloaded_file"
    fi

    api_hist="$api_data"
}

print_local_access_info() {
    local host_ip
    host_ip=$(hostname -I 2> /dev/null | awk '{print $1}')
    if [ -z "$host_ip" ]; then
        host_ip="127.0.0.1"
    fi
    printf "\n[${green}+${NC}] Local access URL: ${green}https://%s:8000${NC}" "$host_ip"
    printf "\n[${green}+${NC}] Certificate path: ${CERT_FILE}"
    printf "\n[${green}+${NC}] Share/trust the certificate so testers avoid warnings."
}

cleanup() {
    printf "\n\n${yellow}Shutting down...${NC}\n"
    if pkill -f "gunicorn.*Uploader:Uploader" > /dev/null 2>&1; then
        log_info "gunicorn stopped"
    else
        log_warn "gunicorn process not found"
    fi

    if [ -n "$NGROK_PID" ] && ps -p "$NGROK_PID" > /dev/null 2>&1; then
        kill "$NGROK_PID"
        log_info "ngrok stopped"
    else
        pkill -x ngrok > /dev/null 2>&1 || true
    fi
    exit 0
}

trap cleanup SIGINT SIGTERM

main() {
    choose_run_mode
    ensure_base_dependencies
    ensure_virtualenv
    ensure_flask
    ensure_gunicorn
    resolve_project_dir
    start_gunicorn

    if [ "$RUN_MODE" == "internet" ]; then
        ensure_ngrok
        start_ngrok
        get_ngrok_public_url

        while true; do
            check_ngrok_api
            sleep 0.5
        done
    else
        print_local_access_info
        while true; do
            sleep 2
        done
    fi
}

main
