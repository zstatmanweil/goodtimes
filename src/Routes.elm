module Routes exposing (..)

import Url.Parser exposing ((</>), Parser, int, map, oneOf, s)


type Route
    = User Int
    | Search
    | SearchUsers


routeParser : Parser (Route -> a) a
routeParser =
    oneOf
        [ map User (s "user" </> int)
        , map Search (s "search")
        , map SearchUsers (s "search" </> s "users")
        ]
