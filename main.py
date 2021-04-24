import json
import os

from config import DEV_AUTH_CONFIG, PROD_AUTH_CONFIG
from werkzeug.exceptions import HTTPException
from flask import Flask, jsonify, send_from_directory
from flask_cors import CORS
import json
from six.moves.urllib.request import urlopen
from functools import wraps

from flask import Flask, request, jsonify, _request_ctx_stack
from flask_cors import cross_origin
from jose import jwt

from routes.books import books
from routes.movies import movies
from routes.tv import tv
from routes.user import user
from routes.friend import friend
from server import auth

app = Flask(__name__, static_url_path='/static', static_folder='public')
app.secret_key = 'very secret key'  # Fix this later!

CORS(app, resources={r"*": {"origins": "*"}})


app.register_blueprint(auth, url_prefix='/api')
app.register_blueprint(books, url_prefix='/api')
app.register_blueprint(movies, url_prefix='/api')
app.register_blueprint(tv, url_prefix='/api')
app.register_blueprint(user, url_prefix='/api')
app.register_blueprint(friend, url_prefix='/api')

@app.route('/auth_config.json')
def send_json():

    print(os.getenv("FLASK_ENV"))
    if os.getenv("FLASK_ENV") == 'production':
        auth_config = PROD_AUTH_CONFIG
    else:
        auth_config = DEV_AUTH_CONFIG

    response = app.response_class(
        response=json.dumps(auth_config),
        status=200,
        mimetype='application/json'
    )
    return response

@app.route('/', defaults={'u_path': ''})
@app.route('/<path:u_path>')
def send_foo(u_path):
    return app.send_static_file('index.html')

@app.errorhandler(HTTPException)
def handle_exception(e):
    """Return JSON instead of HTML for HTTP errors."""
    # start with the correct headers and status code from the error
    response = e.get_response()
    # replace the body with JSON
    response.data = json.dumps({
        "code": e.code,
        "name": e.name,
        "description": e.description,
    })
    response.content_type = "application/json"
    return response

#  main thread of execution to start the server
if __name__ == '__main__':
    app.run(host="0.0.0.0", port=os.getenv("PORT"))
