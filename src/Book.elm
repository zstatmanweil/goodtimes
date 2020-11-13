module Book exposing (Book, decoder)


import Json.Decode as Decode exposing (Decoder)


type alias Book =
    { title : String
    , authorName : Maybe String
    , publishYear : Maybe Int
    , coverUrl : Maybe String
    }


decoder : Decoder Book
decoder =
    Decode.map4 Book
        (Decode.field "title" Decode.string)
        (Decode.field "author_name" (Decode.nullable Decode.string))
        (Decode.field "publish_year" (Decode.nullable Decode.int))
        (Decode.field "cover_url" (Decode.nullable Decode.string))
