# duppy

python flask app which utilises ngrok and gunicorn to securely download and upload files to local machine over the internet. all handled by the bash script. all dependencies will be installed.

logs files that are uploaded/downloaded to the terminal

You need a free ngrok account - https://dashboard.ngrok.com/login

duppy.sh will ask for your ngrok auth token, get it here - https://dashboard.ngrok.com/get-started/your-authtoken

## why?

was on a job beginning of feb where the kali box we could use was in AWS. had to port forward through a few jump boxes to get access. once on the box it had access to the internet and so wanted to securely transfer data/nessus scans back to my local machine easily. got a bit carried away with making it work and look pretty and and here we are 😂 - duppy

also thought it would be fun to work out the cheapest (free) and most secure way to have access to my files/code/exploits on the internet when needed for my pen testing work.

Only tested on Kali and Kali on WSL

Simple Install

```bash
python3 -m venv duppy-venv

source duppy-venv/bin/activate

wget https://raw.githubusercontent.com/deeexcee-io/duppy/main/duppy.sh

chmod +x duppy.sh

./duppy.sh
```

Keep the virtual environment active while running `duppy.sh` so Flask, Gunicorn, and other Python modules are installed inside it. The script detects an already-activated environment and otherwise creates `./duppy-venv` before installing dependencies, and it uses `sudo` internally when system packages are required—no need to prefix the script with `sudo`.

### Choosing how to expose the app

When `duppy.sh` starts it now asks whether you want full internet exposure (via ngrok) or a local-network-only mode. Pick the internet option when you need the tunnel, or select the local option to bind Gunicorn to `0.0.0.0:8000` for peer-to-peer transfers on the same engagement network without ngrok. You can also skip the prompt by setting `DUPPY_MODE=internet` or `DUPPY_MODE=local` before launching the script.

Local mode automatically generates (or reuses) a self-signed TLS certificate in `.tls/` and serves the app over HTTPS (`https://<host>:8000`). Distribute the certificate to teammates and trust it in their browsers to avoid warnings.
## w/cURL

```
curl -u "user:SuperPassword" -L -s -X POST -F "file=@file1.pdf" https://cb58-11-1-11-11.ngrok-free.app

|------------------------------------|

┌──(gd㉿DESKTOP-RCB6DUO)-[~]
└─$ curl -u "user:SuperPassword" -L -s -X POST -F "file=@file1.pdf" https://cb58-11-1-11-11.ngrok-free.app
File uploaded!
```

on server
```
[sudo] password for gd:
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


[+] Updating Package Index
[+] Package Index Updated
[+] ngrok and gunicorn installed......lets go
[+] Pulling duppy repo
[+] duppy already installed
[+] gunicorn started
[+] ngrok started successfully
[+] Public URL: https://cb58-11-1-11-11.ngrok-free.app
[+] New File Uploaded: file1.pdf
```

![image](https://github.com/deeexcee-io/duppy/assets/130473605/f72e6177-98ce-4487-9a2d-5a0340765644)


Local files accessible with upload/download functionality

![image](https://github.com/deeexcee-io/duppy/assets/130473605/7350310a-6e14-42a1-a4af-171e32bbb978)

The app is protected with HTTP basic auth. Customize the credentials by setting the `DUPPY_BASIC_AUTH` environment variable before launching `duppy.sh`, for example:

```bash
export DUPPY_BASIC_AUTH="alice:Use-A-Strong-Password"
./duppy.sh
```

If the variable is not set, the script defaults to `user:SuperPassword`.
