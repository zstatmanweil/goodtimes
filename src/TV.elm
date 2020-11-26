module TV exposing (TV, decoder, encoderWithStatus, maybeStatusAsString, statusAsString)

import Consumption exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias TV =
    { source : String
    , sourceId : String
    , title : String
    , networks : List String
    , posterUrl : Maybe String
    , firstAirDate : Maybe String
    , status : Maybe Consumption.Status
    }


statusAsString : Consumption.Status -> String
statusAsString status =
    case status of
        WantToConsume ->
            "want to watch"

        Consuming ->
            "watching it now! why am I on good times while watching a movie?!"

        Finished ->
            "totally watched it!"

        Abandoned ->
            "couldn't finish"


maybeStatusAsString : Maybe Consumption.Status -> String
maybeStatusAsString maybeStatus =
    case maybeStatus of
        Just status ->
            statusAsString status

        Nothing ->
            "no status"


decoder : Decoder TV
decoder =
    Decode.map7 TV
        (Decode.field "source" Decode.string)
        (Decode.field "source_id" Decode.string)
        (Decode.field "title" Decode.string)
        (Decode.field "networks" (Decode.list Decode.string))
        (Decode.field "poster_url" (Decode.nullable Decode.string))
        (Decode.field "first_air_date" (Decode.nullable Decode.string))
        (Decode.maybe (Decode.field "status" Consumption.statusDecoder))


encoderWithStatus : TV -> Consumption.Status -> Encode.Value
encoderWithStatus tv status =
    Encode.object
        [ ( "source", Encode.string tv.source )
        , ( "source_id", Encode.string tv.sourceId )
        , ( "title", Encode.string tv.title )
        , ( "networks", Encode.list Encode.string tv.networks )
        , ( "poster_url", Encode.string (Maybe.withDefault "" tv.posterUrl) )
        , ( "first_air_date", Encode.string (Maybe.withDefault "unknown" tv.firstAirDate) )
        , ( "status", Consumption.statusEncoder status )
        ]
