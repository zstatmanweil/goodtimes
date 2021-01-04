module Event exposing (..)

import Consumption
import Json.Decode as Decode exposing (Decoder)
import Media exposing (MediaType)


type alias Event =
    { media : MediaType
    , mediaType : String
    , userId : Int
    , username : String
    , status : Consumption.Status
    , created : String
    , timeSince : Int
    }


decoder : Decoder Event
decoder =
    Decode.map7 Event
        (Decode.field "media" Media.unknownMediaDecoder)
        (Decode.field "media_type" Decode.string)
        (Decode.field "user_id" Decode.int)
        (Decode.field "username" Decode.string)
        (Decode.field "status" Consumption.statusDecoder)
        (Decode.field "created" Decode.string)
        (Decode.field "time_since" Decode.int)
