module User exposing (..)

import Html exposing (Html)
import Html.Attributes as Attr exposing (class)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (..)
import Json.Encode.Extra exposing (maybe)
import RemoteData exposing (..)


type alias UnverifiedUser =
    { auth0Sub : String
    , firstName : String
    , lastName : String
    , fullName : String
    , email : String
    , picture : Maybe String
    }


type alias UserInfo =
    { goodTimesId : Int
    , auth0Sub : String
    , firstName : String
    , lastName : String
    , fullName : String
    , email : String
    , picture : Maybe String
    }


type alias LoggedInUser =
    { token : String
    , userInfo : UserInfo
    }


type FriendType
    = ExistingFriend
    | RequestedFriend


decodeFromAuth0 : Decoder UnverifiedUser
decodeFromAuth0 =
    Decode.map6 UnverifiedUser
        (Decode.field "sub" Decode.string)
        (Decode.field "given_name" Decode.string)
        (Decode.field "family_name" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "email" Decode.string)
        (Decode.maybe (Decode.field "picture" Decode.string))


userInfoDecoder : Decoder UserInfo
userInfoDecoder =
    Decode.map7 UserInfo
        (Decode.field "id" Decode.int)
        (Decode.field "auth0_sub" Decode.string)
        (Decode.field "first_name" Decode.string)
        (Decode.field "last_name" Decode.string)
        (Decode.field "full_name" Decode.string)
        (Decode.field "email" Decode.string)
        (Decode.maybe (Decode.field "picture" Decode.string))


unverifiedToUserInfo : UnverifiedUser -> Int -> UserInfo
unverifiedToUserInfo unverifiedUser goodTimesId =
    { goodTimesId = goodTimesId
    , auth0Sub = unverifiedUser.auth0Sub
    , firstName = unverifiedUser.firstName
    , lastName = unverifiedUser.lastName
    , fullName = unverifiedUser.fullName
    , email = unverifiedUser.email
    , picture = unverifiedUser.picture
    }


unverifiedUserEncoder : UnverifiedUser -> Encode.Value
unverifiedUserEncoder unverifiedUser =
    Encode.object
        [ ( "auth0_sub", Encode.string unverifiedUser.auth0Sub )
        , ( "first_name", Encode.string unverifiedUser.firstName )
        , ( "last_name", Encode.string unverifiedUser.lastName )
        , ( "full_name", Encode.string unverifiedUser.fullName )
        , ( "email", Encode.string unverifiedUser.email )
        , ( "picture", maybe Encode.string unverifiedUser.picture )
        ]


getUserFullName : WebData UserInfo -> String
getUserFullName user =
    case user of
        NotAsked ->
            "no user"

        Loading ->
            "friend"

        Failure error ->
            -- TODO show better error!
            "something went wrong"

        Success u ->
            u.fullName


getUserFirstName : WebData UserInfo -> String
getUserFirstName user =
    case user of
        NotAsked ->
            "need to search for a user"

        Loading ->
            "entering the database"

        Failure error ->
            -- TODO show better error!
            "something went wrong"

        Success u ->
            String.toLower u.firstName


getUserEmail : WebData UserInfo -> String
getUserEmail user =
    case user of
        NotAsked ->
            "need to search for a user"

        Loading ->
            "entering the database"

        Failure error ->
            -- TODO show better error!
            "something went wrong"

        Success u ->
            u.email


getUserId : WebData UserInfo -> Int
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
            u.goodTimesId



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
    { userInfo : UserInfo
    , status : Maybe FriendStatus
    }


userWithStatusDecoder : Decoder UserWithFriendStatus
userWithStatusDecoder =
    Decode.map2 UserWithFriendStatus
        (Decode.field "user" userInfoDecoder)
        (Decode.maybe (Decode.field "status" friendStatusDecoder))


type Profile
    = NoProfile
    | LoggedInUserProfile
    | FriendProfile
    | StrangerProfile UserWithFriendStatus



-- SHARED VIEW FUNCTIONS


viewUserPicture : UserInfo -> Html msg
viewUserPicture user =
    case user.picture of
        Just srcUrl ->
            Html.img
                [ Attr.src srcUrl ]
                []

        Nothing ->
            Html.div [ class "no-user-image" ] [ Html.p [] [ Html.text (String.left 1 user.firstName ++ String.left 1 user.lastName) ] ]
