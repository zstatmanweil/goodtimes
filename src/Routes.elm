module Routes exposing (..)

import Url.Parser exposing ((</>), (<?>), Parser, fragment, int, map, oneOf, s)


type Route
    = Feed
    | User Int
    | Search
    | SearchUsers
    | Login
    | Authorized (Maybe String)


routeParser : Parser (Route -> a) a
routeParser =
    oneOf
        [ map Feed (s "feed")
        , map Login (s "login")
        , map Authorized (s "authorized" </> fragment identity)
        , map User (s "user" </> int)
        , map Search (s "search")
        , map SearchUsers (s "search" </> s "users")
        ]
