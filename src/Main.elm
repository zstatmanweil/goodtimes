module Main exposing (..)

import Browser exposing (..)
import Browser.Navigation as Nav
import Html exposing (Html)
import Page.Feed as Feed
import Page.Search as Search
import Page.SearchUsers as SearchUsers
import Page.UserProfile as UserProfile
import Routes exposing (..)
import Skeleton
import Url
import Url.Parser as Parser


main : Program () Model Msg
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


type alias Model =
    { url : Url.Url
    , key : Nav.Key
    , page : Page
    }


type Page
    = NotFound
    | Feed Feed.Model
    | Search Search.Model
    | SearchUsers SearchUsers.Model
    | UserProfile UserProfile.Model



-- INIT


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    stepUrl url
        { url = url
        , key = key
        , page = NotFound
        }



-- VIEW


view : Model -> Browser.Document Msg
view model =
    case model.page of
        NotFound ->
            Skeleton.view never
                { title = "Not Found"
                , attrs = []
                , kids = [ Html.div [] [ Html.text "This page does not exist" ] ]
                }

        Feed feed ->
            Skeleton.view FeedMsg (Feed.view feed)

        Search search ->
            Skeleton.view SearchMsg (Search.view search)

        SearchUsers search ->
            Skeleton.view SearchUsersMsg (SearchUsers.view search)

        UserProfile user ->
            Skeleton.view UserProfileMsg (UserProfile.view user)



-- UPDATE


type Msg
    = None
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | FeedMsg Feed.Msg
    | SearchMsg Search.Msg
    | SearchUsersMsg SearchUsers.Msg
    | UserProfileMsg UserProfile.Msg


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
                Feed feed ->
                    stepFeed model (Feed.update msge feed)

                _ ->
                    ( model, Cmd.none )

        SearchMsg msge ->
            case model.page of
                Search search ->
                    -- if you receive a search message on the search page, update the Search page. If you recieve another message, ignore
                    stepSearch model (Search.update msge search)

                _ ->
                    ( model, Cmd.none )

        SearchUsersMsg msge ->
            case model.page of
                SearchUsers search ->
                    stepSearchUsers model (SearchUsers.update msge search)

                _ ->
                    ( model, Cmd.none )

        UserProfileMsg msge ->
            case model.page of
                UserProfile user ->
                    stepUser model (UserProfile.update msge user)

                _ ->
                    ( model, Cmd.none )

        None ->
            ( model, Cmd.none )


stepFeed : Model -> ( Feed.Model, Cmd Feed.Msg ) -> ( Model, Cmd Msg )
stepFeed model ( feed, cmds ) =
    ( { model | page = Feed feed }
    , Cmd.map FeedMsg cmds
    )


stepSearch : Model -> ( Search.Model, Cmd Search.Msg ) -> ( Model, Cmd Msg )
stepSearch model ( search, cmds ) =
    ( { model | page = Search search }
    , Cmd.map SearchMsg cmds
    )


stepSearchUsers : Model -> ( SearchUsers.Model, Cmd SearchUsers.Msg ) -> ( Model, Cmd Msg )
stepSearchUsers model ( search, cmds ) =
    ( { model | page = SearchUsers search }
    , Cmd.map SearchUsersMsg cmds
    )


stepUser : Model -> ( UserProfile.Model, Cmd UserProfile.Msg ) -> ( Model, Cmd Msg )
stepUser model ( user, cmds ) =
    ( { model | page = UserProfile user }
    , Cmd.map UserProfileMsg cmds
    )


{-| URL to Page
-}
stepUrl : Url.Url -> Model -> ( Model, Cmd Msg )
stepUrl url model =
    case Parser.parse Routes.routeParser url of
        Just route ->
            case route of
                Routes.Feed ->
                    let
                        ( feedModel, feedCommand ) =
                            Feed.init ()
                    in
                    ( { model | page = Feed feedModel }
                    , Cmd.map FeedMsg feedCommand
                    )

                Routes.User userID ->
                    let
                        ( userProfileModel, userProfileCommand ) =
                            UserProfile.init userID
                    in
                    ( { model | page = UserProfile userProfileModel }
                    , Cmd.map UserProfileMsg userProfileCommand
                    )

                Routes.Search ->
                    ( { model | page = Search (Tuple.first (Search.init ())) }
                    , Cmd.none
                    )

                Routes.SearchUsers ->
                    ( { model | page = SearchUsers (Tuple.first (SearchUsers.init ())) }
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
