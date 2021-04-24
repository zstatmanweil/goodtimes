port module Main exposing (..)

import Browser exposing (..)
import Browser.Navigation as Nav
import Dict
import Environment exposing (Environment(..))
import GoodtimesAPI exposing (goodTimesRequest)
import GoodtimesAuth0 exposing (AuthStatus(..))
import Html exposing (Html)
import Http
import Json.Encode as Encode
import Maybe.Extra
import Page.About as About
import Page.Feed as Feed
import Page.Search as Search
import Page.SearchUsers as SearchUsers
import Page.UserProfile as UserProfile
import Routes exposing (..)
import Skeleton
import Url
import Url.Parser as Parser
import User exposing (LoggedInUser, UnverifiedUser, UserInfo, unverifiedToUserInfo, unverifiedUserEncoder, userInfoDecoder)


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



-- PORTS


port saveAccessToken : String -> Cmd msg


port removeAccessToken : () -> Cmd msg



-- MODEL


type alias Flags =
    { maybeAccessToken : Maybe String
    , environment : String
    }


type alias Model =
    { url : Url.Url
    , key : Nav.Key
    , page : Page
    , isOpenMenu : Bool
    , auth : AuthStatus
    , environment : Environment
    }


type Page
    = NotFound
    | About
    | LoggedIn LoggedInUser LoggedInPage


type LoggedInPage
    = AboutLoggedIn
    | Feed Feed.Model
    | Search Search.Model
    | SearchUsers SearchUsers.Model
    | UserProfile UserProfile.Model



-- INIT


init : Flags -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init { maybeAccessToken, environment } url key =
    let
        decodedEnvironment =
            Environment.toEnvironment environment
                |> Result.withDefault Local
    in
    stepUrl url
        { url = url
        , key = key
        , page = About
        , isOpenMenu = False
        , auth =
            case maybeAccessToken of
                Just token ->
                    HasToken token

                Nothing ->
                    NotAuthed
        , environment = decodedEnvironment
        }



-- VIEW


verifyUser : Environment -> String -> UnverifiedUser -> Cmd Msg
verifyUser environment token unVerifiedUser =
    goodTimesRequest
        { token = token
        , method = "POST"
        , url = "/user"
        , body = Just (Http.jsonBody (unverifiedUserEncoder unVerifiedUser))
        , expect = Http.expectJson (VerifiedUser token) userInfoDecoder
        , environment = environment
        }


view : Model -> Browser.Document Msg
view model =
    let
        msgs =
            { toggleViewMenu = ToggleViewMenu
            , logOut = LogOut
            }
    in
    case model.page of
        NotFound ->
            Skeleton.view model.environment
                model.isOpenMenu
                model.auth
                msgs
                never
                { title = "Not Found"
                , attrs = []
                , kids = [ Html.div [] [ Html.text "This page does not exist" ] ]
                }

        About ->
            Skeleton.view model.environment model.isOpenMenu model.auth msgs never (About.view model.environment Nothing)

        LoggedIn loggedInUser loggedInPage ->
            case loggedInPage of
                AboutLoggedIn ->
                    Skeleton.view model.environment model.isOpenMenu model.auth msgs never (About.view model.environment (Just loggedInUser))

                Feed feedModel ->
                    Skeleton.view model.environment model.isOpenMenu model.auth msgs FeedMsg (Feed.view loggedInUser feedModel)

                Search searchModel ->
                    Skeleton.view model.environment model.isOpenMenu model.auth msgs SearchMsg (Search.view searchModel)

                SearchUsers searchUsersModel ->
                    Skeleton.view model.environment model.isOpenMenu model.auth msgs SearchUsersMsg (SearchUsers.view searchUsersModel)

                UserProfile userProfileModel ->
                    Skeleton.view model.environment model.isOpenMenu model.auth msgs UserProfileMsg (UserProfile.view loggedInUser userProfileModel)



-- UPDATE


type Msg
    = None
    | GotAuth0Profile String (Result Http.Error UnverifiedUser)
    | VerifiedUser String (Result Http.Error UserInfo)
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | FeedMsg Feed.Msg
    | SearchMsg Search.Msg
    | SearchUsersMsg SearchUsers.Msg
    | UserProfileMsg UserProfile.Msg
    | ToggleViewMenu
    | LogOut


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
                    , verifyUser model.environment token profile
                    )

                Err err ->
                    case err of
                        Http.BadStatus 401 ->
                            ( { model | auth = NotAuthed }, Cmd.batch [ Nav.pushUrl model.key "about", removeAccessToken () ] )

                        _ ->
                            ( model, Cmd.none )

        VerifiedUser token result ->
            case result of
                Ok profile ->
                    ( { model | auth = Authenticated (LoggedInUser token profile) }
                    , Cmd.batch
                        [ Nav.pushUrl model.key "/feed"
                        , saveAccessToken token
                        ]
                    )

                Err err ->
                    case err of
                        Http.BadStatus 401 ->
                            ( { model | auth = NotAuthed }, Cmd.batch [ Nav.pushUrl model.key "about", removeAccessToken () ] )

                        _ ->
                            ( model, Cmd.none )

        FeedMsg msge ->
            case model.page of
                LoggedIn loggedInUser (Feed feedModel) ->
                    stepFeed model loggedInUser (Feed.update msge feedModel)

                _ ->
                    ( model, Cmd.none )

        SearchMsg msge ->
            case model.page of
                LoggedIn loggedInUser (Search searchModel) ->
                    -- if you receive a search message on the search page, update the Search page. If you recieve another message, ignore
                    stepSearch model loggedInUser (Search.update loggedInUser msge searchModel)

                _ ->
                    ( model, Cmd.none )

        SearchUsersMsg msge ->
            case model.page of
                LoggedIn loggedInUser (SearchUsers searchUsersModel) ->
                    stepSearchUsers model loggedInUser (SearchUsers.update loggedInUser msge searchUsersModel)

                _ ->
                    ( model, Cmd.none )

        UserProfileMsg msge ->
            case model.page of
                LoggedIn loggedInUser (UserProfile userProfileModel) ->
                    stepUser model loggedInUser (UserProfile.update loggedInUser msge userProfileModel)

                _ ->
                    ( model, Cmd.none )

        ToggleViewMenu ->
            ( { model | isOpenMenu = not model.isOpenMenu }, Cmd.none )

        LogOut ->
            ( { model | auth = NotAuthed }, Cmd.batch [ Nav.pushUrl model.key "about", removeAccessToken () ] )

        None ->
            ( model, Cmd.none )


