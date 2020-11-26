module Parser exposing (..)

import Url.Parser exposing ((</>), Parser, int, map, oneOf, s, string)


type Route
    = User Int
    | UserMedia Int String


routeParser : Parser (Route -> a) a
routeParser =
    oneOf
        [ map User (s "user" </> int)
        , map UserMedia (s "user" </> int </> s "media" </> string) -- /user/1/media/books
        ]
