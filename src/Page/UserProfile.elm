module Page.UserProfile exposing (..)

import Book
import Consumption exposing (Consumption, Status(..))
import Html exposing (Attribute, Html)
import Html.Attributes as Attr exposing (class, id)
import Html.Events
import Http
import Json.Decode as Decode
import Media exposing (..)
import Movie
import RemoteData exposing (RemoteData(..), WebData)
import Skeleton
import TV
import User



-- MODEL


type alias Model =
    { user : WebData User.User
    , searchResults : WebData (List MediaType)
    , selectedTab : TabSelection
    }


type Msg
    = None
    | SearchUserMedia TabSelection
    | MediaResponse (Result Http.Error (List MediaType))
    | UserResponse (Result Http.Error User.User)
    | AddMediaToProfile MediaType Consumption.Status
    | MediaAddedToProfile (Result Http.Error Consumption)


type TabSelection
    = BookTab
    | MovieTab
    | TVTab
    | RecommendationTab
    | NoTab


init : Int -> ( Model, Cmd Msg )
init userID =
    ( { user = NotAsked
      , searchResults = NotAsked
      , selectedTab = NoTab
      }
    , getUser userID
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SearchUserMedia tabSelection ->
            if tabSelection == BookTab then
                ( { model | selectedTab = BookTab }, searchUserBooks model.user )

            else if tabSelection == MovieTab then
                ( { model | selectedTab = MovieTab }, searchUserMovies model.user )

            else if tabSelection == TVTab then
                ( { model | selectedTab = TVTab }, searchUserTV model.user )

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
                    ( { model | user = Success user }, Cmd.none )

                -- TODO: handle error
                Err resp ->
                    ( model, Cmd.none )

        AddMediaToProfile mediaType status ->
            ( model, addMediaToProfile mediaType status )

        MediaAddedToProfile result ->
            case result of
                Ok consumption ->
                    if model.selectedTab == BookTab then
                        ( model, searchUserBooks model.user )

                    else if model.selectedTab == MovieTab then
                        ( model, searchUserMovies model.user )

                    else if model.selectedTab == TVTab then
                        ( model, searchUserTV model.user )

                    else
                        ( model, Cmd.none )

                Err httpError ->
                    -- TODO handle error!
                    ( model, Cmd.none )

        None ->
            ( model, Cmd.none )


searchUserBooks : WebData User.User -> Cmd Msg
searchUserBooks user =
    Http.get
        { url = "http://localhost:5000/user/" ++ String.fromInt (User.getUserId user) ++ "/media/book"
        , expect = Http.expectJson MediaResponse (Decode.list (Media.bookToMediaDecoder Book.decoder))
        }


searchUserMovies : WebData User.User -> Cmd Msg
searchUserMovies user =
    Http.get
        { url = "http://localhost:5000/user/" ++ String.fromInt (User.getUserId user) ++ "/media/movie"
        , expect = Http.expectJson MediaResponse (Decode.list (Media.movieToMediaDecoder Movie.decoder))
        }


searchUserTV : WebData User.User -> Cmd Msg
searchUserTV user =
    Http.get
        { url = "http://localhost:5000/user/" ++ String.fromInt (User.getUserId user) ++ "/media/tv"
        , expect = Http.expectJson MediaResponse (Decode.list (Media.tvToMediaDecoder TV.decoder))
        }


getUser : Int -> Cmd Msg
getUser userID =
    Http.get
        { url = "http://localhost:5000/user/" ++ String.fromInt userID
        , expect = Http.expectJson UserResponse User.decoder
        }


addMediaToProfile : MediaType -> Consumption.Status -> Cmd Msg
addMediaToProfile mediaType status =
    case mediaType of
        BookType book ->
            Http.post
                { url = "http://localhost:5000/user/" ++ String.fromInt 1 ++ "/media/book"
                , body = Http.jsonBody (Book.encoderWithStatus book status)
                , expect = Http.expectJson MediaAddedToProfile Consumption.consumptionDecoder
                }

        MovieType movie ->
            Http.post
                { url = "http://localhost:5000/user/" ++ String.fromInt 1 ++ "/media/movie"
                , body = Http.jsonBody (Movie.encoderWithStatus movie status)
                , expect = Http.expectJson MediaAddedToProfile Consumption.consumptionDecoder
                }

        TVType tv ->
            Http.post
                { url = "http://localhost:5000/user/" ++ String.fromInt 1 ++ "/media/tv"
                , body = Http.jsonBody (TV.encoderWithStatus tv status)
                , expect = Http.expectJson MediaAddedToProfile Consumption.consumptionDecoder
                }



-- VIEW


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
            [ Html.div [ id "user-profile" ] [ Html.text ("Welcome " ++ User.getUsername model.user ++ "!") ]
            , Html.div [ class "tab" ]
                [ createTab model BookTab "books"
                , createTab model MovieTab "movies"
                , createTab model TVTab "tv shows"
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
                        , Html.div [ class "media-status" ]
                            [ Html.text (Book.maybeStatusAsString book.status)
                            , viewMediaDropdown (BookType book)
                            ]
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
                        , Html.div [ class "media-status" ]
                            [ Html.text (Movie.maybeStatusAsString movie.status)
                            , viewMediaDropdown (MovieType movie)
                            ]
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
                        , Html.div [ class "media-status" ]
                            [ Html.text (TV.maybeStatusAsString tv.status)
                            , viewMediaDropdown (TVType tv)
                            ]
                        ]
                    ]
                ]


viewMediaDropdown : MediaType -> Html Msg
viewMediaDropdown mediaType =
    Html.div [ class "dropdown" ] <|
        case mediaType of
            BookType book ->
                [ Html.button [ class "dropbtn" ] [ Html.text "update status >>" ]
                , viewDropdownContent (BookType book) "to read" "reading" "read"
                ]

            MovieType movie ->
                [ Html.button [ class "dropbtn" ] [ Html.text "update status >>" ]
                , viewDropdownContent (MovieType movie) "to watch" "watching" "watched"
                ]

            TVType tv ->
                [ Html.button [ class "dropbtn" ] [ Html.text "update status >>" ]
                , viewDropdownContent (TVType tv) "to watch" "watching" "watched"
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



-- TABS


createTab : Model -> TabSelection -> String -> Html Msg
createTab model tabSelection tabString =
    if model.selectedTab == tabSelection then
        Html.button [ class "tablinks active", Html.Events.onClick (SearchUserMedia tabSelection) ] [ Html.text tabString ]

    else
        Html.button [ class "tablinks", Html.Events.onClick (SearchUserMedia tabSelection) ] [ Html.text tabString ]
