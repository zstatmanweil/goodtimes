# goodtimes
Web-app to track, share and recommend books and media our friends are enjoying

# The Backend:

## Quickstart

```sh
# Install dependencies into virtual environment
pip install -r requirements

# Run app
python main.py
```

While this will run the application, most endpoints will require use of the backend database. 

## Database

Create a local Postgres database called `goodtimes`. Follow README in `alembic/` folder to build
database tables. For testing, you will need at least one user:

```shell script
python scripts/create_user.py
```

# The Frontend:

## Quick Start

``` sh
# First - install the dependencies
npm run install

# Then - start the code
npm run serve

```

## What it's using to work

Using [scss](https://sass-lang.com/), which is just like css but gives you some nice things like variables mixins and things. I installed a tool called [Parcel](https://parceljs.org/) that basically does the work of compiling them elm and the scss into html, css, and javascript.

The main entry point is the html file at `src/index.html`.
Parcel follows the dependencies and builds what it needs to. Since `src/index.js` imports an elm file, it compiles the elm. Since `src/index.html` links to a `scss` file, it converts it to css!

