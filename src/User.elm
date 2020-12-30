module User exposing (..)

import Json.Decode as Decode exposing (Decoder)
import RemoteData exposing (..)


type alias User =
    { id : Int
    , username : String
    , firstName : String
    , lastName : String
    , email : String
    }


decoder : Decoder User
decoder =
    Decode.map5 User
        (Decode.field "id" Decode.int)
        (Decode.field "username" Decode.string)
        (Decode.field "first_name" Decode.string)
        (Decode.field "last_name" Decode.string)
        (Decode.field "email" Decode.string)


getUsername : WebData User -> String
getUsername user =
    case user of
        NotAsked ->
            "no user"

        Loading ->
            "friend"

        Failure error ->
            -- TODO show better error!
            "something went wrong"

        Success u ->
            u.username


getUserId : WebData User -> Int
getUserId user =
    case user of
        NotAsked ->
            0

        Loading ->
            0

        Failure error ->
            -- TODO show better error!
            0

        Success u ->
            u.id
