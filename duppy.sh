#!/bin/bash
blue="\033[0;94m"
green="\033[0;92m"
NC="\033[0m"

cat << 'EOF'
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

USER_PATH="$PATH"
USER_PYTHONPATH="$PYTHONPATH"

# Variable to store Ngrok API data history
api_hist=""

# Check Dependencies
start_standardtoolcheck() {
    if [ $(command -v curl) ] && [ $(command -v jq) ] && [ $(command -v sudo) ] && [ $(command -v git) ] && [ $(command -v pgrep) ] && [ $(command -v pip) ] && [ "$(python3 -c 'import flask' 2>/dev/null)" ]
    then
        printf "\n[${green}+$NC] standard tools installed......lets go"
        sleep 1
    else
        printf "\n[${green}+$NC] Updating Package Index"
        if apt update -y > /dev/null 2>&1; then
           printf "\n[${green}+$NC] Package Index Updated"
        else
           printf "\n[${green}+$NC] Cannot Update Package Index.....Exiting"
           exit 1
        fi
    fi

    if [ ! $(command -v sudo) ]
    then
            printf "\n[${green}+$NC] sudo not installed....installing"
            #if no sudo, likely we are root already. This (sudo) worth doing when spinning up a bare kali container
            if apt install sudo -y > /dev/null 2>&1; then
                printf "\n[${green}+$NC] sudo installed"
            fi
    fi

    if [ ! $(command -v git) ]
    then
            printf "\n[${green}+$NC] git not installed....installing"
            # To git clone the duppy repo
            if apt install git -y > /dev/null 2>&1; then
                printf "\n[${green}+$NC] git installed"
            fi
    fi

    if [ ! $(command -v jq) ]
        then
            printf "\n[${green}+$NC] jq not installed....installing"
            if apt install jq -y > /dev/null 2>&1; then
                printf "\n[${green}+$NC] jq installed"
            fi
    fi

    if [ ! $(command -v curl) ]
        then
            printf "\n[${green}+$NC] cURL not installed....installing"
            if apt install curl -y > /dev/null 2>&1; then
                printf "\n[${green}+$NC] cURL installed"
            fi
    fi

    if [ ! $(command -v pgrep) ]
        then
             printf "\n[${green}+$NC] cURL not installed....installing"
             if apt install procps -y > /dev/null 2>&1; then
               printf "\n[${green}+$NC] cURL installed"
            fi
    fi

    if [ ! $(command -v pip) ]
        then
             printf "\n[${green}+$NC] python pip not installed....installing"
             if apt install pip -y > /dev/null 2>&1; then
                printf "\n[${green}+$NC] python pip installed"
             fi
    fi

    if ! python3 -c "import flask" &> /dev/null
        then
             printf "\n[${green}+$NC] python module \"flask\" not installed....installing"
             if pip install flask > /dev/null 2>&1; then
                 printf "\n[${green}+$NC] python \"flask\" module installed"
             fi
    fi
}

start_precheck() {
        USER_PATH="$PATH"
        USER_PYTHONPATH="$PYTHONPATH"

        if [ $(command -v ngrok) ] && [ $(command -v gunicorn) ]
        then
                printf "\n[${green}+$NC] ngrok and gunicorn installed......lets go"
                sleep 1
        fi
        if [ ! $(command -v ngrok) ]
        then
                printf "\n[${green}+$NC] ngrok not installed\n"
                sleep 1
                read -rp $'[\033[0;92m+\033[0m] Do you want to install ngrok? (Y/N): ' response
                case "$response" in
                        [yY])
                                if curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list > /dev/null 2>&1 && sudo apt update > /dev/null 2>&1 && sudo apt install ngrok > /dev/null 2>&1; then
                                        if [ $(command -v ngrok) ]
                                        then
                                                printf "[${green}+$NC] ngrok successfully installed"
                                                printf "\n[${green}+$NC] Sign up for an account: https://dashboard.ngrok.com/signup, then get your auth token at https://dashboard.ngrok.com/get-started/your-authtoken and enter it below :\n"
                                                read -rp $'[\033[0;92m+\033[0m] Enter ngrok auth token:  ' auth_token
                                                if ngrok config add-authtoken $auth_token > /dev/null 2>&1; then
                                                        printf "[${green}+$NC] auth token added!"
                                                fi
                                                sleep 1
                                                #return 0
                                        fi
                                fi
                        ;;
                        [nN*])
                                printf "\n[${green}+$NC] No Probs......Exiting"
                                sleep 1
                                exit 1
                        ;;
                esac
        fi
        if [ ! $(command -v gunicorn) ]
        then
                printf "\n[${green}+$NC] gunicorn not installed\n"
                sleep 1
                read -rp $'[\033[0;92m+\033[0m] Do you want to install gunicorn? (Y/N): ' response
                case "$response" in
                        [yY])
                                if apt install gunicorn -y > /dev/null 2>&1; then
                                        if [ $(command -v gunicorn) ]
                                        then
                                                printf "[${green}+$NC] gunicorn successfully installed"
                                                sleep 1
                                        fi
                                fi
                        ;;
                        [nN*])
                                printf "\n[${green}+$NC] No Probs......Exiting"
                                sleep 1
                                exit 1
                        ;;
                esac
                sleep 1
        fi
        printf "\n[$green+$NC] Pulling duppy repo"
        directory="duppy/"
        if [ -d "$directory" ]; then
                printf "\n[$green+$NC] duppy already installed"
        elif git clone https://github.com/deeexcee-io/duppy.git > /dev/null 2>&1; then
                printf "\n[$green+$NC] duppy installed"
        else
                printf "\n[$green+$NC] error pulling repo....exiting"
                exit 1
        fi
}

