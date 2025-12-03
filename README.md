# duppy

`duppy.sh` is a single script that prepares a Flask + Gunicorn file drop box and exposes it either to the internet through ngrok or to the local network with self-signed TLS. It installs everything it needs (system tools, a virtual environment, Flask, Gunicorn, ngrok, TLS assets) and tears them down cleanly when you exit.

## Requirements

- Python 3 with `venv` (the script creates or reuses `duppy-venv`, or you may activate one manually)
- Ability to download the script (e.g., `curl` or `wget`)
- Optional: free ngrok account + auth token if you want the internet-facing mode

## Run it

Clone the repository locally so the launcher script and templates stay together:

```bash
git clone https://github.com/deeexcee-io/duppy.git
cd duppy
```

Then execute the launcher from the cloned directory:

```bash
chmod +x duppy.sh
./duppy.sh
```

The launcher prompts for mode selection unless you export `DUPPY_MODE=internet` or `DUPPY_MODE=local`. It also asks before installing `ngrok` or `gunicorn` if they are missing.

## Modes

- **Internet:** runs Gunicorn on `127.0.0.1:8000`, starts an ngrok tunnel (optionally bound to `DUPPY_NGROK_DOMAIN`), and prints the public HTTPS URL along with upload/download activity pulled from the ngrok API.
- **Local:** binds to `0.0.0.0:8000`, autogenerates `.tls/duppy.(crt|key)`, and prints the LAN URL to share. Basic auth enforcement is mandatory in this mode.

## Authentication & environment

HTTP basic auth protects both modes. Override the default `user:SuperPassword` combination with `DUPPY_BASIC_AUTH="username:password"`. `DUPPY_REQUIRE_BASIC_AUTH` is set automatically, so no extra config is needed in the Flask app.
