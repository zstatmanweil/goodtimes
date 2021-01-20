module Routes exposing (..)

import Url.Parser exposing ((</>), (<?>), Parser, fragment, int, map, oneOf, s)


type Route
    = Feed
    | User Int
    | Search
    | SearchUsers
    | Authorized (Maybe String)
    | About


routeParser : Parser (Route -> a) a
routeParser =
    oneOf
        [ map About (s "about")
        , map Feed (s "feed")
        , map Authorized (s "authorized" </> fragment identity)
        , map User (s "user" </> int)
        , map Search (s "search")
        , map SearchUsers (s "search" </> s "users")
        ]