# Function to start Gunicorn
start_gunicorn() {
    USER_PATH="$PATH"
    USER_PYTHONPATH="$PYTHONPATH"
    script_dir=$(dirname "{BASH_SOURCE[0]}")
    relative_dir="/duppy"
    if gunicorn -D -w 2 -b 127.0.0.1:8000 --chdir "$script_dir$relative_dir" Uploader:Uploader; then
        printf "\n[$green+$NC] gunicorn started"
        sleep 1
    else
        printf "\ngunicorn failed"
        exit 1
    fi
}

# Function to start Ngrok with basic authentication
start_ngrok() {
    #current_user=$SUDO_USER
    ngrok http 8000 --basic-auth="gd:SuperPassword" > /dev/null 2>&1 &
    sleep 1
    # Check if Ngrok started successfully
    if pgrep -x "ngrok" > /dev/null; then
        printf "\n[$green+$NC] ngrok started successfully"
        sleep 1
    else
        printf "\nngrok failed to start"
        exit 1
    fi
}

# Function to get Ngrok public URL
get_ngrok_public_url() {
    public_url=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')
    printf "\n[$green+$NC] Public URL: $green$public_url$NC"
}

# Function to check Ngrok API for incoming requests
check_ngrok_api() {
    # Use curl to get Ngrok API data for the latest request
    api_data=$(curl -s "$NGROK_URL")

    #pwd
    cwd="duppy/upload/"
    # Extract and display the details of the latest GET request
    latest_request=$(echo "$api_data" | jq -r '.requests[0]' | jq -r '.request.uri')
    latest_response=$(echo "$api_data" | jq -r '.requests[0]' | jq -r '.response.status')

    if [ -n "$api_data" ] && [ "$latest_request" != "null" ] && [ "$latest_response" != "null" ]; then
        if [ "$api_data" != "$api_hist" ]; then
            #printf "\n[$green---$NC]Request details URL: $green$latest_request$NC Status Code: $green$latest_response$NC"
            if [ "$latest_request" == "/done" ]; then
                sleep 3
                uploaded_file=$(ls -t $cwd| head -n1)
                printf "\n[$green+$NC] New File Uploaded: $green$uploaded_file$NC"
            elif [[ "$latest_request" == "/download/"* ]];then
                downloaded_file="${latest_request#"/download/"}"
                printf "\n[$green+$NC] New File Downloaded: $green$downloaded_file$NC"
            fi
        api_hist=$api_data
        fi
    fi
}

# Function to handle cleanup on Ctrl+C
cleanup() {
    echo -e "\nCtrl+C pressed. Cleaning up..."
    # Find the PID of the Gunicorn process
    gunicorn_pid=$(pgrep -o "gunicorn")
    if [ -n "$gunicorn_pid" ]; then
        printf "\nTerminating Gunicorn process with PID: $gunicorn_pid"
        kill $gunicorn_pid
    else
        printf "\nNo Gunicorn process found"
    fi
    exit 0
}

# Trap Ctrl+C and call the cleanup function
trap cleanup SIGINT

# Main function to start and monitor Gunicorn and Ngrok
main() {
    start_standardtoolcheck
    start_precheck
    start_gunicorn
    start_ngrok
    get_ngrok_public_url

    # Your Ngrok tunnel's public URL
    NGROK_URL="http://localhost:4040/api/requests/http?limit=1"

    # Main loop
    while true; do
        check_ngrok_api

        # Sleep for a specific interval (e.g., 3 seconds)
        sleep 0.1
    done
}

# Run the main function
main
