module Book exposing (..)

import Consumption exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias Book =
    { title : String
    , source : String
    , sourceId : String
    , authorNames : List String
    , publishYear : Maybe Int
    , coverUrl : Maybe String
    , status : Maybe Consumption.Status
    }


statusAsString : Consumption.Status -> String
statusAsString status =
    case status of
        WantToConsume ->
            "want to read"

        Consuming ->
            "reading it now!"

        Finished ->
            "i'm great! i read it!"

        Abandoned ->
            "better luck next time"


maybeStatusAsString : Maybe Consumption.Status -> String
maybeStatusAsString maybeStatus =
    case maybeStatus of
        Just status ->
            statusAsString status

        Nothing ->
            "no status"


decoder : Decoder Book
decoder =
    Decode.map7 Book
        (Decode.field "title" Decode.string)
        (Decode.field "source" Decode.string)
        (Decode.field "source_id" Decode.string)
        (Decode.field "author_names" (Decode.list Decode.string))
        (Decode.field "publish_year" (Decode.nullable Decode.int))
        (Decode.field "cover_url" (Decode.nullable Decode.string))
        (Decode.maybe (Decode.field "status" Consumption.statusDecoder))



--TODO: how do I make the default NotAsked but it able to decode a status if it exists?


encoderWithStatus : Book -> Consumption.Status -> Encode.Value
encoderWithStatus book status =
    Encode.object
        [ ( "title", Encode.string book.title )
        , ( "source", Encode.string book.source )
        , ( "source_id", Encode.string book.sourceId )
        , ( "author_names", Encode.list Encode.string book.authorNames )
        , ( "publish_year", Encode.int (Maybe.withDefault 0 book.publishYear) )
        , ( "cover_url", Encode.string (Maybe.withDefault "" book.coverUrl) ) -- should we pass in None? or just empty string?
        , ( "status", Consumption.statusEncoder status )
        ]


type alias RecommendedBook =
    { title : String
    , source : String
    , sourceId : String
    , authorNames : List String
    , publishYear : Maybe Int
    , coverUrl : Maybe String
    , recommender_id : Int
    , recommender_username : String
    }


recommendedBookDecoder : Decoder RecommendedBook
recommendedBookDecoder =
    Decode.map8 RecommendedBook
        (Decode.field "title" Decode.string)
        (Decode.field "source" Decode.string)
        (Decode.field "source_id" Decode.string)
        (Decode.field "author_names" (Decode.list Decode.string))
        (Decode.field "publish_year" (Decode.nullable Decode.int))
        (Decode.field "cover_url" (Decode.nullable Decode.string))
        (Decode.field "recommender_id" Decode.int)
        (Decode.field "recommender_username" Decode.string)
