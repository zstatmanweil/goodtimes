module Recommendation exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Media exposing (MediaType)



-- Recommendation


type alias Recommendation =
    { recommenderUserId : Int
    , recommendedUserId : Int
    , mediaType : String
    , mediaId : Int
    , sourceId : String
    , status : Status
    , created : Float --TODO: deal with datetime
    }


type Status
    = Pending
    | Responded
    | Ignored


statusEncoder : Status -> Value
statusEncoder status =
    case status of
        Pending ->
            Encode.string "pending"

        Responded ->
            Encode.string "responded"

        Ignored ->
            Encode.string "ignored"


stringToStatusDecoder : String -> Decoder Status
stringToStatusDecoder string =
    case string of
        "pending" ->
            Decode.succeed Pending

        "responded" ->
            Decode.succeed Responded

        "ignored" ->
            Decode.succeed Ignored

        invalidString ->
            Decode.fail (invalidString ++ " is not a valid Status")


statusDecoder : Decoder Status
statusDecoder =
    Decode.string
        |> Decode.andThen stringToStatusDecoder


decoder : Decoder Recommendation
decoder =
    Decode.map7 Recommendation
        (Decode.field "recommender_user_id" Decode.int)
        (Decode.field "recommended_user_id" Decode.int)
        (Decode.field "media_type" Decode.string)
        (Decode.field "media_id" Decode.int)
        (Decode.field "source_id" Decode.string)
        (Decode.field "status" statusDecoder)
        (Decode.field "created" Decode.float)


encoder : MediaType -> Int -> Int -> Status -> Encode.Value
encoder mediaType recommenderUserID recommendedUserID status =
    Encode.object
        [ ( "recommender_user_id", Encode.int recommenderUserID )
        , ( "recommended_user_id", Encode.int recommendedUserID )
        , ( "source_id", Encode.string (Media.getSourceId mediaType) )
        , ( "status", statusEncoder status )
        ]



-- Recommended Media


type RecommendationType
    = RecToUserType RecommendedToUserMedia
    | RecByUserType RecommendedByUserMedia


type alias RecommendedToUserMedia =
    { media : MediaType
    , recommenderId : Int
    , recommenderFullName : String
    , created : String -- TODO: how do we deal with datatime??
    }


type alias RecommendedByUserMedia =
    { media : MediaType
    , recommendedId : Int
    , recommendedFullName : String
    , created : String -- TODO: how do we deal with datatime??
    }


getRecommendedMedia : RecommendationType -> MediaType
getRecommendedMedia recommendationType =
    case recommendationType of
        RecToUserType { media } ->
            media

        RecByUserType { media } ->
            media


recommendedToUserMediaDecoder : Decoder RecommendedToUserMedia
recommendedToUserMediaDecoder =
    Decode.map4 RecommendedToUserMedia
        (Decode.field "media" Media.unknownMediaDecoder)
        (Decode.field "recommender_id" Decode.int)
        (Decode.field "recommender_full_name" Decode.string)
        (Decode.field "created" Decode.string)


recToUserToRecTypeDecoder : Decoder RecommendedToUserMedia -> Decoder RecommendationType
recToUserToRecTypeDecoder recToUser =
    Decode.map RecToUserType recToUser


recommendedByUserMediaDecoder : Decoder RecommendedByUserMedia
recommendedByUserMediaDecoder =
    Decode.map4 RecommendedByUserMedia
        (Decode.field "media" Media.unknownMediaDecoder)
        (Decode.field "recommended_id" Decode.int)
        (Decode.field "recommended_full_name" Decode.string)
        (Decode.field "created" Decode.string)


recByUserToRecTypeDecoder : Decoder RecommendedByUserMedia -> Decoder RecommendationType
recByUserToRecTypeDecoder recByUser =
    Decode.map RecByUserType recByUser
