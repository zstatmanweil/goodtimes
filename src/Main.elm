module Main exposing (..)

import Auth0
import Browser exposing (..)
import Browser.Navigation as Nav
import Dict
import Html exposing (Html)
import Html.Attributes as Attr
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Maybe.Extra
import Page.Feed as Feed
import Page.Search as Search
import Page.SearchUsers as SearchUsers
import Page.UserProfile as UserProfile
import Routes exposing (..)
import Skeleton
import Url
import Url.Parser as Parser
import User exposing (UnverifiedUser, UserInfo)


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }



-- MODEL


type alias Flags =
    Bool


type alias Model =
    { url : Url.Url
    , key : Nav.Key
    , page : Page
    , isOpenMenu : Bool
    , auth : AuthStatus
    }


type AuthStatus
    = NotAuthed
    | AuthError String
    | HasToken String
    | HasUnverifiedUser String UnverifiedUser
    | Authenticated String UserInfo


type Page
    = NotFound
    | Login
    | LoggedIn UserInfo LoggedInPage


type LoggedInPage
    = Feed Feed.Model
    | Search Search.Model
    | SearchUsers SearchUsers.Model
    | UserProfile UserProfile.Model



-- INIT


init : Flags -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init isAuthenticated url key =
    stepUrl url
        { url = url
        , key = key
        , page = Login
        , isOpenMenu = False
        , auth = NotAuthed
        }



-- VIEW


auth0GetUser token =
    Http.request
        { method = "POST"
        , headers = []
        , url = auth0Endpoint ++ "/userinfo"
        , body =
            Http.jsonBody <|
                Encode.object [ ( "access_token", Encode.string token ) ]
        , expect =
            Http.expectJson (GotAuth0Profile token) User.decodeFromAuth0
        , timeout = Nothing
        , tracker = Nothing
        }


auth0Endpoint : String
auth0Endpoint =
    "https://goodtimes-staging.us.auth0.com"


auth0LoginUrl : String
auth0LoginUrl =
    Auth0.auth0AuthorizeURL
        (Auth0.Auth0Config auth0Endpoint "68MpVR1fV03q6to9Al7JbNAYLTi2lRGT")
        "token"
        "http://localhost:1234/authorized"
        [ "openid", "name", "email", "profile" ]
        (Just "google-oauth2")


view : Model -> Browser.Document Msg
view model =
    case model.page of
        NotFound ->
            Skeleton.view model.isOpenMenu
                ToggleViewMenu
                never
                { title = "Not Found"
                , attrs = []
                , kids = [ Html.div [] [ Html.text "This page does not exist" ] ]
                }

        Login ->
            { title = "Welcome to goodtimes"
            , body =
                [ Html.h2 [] [ Html.text "good times" ]
                , Html.text "You need to log in"
                , Html.a [ Attr.href auth0LoginUrl ] [ Html.text "login" ]
                ]
            }

        LoggedIn userInfo loggedInPage ->
            let
                _ =
                    Debug.log "User" userInfo
            in
            case loggedInPage of
                Feed feed ->
                    Skeleton.view model.isOpenMenu ToggleViewMenu FeedMsg (Feed.view feed)

                Search search ->
                    Skeleton.view model.isOpenMenu ToggleViewMenu SearchMsg (Search.view search)

                SearchUsers search ->
                    Skeleton.view model.isOpenMenu ToggleViewMenu SearchUsersMsg (SearchUsers.view search)

                UserProfile user ->
                    Skeleton.view model.isOpenMenu ToggleViewMenu UserProfileMsg (UserProfile.view user)



-- UPDATE


type Msg
    = None
    | GotAuth0Profile String (Result Http.Error UnverifiedUser)
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | FeedMsg Feed.Msg
    | SearchMsg Search.Msg
    | SearchUsersMsg SearchUsers.Msg
    | UserProfileMsg UserProfile.Msg
    | ToggleViewMenu


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            stepUrl url { model | url = url }

        GotAuth0Profile token result ->
            case result of
                Ok profile ->
                    ( { model | auth = HasUnverifiedUser token profile }
                    , Nav.pushUrl model.key "authorized"
                    )

                Err err ->
                    let
                        _ =
                            Debug.log "error" err
                    in
                    ( model, Cmd.none )

        FeedMsg msge ->
            case model.page of
                LoggedIn userInfo (Feed feed) ->
                    stepFeed model userInfo (Feed.update msge feed)

                _ ->
                    ( model, Cmd.none )

        SearchMsg msge ->
            case model.page of
                LoggedIn userInfo (Search search) ->
                    -- if you receive a search message on the search page, update the Search page. If you recieve another message, ignore
                    stepSearch model userInfo (Search.update msge search)

                _ ->
                    ( model, Cmd.none )

        SearchUsersMsg msge ->
            case model.page of
                LoggedIn userInfo (SearchUsers search) ->
                    stepSearchUsers model userInfo (SearchUsers.update msge search)

                _ ->
                    ( model, Cmd.none )

        UserProfileMsg msge ->
            case model.page of
                LoggedIn userInfo (UserProfile user) ->
                    stepUser model userInfo (UserProfile.update msge user)

                _ ->
                    ( model, Cmd.none )

        ToggleViewMenu ->
            ( { model | isOpenMenu = not model.isOpenMenu }, Cmd.none )

        None ->
            ( model, Cmd.none )


