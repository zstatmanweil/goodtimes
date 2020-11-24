module TV exposing (TV, decoder, encoderWithStatus, statusAsString)

import Consumption exposing (Status(..))
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import RemoteData exposing (RemoteData(..), WebData)


type alias TV =
    { source : String
    , sourceId : String
    , title : String
    , networks : List String
    , posterUrl : Maybe String
    , firstAirDate : Maybe String
    , status : WebData Status
    }


statusAsString : Consumption.Status -> String
statusAsString status =
    case status of
        WantToConsume ->
            "want to watch"

        Consuming ->
            "watching it now!"

        Finished ->
            "totally watched it!"

        Abandoned ->
            "better luck next time"


decoder : Decoder TV
decoder =
    Decode.map7 TV
        (Decode.field "source" Decode.string)
        (Decode.field "source_id" Decode.string)
        (Decode.field "title" Decode.string)
        (Decode.field "networks" (Decode.list Decode.string))
        (Decode.field "poster_url" (Decode.nullable Decode.string))
        (Decode.field "first_air_date" (Decode.nullable Decode.string))
        (Decode.succeed NotAsked)


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
