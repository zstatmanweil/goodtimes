module Page.Search exposing (..)

import Book exposing (..)
import Consumption exposing (..)
import GoodtimesAPI exposing (goodTimesRequest)
import Html exposing (Attribute, Html)
import Html.Attributes as Attr exposing (class, id, placeholder, type_)
import Html.Events
import Http
import Json.Decode as Decode exposing (Decoder)
import List.Extra
import Media exposing (..)
import Movie exposing (..)
import RemoteData exposing (RemoteData(..), WebData)
import Skeleton
import TV exposing (..)
import User exposing (LoggedInUser)



-- MODEL


type alias Model =
    { searchResults : WebData (List MediaType)
    , selectedMediaType : MediaSelection
    , query : String
    }


type Msg
    = None
    | SearchMedia
    | UpdateQuery String
    | UpdateMediaSelection MediaSelection
    | MediaResponse (Result Http.Error (List MediaType))
    | AddMediaToProfile MediaType Consumption.Status
    | MediaAddedToProfile (Result Http.Error Consumption)


init : () -> ( Model, Cmd Msg )
init _ =
    ( { searchResults = NotAsked
      , selectedMediaType = NoSelection
      , query = ""
      }
    , Cmd.none
    )



-- Update


update : LoggedInUser -> Msg -> Model -> ( Model, Cmd Msg )
update loggedInUser msg model =
    case msg of
        SearchMedia ->
            if model.selectedMediaType == BookSelection then
                ( model, searchBooks loggedInUser model.query )

            else if model.selectedMediaType == MovieSelection then
                ( model, searchMovies loggedInUser model.query )

            else if model.selectedMediaType == TVSelection then
                ( model, searchTV loggedInUser model.query )

            else
                ( model, Cmd.none )

        MediaResponse mediaResponse ->
            let
                receivedMedia =
                    RemoteData.fromResult mediaResponse
            in
            ( { model | searchResults = receivedMedia }, Cmd.none )

        UpdateQuery newString ->
            ( { model | query = newString }, Cmd.none )

        UpdateMediaSelection mediaSelection ->
            ( { model | selectedMediaType = mediaSelection }, Cmd.none )

        AddMediaToProfile mediaType status ->
            let
                mediaUpdater =
                    List.Extra.updateIf
                        (\b -> b == mediaType)
                        (Media.setMediaStatus status)

                newBooks =
                    RemoteData.map mediaUpdater model.searchResults
            in
            ( { model | searchResults = newBooks }, addMediaToProfile loggedInUser mediaType status )

        MediaAddedToProfile result ->
            case result of
                Ok consumption ->
                    let
                        mediaUpdater : List MediaType -> List MediaType
                        mediaUpdater =
                            List.Extra.updateIf
                                (\b -> Media.getSourceId b == consumption.sourceId)
                                (Media.setMediaStatus consumption.status)

                        newBooks =
                            RemoteData.map mediaUpdater model.searchResults
                    in
                    ( { model | searchResults = newBooks }
                    , Cmd.none
                    )

                Err httpError ->
                    -- TODO handle error!
                    ( model, Cmd.none )

        None ->
            ( model, Cmd.none )


searchBooks : LoggedInUser -> String -> Cmd Msg
searchBooks loggedInUser titleString =
    goodTimesRequest
        { loggedInUser = loggedInUser
        , method = "GET"
        , url = "/books?title=" ++ titleString
        , body = Nothing
        , expect = Http.expectJson MediaResponse (Decode.list (Media.bookToMediaDecoder Book.decoder))
        }


searchMovies : LoggedInUser -> String -> Cmd Msg
searchMovies loggedInUser titleString =
    goodTimesRequest
        { loggedInUser = loggedInUser
        , method = "GET"
        , url = "/movies?title=" ++ titleString
        , body = Nothing
        , expect = Http.expectJson MediaResponse (Decode.list (Media.movieToMediaDecoder Movie.decoder))
        }


searchTV : LoggedInUser -> String -> Cmd Msg
searchTV loggedInUser titleString =
    goodTimesRequest
        { loggedInUser = loggedInUser
        , method = "GET"
        , url = "/tv?title=" ++ titleString
        , body = Nothing
        , expect = Http.expectJson MediaResponse (Decode.list (Media.tvToMediaDecoder TV.decoder))
        }


addMediaToProfile : LoggedInUser -> MediaType -> Consumption.Status -> Cmd Msg
addMediaToProfile loggedInUser mediaType status =
    case mediaType of
        BookType book ->
            goodTimesRequest
                { loggedInUser = loggedInUser
                , method = "POST"
                , url = "/user/" ++ String.fromInt loggedInUser.userInfo.goodTimesId ++ "/media/book"
                , body = Just <| Http.jsonBody (Book.encoderWithStatus book status)
                , expect = Http.expectJson MediaAddedToProfile Consumption.consumptionDecoder
                }

        MovieType movie ->
            goodTimesRequest
                { loggedInUser = loggedInUser
                , method = "POST"
                , url = "/user/" ++ String.fromInt loggedInUser.userInfo.goodTimesId ++ "/media/movie"
                , body = Just <| Http.jsonBody (Movie.encoderWithStatus movie status)
                , expect = Http.expectJson MediaAddedToProfile Consumption.consumptionDecoder
                }

        TVType tv ->
            goodTimesRequest
                { loggedInUser = loggedInUser
                , method = "POST"
                , url = "/user/" ++ String.fromInt loggedInUser.userInfo.goodTimesId ++ "/media/tv"
                , body = Just <| Http.jsonBody (TV.encoderWithStatus tv status)
                , expect = Http.expectJson MediaAddedToProfile Consumption.consumptionDecoder
                }



-- View


