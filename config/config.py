import os

# Do this weird hack because heroku doesnt play nice with the url scheme that
# sqlalchemy expects
# https://stackoverflow.com/questions/62688256/sqlalchemy-exc-nosuchmoduleerror-cant-load-plugin-sqlalchemy-dialectspostgre#comment118515587_66794960
database_url = os.getenv("DATABASE_URL")
if database_url.startswith("postgres://"):
    database_url = database_url.replace("postgres://", "postgresql://", 1)

DATABASE_URL=database_url

GOOGLE_BOOKS_API_KEY=os.getenv("GOOGLE_BOOKS_API_KEY")
TMDB_TOKEN=os.getenv("TMDB_TOKEN")


PROD_AUTH0_DOMAIN = "goodtimes-production.us.auth0.com"
PROD_AUTH_CONFIG = {
    "domain": PROD_AUTH0_DOMAIN,
    "clientId": "plxal68Z4k1rlKCcNxjfq3IHY1Mr8sAx"
}

DEV_AUTH0_DOMAIN = "goodtimes-staging.us.auth0.com"
DEV_AUTH_CONFIG = {
    "domain": DEV_AUTH0_DOMAIN,
    "clientId": "68MpVR1fV03q6to9Al7JbNAYLTi2lRGT"
}

