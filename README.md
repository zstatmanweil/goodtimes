# goodtimes
Web-app to track, share and recommend books and media our friends are enjoying

# Quickstart

```sh
# Install Pythong dependencies into virtual environment
pip install -r requirements

# Install js dependencies
npm run install

# Run the frontend builder 
npm run start

# Run app locally (Ensuring in development environment)
echo 'FLASK_ENV=development' > .flaskenv
python main.py
```

While this will run the application, most endpoints will require use of the backend database. 

## Database

Create a local Postgres database called `goodtimes`. Follow README in `alembic/` folder to build
database tables. For testing, you will need at least one user:

```shell script
python scripts/create_user.py
```

Update a file `/config/config` to contain a variable postgres_db with your postgres username and password as follows:

```
postgres_db="postgresql://username:password@localhost/goodtimes"
```

## What it's using to work

Using [scss](https://sass-lang.com/), which is just like css but gives you some nice things like variables mixins and things. I installed a tool called [Parcel](https://parceljs.org/) that basically does the work of compiling them elm and the scss into html, css, and javascript.

The main entry point is the html file at `src/index.html`.
Parcel follows the dependencies and builds what it needs to. Since `src/index.js` imports an elm file, it compiles the elm. Since `src/index.html` links to a `scss` file, it converts it to css!

# TODO
  - [ ] Update index.js to not hardcode 'local'
  - [ ] Serve the frontend
  - [x] Create managed database that we can run in production
  - [x] Host the backend
  - [ ] Setup so that deploying changes is fairly easy (github actions?)
  - [ ] Run with wsgi? Gunicorn? Productioner server, wasup?
  - [ ] Automatically redirect from http to https



# Interacting with the cloud:

### Updating code

Pushing to the heroku remote automatically redploys:

`git push heroku main`


### Database migrations

`heroku run alembic upgrade head --app good-times-buzz`


### View logs

`heroku logs --tail`
