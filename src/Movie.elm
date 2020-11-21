module Movie exposing (Movie, decoder, encoderWithStatus, statusAsString)

import Consumption exposing (Status(..))
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import RemoteData exposing (RemoteData(..), WebData)


type alias Movie =
    { source : String
    , sourceId : String
    , title : String
    , posterUrl : Maybe String
    , firstAirDate : String
    , status : WebData Status
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
            "Stopped it midway"


decoder : Decoder Movie
decoder =
    Decode.map6 Movie
        (Decode.field "source" Decode.string)
        (Decode.field "source_id" Decode.string)
        (Decode.field "title" Decode.string)
        (Decode.field "poster_url" (Decode.nullable Decode.string))
        (Decode.field "first_air_date" Decode.string)
        (Decode.succeed NotAsked)


encoderWithStatus : Movie -> Consumption.Status -> Encode.Value
encoderWithStatus movie status =
    Encode.object
        [ ( "source", Encode.string movie.source )
        , ( "source_id", Encode.string movie.sourceId )
        , ( "title", Encode.string movie.title )
        , ( "poster_url", Encode.string (Maybe.withDefault "" movie.posterUrl) )
        , ( "first_air_date", Encode.string movie.firstAirDate )
        , ( "status", Consumption.statusEncoder status )
        ]
