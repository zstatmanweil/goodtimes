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
import Routes
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
    let
        _ =
            Debug.log loggedInUser.token 0
    in
    goodTimesRequest
        { token = loggedInUser.token
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
    let
        mediaDetails =
            case event.media of
                BookType book ->
                    viewBookDetails book

                MovieType movie ->
                    viewMovieDetails movie

                TVType tv ->
                    viewTVDetails tv
    in
    Html.li []
        [ Html.div [ class "media-card" ]
            [ Html.div [ class "media-image" ] [ Media.viewMediaCover event.media ]
            , Html.div [ class "media-info" ]
                [ Html.i []
                    [ Html.text <| "(" ++ hrsToString event.timeSince ++ ")"
                    , getMediaStatus logged_in_user_id event
                    ]
                , mediaDetails
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


getMediaStatus : Int -> Event -> Html Msg
getMediaStatus logged_in_user_id event =
    let
        ( actorName, actorTense ) =
            if event.userId == logged_in_user_id then
                ( Html.text "you", Media.Second )

            else
                ( Html.a [ Attr.href <| Routes.user event.userId ]
                    [ Html.text event.fullName ]
                , Media.Third
                )
    in
    Html.span []
        [ actorName
        , Html.text <| Media.conjugate actorTense event.status event.media
        ]


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