stepFeed : Model -> LoggedInUser -> ( Feed.Model, Cmd Feed.Msg ) -> ( Model, Cmd Msg )
stepFeed model loggedInUser ( feed, cmds ) =
    ( { model | page = LoggedIn loggedInUser (Feed feed) }
    , Cmd.map FeedMsg cmds
    )


stepSearch : Model -> LoggedInUser -> ( Search.Model, Cmd Search.Msg ) -> ( Model, Cmd Msg )
stepSearch model loggedInUser ( search, cmds ) =
    ( { model | page = LoggedIn loggedInUser (Search search) }
    , Cmd.map SearchMsg cmds
    )


stepSearchUsers : Model -> LoggedInUser -> ( SearchUsers.Model, Cmd SearchUsers.Msg ) -> ( Model, Cmd Msg )
stepSearchUsers model loggedInUser ( search, cmds ) =
    ( { model | page = LoggedIn loggedInUser (SearchUsers search) }
    , Cmd.map SearchUsersMsg cmds
    )


stepUser : Model -> LoggedInUser -> ( UserProfile.Model, Cmd UserProfile.Msg ) -> ( Model, Cmd Msg )
stepUser model loggedInUser ( user, cmds ) =
    ( { model | page = LoggedIn loggedInUser (UserProfile user) }
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


auth0GetUser token env =
    Http.request
        { method = "POST"
        , headers = []
        , url = Environment.auth0Endpoint env ++ "/userinfo"
        , body =
            Http.jsonBody <|
                Encode.object [ ( "access_token", Encode.string token ) ]
        , expect =
            Http.expectJson (GotAuth0Profile token) User.decodeFromAuth0
        , timeout = Nothing
        , tracker = Nothing
        }


{-| URL to Page
-}
stepUrl : Url.Url -> Model -> ( Model, Cmd Msg )
stepUrl url model =
    case model.auth of
        NotAuthed ->
            case Parser.parse Routes.routeParser url of
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
                            ( { model | auth = newAuth }
                            , Nav.pushUrl model.key "/feed"
                            )

                        _ ->
                            ( { model | page = About }
                            , Cmd.none
                            )

                _ ->
                    ( { model | page = About }
                    , Cmd.none
                    )

        AuthError str ->
            ( model, Cmd.none )

        HasToken token ->
            ( model, auth0GetUser token model.environment )

        HasUnverifiedUser token unverifiedUser ->
            -- This is just an interim state, and we only expect
            -- to pass through this through auth0GetUser
            ( model, Cmd.none )

        Authenticated loggedInUser ->
            case Parser.parse Routes.routeParser url of
                Just route ->
                    case route of
                        Routes.Authorized _ ->
                            ( model, Nav.pushUrl model.key "feed" )

                        Routes.Feed ->
                            let
                                ( feedModel, feedCommand ) =
                                    Feed.init { loggedInUser = loggedInUser, environment = model.environment }
                            in
                            ( { model | page = LoggedIn loggedInUser (Feed feedModel) }
                            , Cmd.map FeedMsg feedCommand
                            )

                        Routes.User profileUserId ->
                            let
                                ( userProfileModel, userProfileCommand ) =
                                    UserProfile.init { loggedInUser = loggedInUser, environment = model.environment } profileUserId
                            in
                            ( { model | page = LoggedIn loggedInUser (UserProfile userProfileModel) }
                            , Cmd.map UserProfileMsg userProfileCommand
                            )

                        Routes.Search ->
                            ( { model | page = LoggedIn loggedInUser (Search (Tuple.first (Search.init { environment = model.environment }))) }
                            , Cmd.none
                            )

                        Routes.SearchUsers ->
                            ( { model | page = LoggedIn loggedInUser (SearchUsers (Tuple.first (SearchUsers.init model.environment))) }
                            , Cmd.none
                            )

                        Routes.About ->
                            ( { model | page = LoggedIn loggedInUser AboutLoggedIn }
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
