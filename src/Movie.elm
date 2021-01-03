module Movie exposing (Movie, decoder, encoderWithStatus, maybeStatusAsString, statusAsString)

import Consumption exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias Movie =
    { source : String
    , sourceId : String
    , title : String
    , posterUrl : Maybe String
    , releaseDate : String
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
            "stopped it midway"


maybeStatusAsString : Maybe Consumption.Status -> String
maybeStatusAsString maybeStatus =
    case maybeStatus of
        Just status ->
            statusAsString status

        Nothing ->
            "no status"


decoder : Decoder Movie
decoder =
    Decode.map6 Movie
        (Decode.field "source" Decode.string)
        (Decode.field "source_id" Decode.string)
        (Decode.field "title" Decode.string)
        (Decode.field "poster_url" (Decode.nullable Decode.string))
        (Decode.field "release_date" Decode.string)
        (Decode.maybe (Decode.field "status" Consumption.statusDecoder))


encoderWithStatus : Movie -> Consumption.Status -> Encode.Value
encoderWithStatus movie status =
    Encode.object
        [ ( "source", Encode.string movie.source )
        , ( "source_id", Encode.string movie.sourceId )
        , ( "title", Encode.string movie.title )
        , ( "poster_url", Encode.string (Maybe.withDefault "" movie.posterUrl) )
        , ( "release_date", Encode.string movie.releaseDate )
        , ( "status", Consumption.statusEncoder status )
        ]
