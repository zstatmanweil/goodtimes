module Media exposing (..)

import Book exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Media


type Media
    = Book
    | TV
    | Movie


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


type alias Consumption =
    { userId : Int
    , sourceId : String
    , mediaType : String
    , mediaId : Int
    , status : Media.Status
    , created : String
    }


consumptionDecoder : Decoder Consumption
consumptionDecoder =
    Decode.map6 Consumption
        (Decode.field "user_id" Decode.int)
        (Decode.field "source_id" Decode.string)
        (Decode.field "media_type" Decode.string)
        (Decode.field "media_id" Decode.int)
        (Decode.field "status" Media.statusDecoder)
        (Decode.field "created" Decode.string)
