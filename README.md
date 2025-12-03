# duppy

`duppy.sh` provisions a small Flask application (served by Gunicorn) that lets you upload and download files from your workstation. It can either expose the service through an ngrok tunnel or keep it limited to the local network with self-signed TLS.

## Requirements

- Python 3 with `venv`
- `wget` (or curl) to grab the bootstrap script
- Free ngrok account and auth token: https://dashboard.ngrok.com/get-started/your-authtoken

Tested on Kali Linux (bare metal and WSL).

## Quick start

```bash
python3 -m venv duppy-venv
source duppy-venv/bin/activate
wget https://raw.githubusercontent.com/deeexcee-io/duppy/main/duppy.sh
chmod +x duppy.sh
./duppy.sh
```

Keep the virtual environment active while running `duppy.sh`; dependencies are installed inside it. The script creates the environment if one is not already active.

## Operating modes

- **Internet:** uses ngrok to publish a tunnel and prints the public HTTPS URL.
- **Local:** binds to `0.0.0.0:8000` with a self-signed certificate stored in `.tls/`.

Set `DUPPY_MODE=internet` or `DUPPY_MODE=local` before launching the script to skip the mode prompt.

## Authentication

The web UI and upload endpoint use HTTP basic auth. Override the default credentials by exporting `DUPPY_BASIC_AUTH="username:password"` prior to running `./duppy.sh`.
