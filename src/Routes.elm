module Routes exposing (..)

import Url.Parser exposing ((</>), Parser, int, map, oneOf, s)


type Route
    = User Int
    | Search


routeParser : Parser (Route -> a) a
routeParser =
    oneOf
        [ map User (s "user" </> int)
        , map Search (s "search") -- /user/1/media/books
        ]
