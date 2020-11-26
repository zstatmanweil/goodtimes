module User exposing (..)

import Json.Decode as Decode exposing (Decoder)


type alias User =
    { username : String
    , firstName : String
    , lastName : String
    }


decoder : Decoder User
decoder =
    Decode.map3 User
        (Decode.field "username" Decode.string)
        (Decode.field "first_name" Decode.string)
        (Decode.field "last_name" Decode.string)
