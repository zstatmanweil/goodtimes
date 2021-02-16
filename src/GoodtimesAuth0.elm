module GoodtimesAuth0 exposing (..)

import Auth0
import Url
import User exposing (LoggedInUser, UnverifiedUser)


type AuthStatus
    = NotAuthed
    | AuthError String
    | HasToken String
    | HasUnverifiedUser String UnverifiedUser
    | Authenticated LoggedInUser


isMidAuthentication : AuthStatus -> Bool
isMidAuthentication authStatus =
    case authStatus of
        NotAuthed ->
            False

        AuthError _ ->
            False

        HasToken _ ->
            True

        HasUnverifiedUser _ _ ->
            True

        Authenticated _ ->
            False


auth0Endpoint : String
auth0Endpoint =
    "https://goodtimes-staging.us.auth0.com"


auth0AuthorizeURL auth0Config responseType redirectURL scopes maybeConn =
    let
        connectionParam =
            maybeConn
                |> Maybe.map (\c -> "&connection=" ++ c)
                |> Maybe.withDefault ""

        scopeParam =
            scopes |> String.join " " |> Url.percentEncode
    in
    auth0Config.endpoint
        ++ "/authorize"
        ++ ("?response_type=" ++ responseType)
        ++ ("&client_id=" ++ auth0Config.clientId)
        ++ connectionParam
        ++ ("&redirect_uri=" ++ redirectURL)
        ++ ("&scope=" ++ scopeParam)
        ++ ("&audience=" ++ auth0Endpoint ++ "/api/v2/")


auth0LoginUrl : String
auth0LoginUrl =
    auth0AuthorizeURL
        (Auth0.Auth0Config auth0Endpoint "68MpVR1fV03q6to9Al7JbNAYLTi2lRGT")
        "token"
        "http://localhost:1234/authorized"
        [ "openid", "name", "email", "profile" ]
        (Just "google-oauth2")
