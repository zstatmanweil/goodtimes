module Main exposing (..)

import Auth0
import Browser exposing (..)
import Browser.Navigation as Nav
import Dict
import Html exposing (Html)
import Html.Attributes as Attr
import Maybe.Extra
import Page.Feed as Feed
import Page.Search as Search
import Page.SearchUsers as SearchUsers
import Page.UserProfile as UserProfile
import Routes exposing (..)
import Skeleton
import Url
import Url.Parser as Parser


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
    , userToken : Maybe String
    }


type Page
    = NotFound
    | Login
    | LoggedIn UserInfo LoggedInPage


type alias UserInfo =
    { username : String }


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
        , userToken = Nothing
        }



-- VIEW


auth0LoginUrl : String
auth0LoginUrl =
    Auth0.auth0AuthorizeURL
        (Auth0.Auth0Config "https://goodtimes-staging.us.auth0.com" "68MpVR1fV03q6to9Al7JbNAYLTi2lRGT")
        "token"
        "http://localhost:1234/authorized"
        [ "openid", "name", "email" ]
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

        FeedMsg msge ->
            case model.page of
                LoggedIn userInfo (Feed feed) ->
                    stepFeed model (Feed.update msge feed)

                _ ->
                    ( model, Cmd.none )

        SearchMsg msge ->
            case model.page of
                LoggedIn userInfo (Search search) ->
                    -- if you receive a search message on the search page, update the Search page. If you recieve another message, ignore
                    stepSearch model (Search.update msge search)

                _ ->
                    ( model, Cmd.none )

        SearchUsersMsg msge ->
            case model.page of
                LoggedIn userInfo (SearchUsers search) ->
                    stepSearchUsers model (SearchUsers.update msge search)

                _ ->
                    ( model, Cmd.none )

        UserProfileMsg msge ->
            case model.page of
                LoggedIn userInfo (UserProfile user) ->
                    stepUser model (UserProfile.update msge user)

                _ ->
                    ( model, Cmd.none )

        ToggleViewMenu ->
            ( { model | isOpenMenu = not model.isOpenMenu }, Cmd.none )

        None ->
            ( model, Cmd.none )


stepFeed : Model -> ( Feed.Model, Cmd Feed.Msg ) -> ( Model, Cmd Msg )
stepFeed model ( feed, cmds ) =
    ( { model | page = LoggedIn dummyUser (Feed feed) }
    , Cmd.map FeedMsg cmds
    )


stepSearch : Model -> ( Search.Model, Cmd Search.Msg ) -> ( Model, Cmd Msg )
stepSearch model ( search, cmds ) =
    ( { model | page = LoggedIn dummyUser (Search search) }
    , Cmd.map SearchMsg cmds
    )


dummyUser =
    { username = "z" }


stepSearchUsers : Model -> ( SearchUsers.Model, Cmd SearchUsers.Msg ) -> ( Model, Cmd Msg )
stepSearchUsers model ( search, cmds ) =
    ( { model | page = LoggedIn dummyUser (SearchUsers search) }
    , Cmd.map SearchUsersMsg cmds
    )


stepUser : Model -> ( UserProfile.Model, Cmd UserProfile.Msg ) -> ( Model, Cmd Msg )
stepUser model ( user, cmds ) =
    ( { model | page = LoggedIn dummyUser (UserProfile user) }
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
    case model.userToken of
        Just token ->
            case Parser.parse Routes.routeParser url of
                Just route ->
                    case route of
                        Routes.Authorized maybeToken ->
                            let
                                parsedToken =
                                    maybeToken
                                        |> Maybe.andThen parseToken
                            in
                            ( { model | userToken = parsedToken }, Nav.pushUrl model.key "feed" )

                        Routes.Feed ->
                            let
                                ( feedModel, feedCommand ) =
                                    Feed.init ()
                            in
                            ( { model | page = LoggedIn dummyUser (Feed feedModel) }
                            , Cmd.map FeedMsg feedCommand
                            )

                        Routes.User userID ->
                            let
                                ( userProfileModel, userProfileCommand ) =
                                    UserProfile.init userID
                            in
                            ( { model | page = LoggedIn dummyUser (UserProfile userProfileModel) }
                            , Cmd.map UserProfileMsg userProfileCommand
                            )

                        Routes.Search ->
                            ( { model | page = LoggedIn dummyUser (Search (Tuple.first (Search.init ()))) }
                            , Cmd.none
                            )

                        Routes.SearchUsers ->
                            ( { model | page = LoggedIn dummyUser (SearchUsers (Tuple.first (SearchUsers.init ()))) }
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

        Nothing ->
            case Parser.parse Routes.routeParser (Debug.log "receivedURL" url) of
                Just route ->
                    case route of
                        Routes.Authorized maybeToken ->
                            let
                                parsedToken =
                                    maybeToken
                                        |> Maybe.andThen parseToken
                            in
                            ( { model | userToken = parsedToken }, Nav.pushUrl model.key "feed" )

                        _ ->
                            ( { model | page = Login }
                            , Cmd.none
                            )

                _ ->
                    ( { model | page = Login }
                    , Cmd.none
                    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
