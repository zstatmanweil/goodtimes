import json

from werkzeug.exceptions import HTTPException
from flask import Flask, jsonify
from flask_cors import CORS

from routes.books import books
from routes.movies import movies
from routes.tv import tv
from routes.user import user
from routes.friend import friend

app = Flask(__name__)
app.secret_key = 'very secret key'  # Fix this later!

CORS(app, resources={r"*": {"origins": "*"}})


app.register_blueprint(books)
app.register_blueprint(movies)
app.register_blueprint(tv)
app.register_blueprint(user)
app.register_blueprint(friend)


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
    app.run(debug=True)
