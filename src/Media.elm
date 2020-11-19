module Media exposing (..)

import Json.Encode as Encode exposing (Value)


type Status
    = WantToConsume
    | Consuming
    | Finished
    | Abandoned


encodeStatus : Status -> Value
encodeStatus status =
    case status of
        WantToConsume ->
            Encode.string "want to consume"

        Consuming ->
            Encode.string "consuming"

        Finished ->
            Encode.string "finished"

        Abandoned ->
            Encode.string "abandoned"
