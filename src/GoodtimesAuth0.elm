module GoodtimesAuth0 exposing (..)

import Auth0
import Http
import Json.Encode as Encode
import User


auth0Endpoint : String
auth0Endpoint =
    "https://goodtimes-staging.us.auth0.com"


auth0LoginUrl : String
auth0LoginUrl =
    Auth0.auth0AuthorizeURL
        (Auth0.Auth0Config auth0Endpoint "68MpVR1fV03q6to9Al7JbNAYLTi2lRGT")
        "token"
        "http://localhost:1234/authorized"
        [ "openid", "name", "email", "profile" ]
        (Just "google-oauth2")