stepFeed : Model -> UserInfo -> ( Feed.Model, Cmd Feed.Msg ) -> ( Model, Cmd Msg )
stepFeed model userInfo ( feed, cmds ) =
    ( { model | page = LoggedIn userInfo (Feed feed) }
    , Cmd.map FeedMsg cmds
    )


stepSearch : Model -> UserInfo -> ( Search.Model, Cmd Search.Msg ) -> ( Model, Cmd Msg )
stepSearch model userInfo ( search, cmds ) =
    ( { model | page = LoggedIn userInfo (Search search) }
    , Cmd.map SearchMsg cmds
    )


stepSearchUsers : Model -> UserInfo -> ( SearchUsers.Model, Cmd SearchUsers.Msg ) -> ( Model, Cmd Msg )
stepSearchUsers model userInfo ( search, cmds ) =
    ( { model | page = LoggedIn userInfo (SearchUsers search) }
    , Cmd.map SearchUsersMsg cmds
    )


stepUser : Model -> UserInfo -> ( UserProfile.Model, Cmd UserProfile.Msg ) -> ( Model, Cmd Msg )
stepUser model userInfo ( user, cmds ) =
    ( { model | page = LoggedIn userInfo (UserProfile user) }
    , Cmd.map UserProfileMsg cmds
    )


parseToken : String -> Maybe String
parseToken string =
    string
        |> String.split "&"
        |> List.map (String.split "=")
        |> List.map intoTuple
        |> Maybe.Extra.values
        |> Dict.fromList
        |> Dict.get "access_token"


intoTuple : List a -> Maybe ( a, a )
intoTuple list =
    case list of
        [ a, b ] ->
            Just ( a, b )

        _ ->
            Nothing



-- access_token=sg3mNLMkW7INs0nPaA2hDQl3-uiXGf1e&scope=openid%20email&expires_in=7200&token_type=Bearer
-- string
--     |> String.split "="


{-| URL to Page
-}
stepUrl : Url.Url -> Model -> ( Model, Cmd Msg )
stepUrl url model =
    case model.auth of
        NotAuthed ->
            case Parser.parse Routes.routeParser (Debug.log "receivedURL" url) of
                Just route ->
                    case route of
                        Routes.Authorized maybeToken ->
                            let
                                maybeTokenToAuth maybeParsedToken =
                                    case maybeParsedToken of
                                        Just token ->
                                            HasToken token

                                        Nothing ->
                                            AuthError "AccessToken didn't parse correctly"

                                newAuth =
                                    maybeToken
                                        |> Maybe.andThen parseToken
                                        |> maybeTokenToAuth
                            in
                            ( { model | auth = newAuth }, Nav.pushUrl model.key "feed" )

                        _ ->
                            ( { model | page = Login }
                            , Cmd.none
                            )

                _ ->
                    ( { model | page = Login }
                    , Cmd.none
                    )

        AuthError str ->
            ( model, Cmd.none )

        HasToken token ->
            ( model, auth0GetUser token )

        HasUnverifiedUser token unverifiedUser ->
            let
                -- TODO actually verify!!
                newAuth =
                    Authenticated token (User.unverifiedToVerifyUser unverifiedUser 1)
            in
            ( { model | auth = newAuth }, Nav.pushUrl model.key "feed" )

        Authenticated token userInfo ->
            case Parser.parse Routes.routeParser url of
                Just route ->
                    case route of
                        Routes.Authorized maybeToken ->
                            ( model, Nav.pushUrl model.key "feed" )

                        Routes.Feed ->
                            let
                                ( feedModel, feedCommand ) =
                                    Feed.init ()
                            in
                            ( { model | page = LoggedIn userInfo (Feed feedModel) }
                            , Cmd.map FeedMsg feedCommand
                            )

                        Routes.User userID ->
                            let
                                ( userProfileModel, userProfileCommand ) =
                                    UserProfile.init userID
                            in
                            ( { model | page = LoggedIn userInfo (UserProfile userProfileModel) }
                            , Cmd.map UserProfileMsg userProfileCommand
                            )

                        Routes.Search ->
                            ( { model | page = LoggedIn userInfo (Search (Tuple.first (Search.init ()))) }
                            , Cmd.none
                            )

                        Routes.SearchUsers ->
                            ( { model | page = LoggedIn userInfo (SearchUsers (Tuple.first (SearchUsers.init ()))) }
                            , Cmd.none
                            )

                        Routes.Login ->
                            ( { model | page = Login }
                            , Cmd.none
                            )

                Nothing ->
                    ( { model | page = NotFound }
                    , Cmd.none
                    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
