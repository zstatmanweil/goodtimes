module User exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
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



-- FRIEND


type alias FriendLink =
    { requester_id : Int
    , requested_id : Int
    , status : FriendStatus
    }


type FriendStatus
    = Requested
    | Accepted
    | Rejected
    | Unfriend


friendStatusDecoder : Decoder FriendStatus
friendStatusDecoder =
    Decode.string
        |> Decode.andThen stringToFriendStatusDecoder


stringToFriendStatusDecoder : String -> Decoder FriendStatus
stringToFriendStatusDecoder string =
    case string of
        "requested" ->
            Decode.succeed Requested

        "accepted" ->
            Decode.succeed Accepted

        "rejected" ->
            Decode.succeed Rejected

        "unfriend" ->
            Decode.succeed Unfriend

        invalidString ->
            Decode.fail (invalidString ++ " is not a valid Status")


friendStatusEncoder : FriendStatus -> Value
friendStatusEncoder friendStatus =
    case friendStatus of
        Requested ->
            Encode.string "requested"

        Accepted ->
            Encode.string "accepted"

        Rejected ->
            Encode.string "rejected"

        Unfriend ->
            Encode.string "unfriend"


friendLinkEncoder : Int -> Int -> FriendStatus -> Encode.Value
friendLinkEncoder requesterId requestedId status =
    Encode.object
        [ ( "requester_id", Encode.int requesterId )
        , ( "requested_id", Encode.int requestedId )
        , ( "status", friendStatusEncoder status )
        ]


friendLinkDecoder : Decoder FriendLink
friendLinkDecoder =
    Decode.map3 FriendLink
        (Decode.field "requester_id" Decode.int)
        (Decode.field "requested_id" Decode.int)
        (Decode.field "status" friendStatusDecoder)


friendStatusAsString : FriendStatus -> String
friendStatusAsString status =
    case status of
        Requested ->
            "friendship requested"

        Accepted ->
            "already friends!"

        Rejected ->
            "friendship rejected"

        Unfriend ->
            "friendship has ended"



-- USER WITH STATUS


type alias UserWithFriendStatus =
    { id : Int
    , username : String
    , firstName : String
    , lastName : String
    , email : String
    , status : Maybe FriendStatus
    }


userWithStatusDecoder : Decoder UserWithFriendStatus
userWithStatusDecoder =
    Decode.map6 UserWithFriendStatus
        (Decode.field "id" Decode.int)
        (Decode.field "username" Decode.string)
        (Decode.field "first_name" Decode.string)
        (Decode.field "last_name" Decode.string)
        (Decode.field "email" Decode.string)
        (Decode.maybe (Decode.field "status" friendStatusDecoder))