view : Model -> Skeleton.Details Msg
view model =
    { title = "Media Search"
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
            [ Html.form
                [ class "searcher"
                , onSubmit SearchMedia
                ]
                [ Html.input
                    [ case model.selectedMediaType of
                        NoSelection ->
                            placeholder "select a media type"

                        BookSelection ->
                            placeholder "book title or author"

                        MovieSelection ->
                            placeholder "movie title"

                        TVSelection ->
                            placeholder "tv title"
                    , Attr.value model.query
                    , Html.Events.onInput UpdateQuery
                    ]
                    []
                , Html.button
                    [ Attr.disabled <| String.isEmpty model.query || model.selectedMediaType == NoSelection ]
                    [ Html.text "search!" ]
                ]
            , Html.div [ class "selector" ]
                [ Html.label []
                    [ Html.input [ type_ "radio", Attr.name "media", Attr.value "books", Html.Events.onClick (UpdateMediaSelection BookSelection) ] []
                    , Html.text "books"
                    ]
                , Html.label []
                    [ Html.input [ type_ "radio", Attr.name "media", Attr.value "movies", Html.Events.onClick (UpdateMediaSelection MovieSelection) ] []
                    , Html.text "movies"
                    ]
                , Html.label []
                    [ Html.input [ type_ "radio", Attr.name "media", Attr.value "tv", Html.Events.onClick (UpdateMediaSelection TVSelection) ] []
                    , Html.text "tv shows"
                    ]
                ]
            , Html.div [ class "results" ]
                [ viewMedias model.searchResults ]
            ]
        ]


viewMedias : WebData (List MediaType) -> Html Msg
viewMedias receivedMedia =
    case receivedMedia of
        NotAsked ->
            Html.div [ class "page-text" ] [ Html.text "select a media type to search!" ]

        Loading ->
            Html.div [ class "page-text" ] [ Html.text "entering the database!" ]

        Failure error ->
            -- TODO show better error!
            Html.div [ class "page-text" ] [ Html.text "something went wrong" ]

        Success media ->
            if List.isEmpty media then
                Html.div [ class "page-text" ] [ Html.text "no results..." ]

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
                        , viewMediaDropdown (BookType book)
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
                        , viewMediaDropdown (MovieType movie)
                        ]
                    ]
                ]

        TVType tv ->
            Html.li []
                [ Html.div [ class "media-card" ]
                    [ Html.div [ class "media-image" ] [ viewMediaCover tv.posterUrl ]
                    , Html.div [ class "media-info" ]
                        [ Html.b [] [ Html.text tv.title ]
                        , Html.div [] [ Html.text (String.join ", " tv.networks) ]
                        , case tv.firstAirDate of
                            Just date ->
                                Html.text <| "(" ++ date ++ ")"

                            Nothing ->
                                Html.text ""
                        , viewMediaDropdown (TVType tv)
                        ]
                    ]
                ]


viewMediaDropdown : MediaType -> Html Msg
viewMediaDropdown mediaType =
    Html.div [ class "dropdown" ] <|
        case mediaType of
            BookType book ->
                case book.status of
                    Nothing ->
                        [ Html.div [ class "media-buttons" ]
                            [ Html.div [ class "dropdown" ]
                                [ Html.button [ class "dropbtn" ] [ Html.text "Add Book >>" ]
                                , viewDropdownContent (BookType book) "to read" "reading" "read"
                                ]
                            ]
                        ]

                    Just status ->
                        [ Html.div [ class "media-buttons" ]
                            [ Html.div [ class "media-existing-status-not-btn" ]
                                [ Html.text (Book.statusAsString status) ]
                            ]
                        ]

            MovieType movie ->
                case movie.status of
                    Nothing ->
                        [ Html.div [ class "media-buttons" ]
                            [ Html.div [ class "dropdown" ]
                                [ Html.button [ class "dropbtn" ] [ Html.text "Add Movie >>" ]
                                , viewDropdownContent (MovieType movie) "to watch" "watching" "watched"
                                ]
                            ]
                        ]

                    Just status ->
                        [ Html.div [ class "media-buttons" ]
                            [ Html.div [ class "media-existing-status-not-btn" ]
                                [ Html.text (Movie.statusAsString status) ]
                            ]
                        ]

            TVType tv ->
                case tv.status of
                    Nothing ->
                        [ Html.div [ class "media-buttons" ]
                            [ Html.div [ class "dropdown" ]
                                [ Html.button [ class "dropbtn" ] [ Html.text "Add TV Show >>" ]
                                , viewDropdownContent (TVType tv) "to watch" "watching" "watched"
                                ]
                            ]
                        ]

                    Just status ->
                        [ Html.div [ class "media-buttons" ]
                            [ Html.div [ class "media-existing-status-not-btn" ]
                                [ Html.text (TV.statusAsString status) ]
                            ]
                        ]


viewDropdownContent : MediaType -> String -> String -> String -> Html Msg
viewDropdownContent mediaType wantToConsume consuming finished =
    Html.div [ class "dropdown-content" ]
        [ Html.p [ Html.Events.onClick (AddMediaToProfile mediaType WantToConsume) ] [ Html.text wantToConsume ]
        , Html.p [ Html.Events.onClick (AddMediaToProfile mediaType Consuming) ] [ Html.text consuming ]
        , Html.p [ Html.Events.onClick (AddMediaToProfile mediaType Finished) ] [ Html.text finished ]
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


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- Helpers


{-| This has to do with the default behavior of forms
-}
onSubmit : msg -> Attribute msg
onSubmit msg =
    Html.Events.preventDefaultOn "submit"
        (Decode.map (\a -> ( a, True )) (Decode.succeed msg))


isJust : Maybe a -> Bool
isJust maybe =
    case maybe of
        Just _ ->
            True

        Nothing ->
            False
