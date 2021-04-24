module GoodtimesAuth0 exposing (..)

import Auth0
import Environment exposing (Environment)
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


auth0AuthorizeURL auth0Config responseType redirectURL scopes maybeConn env =
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
        ++ ("&audience=" ++ Environment.auth0Endpoint env ++ "/api/v2/")


loginUrl : Environment -> String
loginUrl env =
    auth0AuthorizeURL
        (Auth0.Auth0Config (Environment.auth0Endpoint env) "68MpVR1fV03q6to9Al7JbNAYLTi2lRGT")
        "token"
        (Environment.canonicalUrl env ++ "/authorized")
        [ "openid", "name", "email", "profile", "offline_access" ]
        (Just "google-oauth2")
        env
