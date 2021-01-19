module Overlap exposing (..)

import Consumption
import Json.Decode as Decode exposing (Decoder)
import Media exposing (MediaType)


type alias OverlapMedia =
    { media : MediaType
    , otherUserId : Int
    , otherUserStatus : Consumption.Status
    }


overlapMediaDecoder : Decoder OverlapMedia
overlapMediaDecoder =
    Decode.map3 OverlapMedia
        (Decode.field "media" Media.unknownMediaDecoder)
        (Decode.field "other_user_id" Decode.int)
        (Decode.field "other_user_status" Consumption.statusDecoder)
