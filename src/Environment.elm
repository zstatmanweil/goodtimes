module Environment exposing (..)

import Json.Decode as Decode exposing (Decoder)


type Environment
    = Local
    | Production


toEnvironment : String -> Result String Environment
toEnvironment string =
    case string of
        "local" ->
            Ok Local

        "production" ->
            Ok Production

        badString ->
            Err (badString ++ " is not a valid environment")


auth0Endpoint : Environment -> String
auth0Endpoint env =
    case env of
        Local ->
            "https://goodtimes-staging.us.auth0.com"

        Production ->
            "https://goodtimes-production.us.auth0.com"


canonicalUrl : Environment -> String
canonicalUrl env =
    case env of
        Local ->
            "http://localhost:5000"

        Production ->
            "https://goodtimes.buzz"


apiUrl : Environment -> String
apiUrl env =
    case env of
        Local ->
            "http://127.0.0.1:5000/api"

        Production ->
            "https://goodtimes.buzz/api"
