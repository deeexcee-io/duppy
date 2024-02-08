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
![image](https://github.com/deeexcee-io/Uploader/assets/130473605/b1a1f5dd-8735-4097-8621-77304d8ab53a)

## Command Line
```bash
curl -L -s -X POST -F "file=@/etc/passwd" http://192.168.0.29:8000
File uploaded!
```
