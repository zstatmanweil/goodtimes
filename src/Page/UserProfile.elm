module Page.UserProfile exposing (..)

import Book
import Html exposing (Attribute, Html)
import Html.Attributes as Attr exposing (class, id, type_)
import Html.Events
import Http
import Json.Decode as Decode
import Media exposing (MediaSelection(..), MediaType(..))
import Movie
import RemoteData exposing (RemoteData(..), WebData)
import Skeleton
import TV
import User



-- MODEL


type alias Model =
    { user : User.User
    , searchResults : WebData (List MediaType)
    , selectedMediaType : MediaSelection
    }


type Msg
    = None
    | SearchUserMedia MediaSelection
    | MediaResponse (Result Http.Error (List MediaType))
    | UserResponse (Result Http.Error User.User)


init : () -> ( Model, Cmd Msg )
init _ =
    ( { user = User.User "" "" ""
      , searchResults = NotAsked
      , selectedMediaType = NoSelection
      }
    , getUser
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SearchUserMedia mediaSelection ->
            if mediaSelection == BookSelection then
                ( model, searchUserBooks )

            else if mediaSelection == MovieSelection then
                ( model, searchUserMovies )

            else if mediaSelection == TVSelection then
                ( model, searchUserTV )

            else
                ( model, Cmd.none )

        MediaResponse mediaResponse ->
            let
                receivedMedia =
                    RemoteData.fromResult mediaResponse
            in
            ( { model | searchResults = receivedMedia }, Cmd.none )

        UserResponse userResponse ->
            case userResponse of
                Ok user ->
                    ( { model | user = user }, Cmd.none )

                -- TODO: handle error
                Err resp ->
                    ( model, Cmd.none )

        None ->
            ( model, Cmd.none )


searchUserBooks : Cmd Msg
searchUserBooks =
    Http.get
        { url = "http://localhost:5000/user/1/media/book"
        , expect = Http.expectJson MediaResponse (Decode.list (Media.bookToMediaDecoder Book.decoder))
        }


searchUserMovies : Cmd Msg
searchUserMovies =
    Http.get
        { url = "http://localhost:5000/user/1/media/movie"
        , expect = Http.expectJson MediaResponse (Decode.list (Media.movieToMediaDecoder Movie.decoder))
        }


searchUserTV : Cmd Msg
searchUserTV =
    Http.get
        { url = "http://localhost:5000/user/1/media/tv"
        , expect = Http.expectJson MediaResponse (Decode.list (Media.tvToMediaDecoder TV.decoder))
        }


getUser : Cmd Msg
getUser =
    Http.get
        { url = "http://localhost:5000/user/1"
        , expect = Http.expectJson UserResponse User.decoder
        }


view : Model -> Skeleton.Details Msg
view model =
    { title = "User Profile"
    , attrs = []
    , kids =
        [ Html.div [ class "container", id "page-container" ]
            [ body model
            ]
        ]
    }


body : Model -> Html Msg
body model =
    Html.main_ [ class "content" ]
        [ Html.div [ id "content-wrap" ]
            [ Html.div [ id "user-profile" ] [ Html.text ("Welcome" ++ model.user.username ++ "!") ]
            , Html.div [ class "media-selector" ]
                [ Html.label []
                    [ Html.input [ type_ "radio", Attr.name "media", Attr.value "books", Html.Events.onClick (SearchUserMedia BookSelection) ] []
                    , Html.text "books"
                    ]
                , Html.label []
                    [ Html.input [ type_ "radio", Attr.name "media", Attr.value "movies", Html.Events.onClick (SearchUserMedia MovieSelection) ] []
                    , Html.text "movies"
                    ]
                , Html.label []
                    [ Html.input [ type_ "radio", Attr.name "media", Attr.value "tv", Html.Events.onClick (SearchUserMedia TVSelection) ] []
                    , Html.text "tv shows"
                    ]
                ]
            , Html.div [ class "media-results" ]
                [ viewMedias model.searchResults ]
            ]
        ]


viewMedias : WebData (List MediaType) -> Html Msg
viewMedias receivedMedia =
    case receivedMedia of
        NotAsked ->
            Html.text "select a media type to see what you are tracking"

        Loading ->
            Html.text "entering the database!"

        Failure error ->
            -- TODO show better error!
            Html.text "something went wrong"

        Success media ->
            if List.isEmpty media then
                Html.text "no results..."

            else
                Html.ul [ class "book-list" ]
                    (List.map viewMediaType media)


viewMediaType : MediaType -> Html Msg
viewMediaType mediaType =
    case mediaType of
        BookType book ->
            Html.li []
                [ Html.div [ class "media-card" ]
                    [ Html.div [ class "media-image" ] [ viewMediaCover book.coverUrl ]
                    , Html.div [ class "media-info" ]
                        [ Html.b [] [ Html.text book.title ]
                        , Html.div []
                            [ Html.text "by "
                            , Html.text (String.join ", " book.authorNames)
                            ]
                        , case book.publishYear of
                            Just year ->
                                Html.text <| "(" ++ String.fromInt year ++ ")"

                            Nothing ->
                                Html.text ""
                        , Html.div [ class "media-status" ] [ Html.text (Book.maybeStatusAsString book.status) ]
                        ]
                    ]
                ]

        MovieType movie ->
            Html.li []
                [ Html.div [ class "media-card" ]
                    [ Html.div [ class "media-image" ] [ viewMediaCover movie.posterUrl ]
                    , Html.div [ class "media-info" ]
                        [ Html.b [] [ Html.text movie.title ]
                        , Html.text <| "(" ++ movie.releaseDate ++ ")"
                        , Html.div [ class "media-status" ] [ Html.text (Movie.maybeStatusAsString movie.status) ]
                        ]
                    ]
                ]

        TVType tv ->
            Html.li []
                [ Html.div [ class "media-card" ]
                    [ Html.div [ class "media-image" ] [ viewMediaCover tv.posterUrl ]
                    , Html.div [ class "media-info" ]
                        [ Html.b [] [ Html.text tv.title ]
                        , case tv.firstAirDate of
                            Just date ->
                                Html.text <| "(" ++ date ++ ")"

                            Nothing ->
                                Html.text ""
                        , Html.div [ class "media-status" ] [ Html.text (TV.maybeStatusAsString tv.status) ]
                        ]
                    ]
                ]


viewMediaCover : Maybe String -> Html Msg
viewMediaCover maybeCoverUrl =
    case maybeCoverUrl of
        Just srcUrl ->
            Html.img
                [ Attr.src srcUrl ]
                []

        Nothing ->
            Html.div [ class "no-media" ] []
