module Book exposing (Book, decoder, encoderWithStatus)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias Book =
    { title : String
    , source : String
    , sourceId : String
    , authorName : Maybe String
    , publishYear : Maybe Int
    , coverUrl : Maybe String
    }


decoder : Decoder Book
decoder =
    Decode.map6 Book
        (Decode.field "title" Decode.string)
        (Decode.field "source" Decode.string)
        (Decode.field "source_id" Decode.string)
        (Decode.field "author_name" (Decode.nullable Decode.string))
        (Decode.field "publish_year" (Decode.nullable Decode.int))
        (Decode.field "cover_url" (Decode.nullable Decode.string))


encoderWithStatus : Book -> String -> Encode.Value
encoderWithStatus book status =
    Encode.object
        [ ( "title", Encode.string book.title )
        , ( "source", Encode.string book.source )
        , ( "source_id", Encode.string book.sourceId )
        , ( "author_name", Encode.string (Maybe.withDefault "" book.authorName) )
        , ( "publish_year", Encode.int (Maybe.withDefault 0 book.publishYear) )
        , ( "cover_url", Encode.string (Maybe.withDefault "" book.coverUrl) ) -- should we pass in None? or just empty string?
        , ( "status", Encode.string status )
        ]
