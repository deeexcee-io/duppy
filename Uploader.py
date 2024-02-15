import os
import argparse
from flask import Flask, request, redirect, url_for, session, Response, render_template, send_file
from werkzeug.utils import secure_filename

Uploader = Flask('Uploader')
Uploader.secret_key = 'XXX1234'

UPLOAD_FOLDER_DEFAULT = os.path.join(os.getcwd(), 'upload')
Uploader.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER_DEFAULT
Uploader.config['MAX_CONTENT_LENGTH'] = 20 * 1024 * 1024

ALLOWED_EXTENSIONS = set(['txt', 'pdf', 'png', 'jpg', 'jpeg', 'gif', 'zip', 'exe'])
def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@Uploader.route('/', methods=['GET', 'POST'])
def upload_file():
    if request.method == 'POST':
        # check if the post request has the file part
        if 'file' not in request.files:
            return redirect(request.url)
        file = request.files['file']
        # if user does not select file, browser also
        # submit an empty part without filename
        if file.filename == '':
            return redirect(request.url)
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            file.save(os.path.join(Uploader.config['UPLOAD_FOLDER'], filename))
            session['filename'] = filename
            return redirect(url_for('complete'))
            # FileName to use in /done route if cURL is used

    file_list = os.listdir(Uploader.config['UPLOAD_FOLDER'])
    return render_template('upload_form.html', file_list=file_list)

@Uploader.route('/done', methods=['GET', 'POST'])
def complete():
    filename = session.get('filename')
    user_agent = request.headers.get('User-Agent', '').lower()
    is_curl = 'curl' in user_agent
    if is_curl:
        return "File uploaded!"

    # Render the template with the filename
    return render_template('uploaded_file.html', filename=filename)

@Uploader.route('/download')
def file_list():
    #pwd = args.upload_folder
    cwd = UPLOAD_FOLDER_DEFAULT
    file_list = os.listdir(cwd)
    return render_template('file_list.html', file_list=file_list)

@Uploader.route('/download/<filename>')
def down_file(filename):
    #pwd = args.upload_folder
    cwd = UPLOAD_FOLDER_DEFAULT
    file_path = os.path.join(cwd, filename)
    return send_file(file_path, as_attachment=True, download_name=f'{filename}')

if __name__ == '__main__':
    # parser = argparse.ArgumentParser(description='Simple Flask File Uploader')
    # parser.add_argument('-P', '--port', type=int, default=5000, help='Port Number to listen On - Default 5000')
    # parser.add_argument('-H', '--host', default='0.0.0.0', help='Interface to listen on - Default all')
    # parser.add_argument('--upload-folder', default=UPLOAD_FOLDER_DEFAULT, help='Upload file path - Default \'cwd\'')
    # args = parser.parse_args()

    # Uploader.config['UPLOAD_FOLDER'] = args.upload_folder
    Uploader.run #(host=args.host, port=args.port)
