# duppy

python flask app which utilises ngrok and gunicorn to securely download and upload files to local machine over the internet. all handled by the bash script. all dependencies will be installed.

logs files that are uploaded/downloaded to the terminal

You need a free ngrok account - https://dashboard.ngrok.com/login

duppy.sh will ask for your ngrok auth token, get it here - https://dashboard.ngrok.com/get-started/your-authtoken

## why?

was on a job beginning of feb where the kali box we could use was in AWS. had to port forward through a few jump boxes to get access. once on the box it had access to the internet and so wanted to securely transfer data/nessus scans back to my local machine easily. got a bit carried away with making it work and look pretty and and here we are 😂 - duppy

also thought it would be fun to work out the cheapest (free) and most secure way to have access to my files on the internet when needed.

Only tested on Kali and Kali on WSL

Simple Install

```bash
python3 -m venv duppy-venv

source duppy-venv/bin/activate

wget https://raw.githubusercontent.com/deeexcee-io/duppy/main/duppy.sh

sudo bash duppy.sh
```
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

app is protected with basic auth - update the creds in duppy.sh

```
start_ngrok() {
    #current_user=$SUDO_USER
    ngrok http 8000 --basic-auth="user:SuperPassword" > /dev/null 2>&1 &
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
```

