module Media exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)


type Status
    = WantToConsume
    | Consuming
    | Finished
    | Abandoned


statusDecoder : Decoder Status
statusDecoder =
    Decode.string
        |> Decode.andThen stringToStatusDecoder


stringToStatusDecoder : String -> Decoder Status
stringToStatusDecoder string =
    case string of
        "want to consume" ->
            Decode.succeed WantToConsume

        "consuming" ->
            Decode.succeed Consuming

        "finished" ->
            Decode.succeed Finished

        "abandoned" ->
            Decode.succeed Abandoned

        invalidString ->
            Decode.fail (invalidString ++ " is not a valid Status")


statusEncoder : Status -> Value
statusEncoder status =
    case status of
        WantToConsume ->
            Encode.string "want to consume"

        Consuming ->
            Encode.string "consuming"

        Finished ->
            Encode.string "finished"

        Abandoned ->
            Encode.string "abandoned"
