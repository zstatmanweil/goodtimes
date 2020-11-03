from flask import Flask
from routes.books import books
from routes.movies import movies

app = Flask(__name__)
app.secret_key = 'very secret key'  # Fix this later!


app.register_blueprint(books)
app.register_blueprint(movies)

#  main thread of execution to start the server
if __name__ == '__main__':
    app.run(debug=True)
