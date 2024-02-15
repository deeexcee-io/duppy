python flask app which utilises ngrok and gunicorn to securely download and upload files to local machine over the internet. all handled by the bash script. all dependencies will be installed.

logs files that are uploaded/downloaded to the terminal

Simple Install

```bash
python3 -m venv duppy-venv

source duppy-venv/bin/activate

wget https://raw.githubusercontent.com/deeexcee-io/duppy/main/duppy.sh

sudo bash duppy.sh
```
You need a free ngrok account - https://dashboard.ngrok.com/login

duppy.sh will ask for your ngrok auth token, get it here - https://dashboard.ngrok.com/get-started/your-authtoken

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

