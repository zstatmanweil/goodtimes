from flask import Flask
from flask_cors import CORS

from routes.books import books
from routes.movies import movies
from routes.tv import tv
from routes.user import user

app = Flask(__name__)
app.secret_key = 'very secret key'  # Fix this later!

CORS(app, resources={r"*": {"origins": "*"}})


app.register_blueprint(books)
app.register_blueprint(movies)
app.register_blueprint(tv)
app.register_blueprint(user)

#  main thread of execution to start the server
if __name__ == '__main__':
    app.run(debug=True)
