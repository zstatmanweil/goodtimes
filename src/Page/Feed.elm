module Page.Feed exposing (..)

import Book exposing (Book)
import Consumption exposing (Status(..))
import Event exposing (..)
import GoodtimesAPI exposing (goodTimesRequest)
import Html exposing (Html)
import Html.Attributes as Attr exposing (class, id)
import Http
import Json.Decode as Decode
import Media exposing (MediaType(..))
import Movie exposing (Movie)
import RemoteData exposing (RemoteData(..), WebData)
import Skeleton
import TV exposing (TV)
import User exposing (LoggedInUser, UserInfo)



-- MODEL


type alias Model =
    { friends : WebData (List UserInfo)
    , eventResults : WebData (List Event)
    }


type Msg
    = EventResponse (Result Http.Error (List Event))
    | None


init : LoggedInUser -> ( Model, Cmd Msg )
init user =
    ( { friends = NotAsked
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


getUserAndFriendEvents : LoggedInUser -> Cmd Msg
getUserAndFriendEvents loggedInUser =
    goodTimesRequest
        { loggedInUser = loggedInUser
        , method = "GET"
        , url = "/user/" ++ String.fromInt loggedInUser.userInfo.goodTimesId ++ "/friend/events"
        , body = Nothing
        , expect = Http.expectJson EventResponse (Decode.list Event.decoder)
        }



-- VIEW


view : LoggedInUser -> Model -> Skeleton.Details Msg
view loggedInUser model =
    { title = "Feed"
    , attrs = []
    , kids =
        [ Html.div [ class "container", id "page-container" ]
            [ body loggedInUser model
            ]
        ]
    }


body : LoggedInUser -> Model -> Html Msg
body loggedInUser model =
    Html.main_ [ class "content" ]
        [ Html.div [ id "content-wrap" ]
            [ Html.div [ id "user-profile" ] [ Html.text ("Welcome " ++ loggedInUser.userInfo.fullName ++ "!") ]
            , Html.div [ class "results" ]
                [ viewEvents loggedInUser model ]
            ]
        ]


viewEvents : LoggedInUser -> Model -> Html Msg
viewEvents loggedInUser model =
    case model.eventResults of
        NotAsked ->
            Html.text "see your friend's events"

        Loading ->
            Html.text "entering the database!"

        Failure error ->
            -- TODO show better error!
            Html.text "something went wrong"

        Success events ->
            if List.isEmpty events then
                Html.text "you have no good times events, start making friends and adding books, tv and movie!"

            else
                Html.ul [ class "book-list" ]
                    (List.map (viewEvent loggedInUser.userInfo.goodTimesId) events)


viewEvent : Int -> Event -> Html Msg
viewEvent logged_in_user_id event =
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
                                    ++ getMediaStatusAsString logged_in_user_id event
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
                                    ++ getMediaStatusAsString logged_in_user_id event
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
                                    ++ getMediaStatusAsString logged_in_user_id event
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


getMediaStatusAsString : Int -> Event -> String
getMediaStatusAsString logged_in_user_id event =
    case event.media of
        BookType _ ->
            case event.status of
                WantToConsume ->
                    if event.userId == logged_in_user_id then
                        "you want to read"

                    else
                        event.fullName ++ " wants to read"

                Consuming ->
                    if event.userId == logged_in_user_id then
                        "you are reading"

                    else
                        event.fullName ++ " reading"

                Finished ->
                    if event.userId == logged_in_user_id then
                        "you read"

                    else
                        event.fullName ++ " read"

                Abandoned ->
                    if event.userId == logged_in_user_id then
                        "you abandoned"

                    else
                        event.fullName ++ " abandoned"

        _ ->
            case event.status of
                WantToConsume ->
                    if event.userId == logged_in_user_id then
                        "you want to watch"

                    else
                        event.fullName ++ " wants to watch"

                Consuming ->
                    if event.userId == logged_in_user_id then
                        "you are watching"

                    else
                        event.fullName ++ " is watching"

                Finished ->
                    if event.userId == logged_in_user_id then
                        "you watched"

                    else
                        event.fullName ++ " watched"

                Abandoned ->
                    if event.userId == logged_in_user_id then
                        "you abandoned"

                    else
                        event.fullName ++ " abandoned"


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
