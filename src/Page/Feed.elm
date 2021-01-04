module Page.Feed exposing (..)

import Book exposing (Book)
import Consumption exposing (Status(..))
import Event exposing (..)
import Html exposing (Html)
import Html.Attributes as Attr exposing (class, id)
import Http
import Json.Decode as Decode
import Media exposing (MediaType(..))
import Movie exposing (Movie)
import RemoteData exposing (RemoteData(..), WebData)
import Skeleton
import TV exposing (TV)
import User



-- MODEL


type alias Model =
    { logged_in_user : WebData User.User
    , friends : WebData (List User.User)
    , eventResults : WebData (List Event)
    }


type Msg
    = EventResponse (Result Http.Error (List Event))
    | None


init : () -> ( Model, Cmd Msg )
init _ =
    let
        user =
            Success (User.User 1 "zstat" "zoe" "statman-weil" "zstatmanweil@gmail.com")
    in
    ( { logged_in_user = user
      , friends = NotAsked
      , eventResults = NotAsked
      }
    , getUserAndFriendEvents user
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        None ->
            ( model, Cmd.none )

        EventResponse eventResponse ->
            let
                receivedEvents =
                    RemoteData.fromResult eventResponse
            in
            ( { model
                | eventResults = receivedEvents
              }
            , Cmd.none
            )


getUserAndFriendEvents : WebData User.User -> Cmd Msg
getUserAndFriendEvents user =
    Http.get
        { url = "http://localhost:5000/user/" ++ String.fromInt (User.getUserId user) ++ "/friend/events"
        , expect = Http.expectJson EventResponse (Decode.list Event.decoder)
        }



-- VIEW


view : Model -> Skeleton.Details Msg
view model =
    { title = "Feed"
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
            [ Html.div [ id "user-profile" ] [ Html.text ("Welcome " ++ User.getUsername model.logged_in_user ++ "!") ]
            , Html.div [ class "results" ]
                [ viewEvents model.eventResults ]
            ]
        ]


viewEvents : WebData (List Event) -> Html Msg
viewEvents events =
    case events of
        NotAsked ->
            Html.text "see your friend's events"

        Loading ->
            Html.text "entering the database!"

        Failure error ->
            -- TODO show better error!
            Html.text "something went wrong"

        Success event ->
            if List.isEmpty event then
                Html.text "you have no good times events, start making friends and adding books, tv and movie!"

            else
                Html.ul [ class "book-list" ]
                    (List.map viewEvent event)


viewEvent : Event -> Html Msg
viewEvent event =
    case event.media of
        BookType book ->
            Html.li []
                [ Html.div [ class "media-card" ]
                    [ Html.div [ class "media-image" ] [ viewMediaCover book.coverUrl ]
                    , Html.div [ class "media-info" ]
                        [ Html.i []
                            [ Html.text <|
                                "("
                                    ++ hrsToString event.timeSince
                                    ++ ") "
                                    ++ event.username
                                    ++ " "
                                    ++ getMediaStatusAsString event.media event.status
                            ]
                        , viewBookDetails book
                        ]
                    ]
                ]

        MovieType movie ->
            Html.li []
                [ Html.div [ class "media-card" ]
                    [ Html.div [ class "media-image" ] [ viewMediaCover movie.posterUrl ]
                    , Html.div [ class "media-info" ]
                        [ Html.i []
                            [ Html.text <|
                                "("
                                    ++ hrsToString event.timeSince
                                    ++ ") "
                                    ++ event.username
                                    ++ " "
                                    ++ getMediaStatusAsString event.media event.status
                            ]
                        , viewMovieDetails movie
                        ]
                    ]
                ]

        TVType tv ->
            Html.li []
                [ Html.div [ class "media-card" ]
                    [ Html.div [ class "media-image" ] [ viewMediaCover tv.posterUrl ]
                    , Html.div [ class "media-info" ]
                        [ Html.i []
                            [ Html.text <|
                                "("
                                    ++ hrsToString event.timeSince
                                    ++ ") "
                                    ++ event.username
                                    ++ " "
                                    ++ getMediaStatusAsString event.media event.status
                            ]
                        , viewTVDetails tv
                        ]
                    ]
                ]


viewBookDetails : Book -> Html Msg
viewBookDetails book =
    Html.div []
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
        ]


viewMovieDetails : Movie -> Html Msg
viewMovieDetails movie =
    Html.div []
        [ Html.b [] [ Html.text movie.title ]
        , Html.div [] [ Html.text <| "(" ++ movie.releaseDate ++ ")" ]
        ]


viewTVDetails : TV -> Html Msg
viewTVDetails tv =
    Html.div []
        [ Html.b [] [ Html.text tv.title ]
        , Html.div [] [ Html.text (String.join ", " tv.networks) ]
        , case tv.firstAirDate of
            Just date ->
                Html.text <| "(" ++ date ++ ")"

            Nothing ->
                Html.text ""
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


getMediaStatusAsString : MediaType -> Consumption.Status -> String
getMediaStatusAsString mediaType status =
    case mediaType of
        BookType _ ->
            case status of
                WantToConsume ->
                    "wants to read"

                Consuming ->
                    "is reading"

                Finished ->
                    "read"

                Abandoned ->
                    "abandoned"

        _ ->
            case status of
                WantToConsume ->
                    "wants to watch"

                Consuming ->
                    "is watching"

                Finished ->
                    "watched"

                Abandoned ->
                    "abandoned"


hrsToString : Int -> String
hrsToString hrs =
    if hrs == 1 then
        "1 hr"

    else if hrs < 24 then
        String.fromInt hrs ++ " hrs"

    else
        daysToString (hrs // 24)


daysToString : Int -> String
daysToString day =
    if day == 1 then
        "1 day"

    else
        String.fromInt day ++ " days"
