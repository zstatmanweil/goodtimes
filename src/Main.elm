module Main exposing (..)

import Browser exposing (..)
import Browser.Navigation as Nav
import Html exposing (Html)
import Page.Search as Search
import Page.User as User
import Skeleton
import Url


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
    | Search Search.Model
    | User User.Model



-- INIT


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    ( { url = url
      , key = key
      , page = User (Tuple.first (User.init ()))
      }
    , Cmd.none
    )



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

        Search search ->
            Skeleton.view SearchMsg (Search.view search)

        User user ->
            Skeleton.view UserMsg (User.view user)



-- UPDATE


type Msg
    = None
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | SearchMsg Search.Msg
    | UserMsg User.Msg


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
            ( { model | url = url }
            , Cmd.none
            )

        SearchMsg msge ->
            case model.page of
                Search search ->
                    stepSearch model (Search.update msge search)

                _ ->
                    ( model, Cmd.none )

        UserMsg msge ->
            case model.page of
                User user ->
                    stepUser model (User.update msge user)

                _ ->
                    ( model, Cmd.none )

        None ->
            ( model, Cmd.none )



--TODO: what is this doing exactly?


stepSearch : Model -> ( Search.Model, Cmd Search.Msg ) -> ( Model, Cmd Msg )
stepSearch model ( search, cmds ) =
    ( { model | page = Search search }
    , Cmd.map SearchMsg cmds
    )


stepUser : Model -> ( User.Model, Cmd User.Msg ) -> ( Model, Cmd Msg )
stepUser model ( user, cmds ) =
    ( { model | page = User user }
    , Cmd.map UserMsg cmds
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
