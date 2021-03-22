module Page.SearchUsers exposing (..)

import Environment exposing (Environment)
import GoodtimesAPI exposing (goodTimesRequest)
import Html exposing (Attribute, Html)
import Html.Attributes as Attr exposing (class, id, placeholder)
import Html.Events
import Http
import Json.Decode as Decode
import RemoteData exposing (RemoteData(..), WebData)
import Skeleton
import User exposing (FriendLink, FriendStatus(..), LoggedInUser, UserWithFriendStatus, friendLinkDecoder, friendLinkEncoder, viewUserPicture)



-- MODEL


type alias Model =
    { searchResults : WebData (List UserWithFriendStatus)
    , query : String
    , environment : Environment
    }


type Msg
    = None
    | SearchUsers
    | UpdateQuery String
    | UserWithFriendStatusResponse (Result Http.Error (List UserWithFriendStatus))
    | RequestFriend UserWithFriendStatus FriendStatus
    | FriendLinkAdded (Result Http.Error FriendLink)


init : Environment -> ( Model, Cmd Msg )
init environment =
    ( { searchResults = NotAsked
      , query = ""
      , environment = environment
      }
    , Cmd.none
    )



-- UPDATE


update : LoggedInUser -> Msg -> Model -> ( Model, Cmd Msg )
update loggedInUser msg model =
    case msg of
        SearchUsers ->
            ( model, searchUsers model.environment loggedInUser model.query )

        UpdateQuery newString ->
            ( { model | query = newString }, Cmd.none )

        UserWithFriendStatusResponse userResponse ->
            let
                foundUsers =
                    RemoteData.fromResult userResponse
            in
            ( { model | searchResults = foundUsers }, Cmd.none )

        RequestFriend user status ->
            ( model, addFriendLink model.environment loggedInUser user status )

        FriendLinkAdded result ->
            case result of
                Ok _ ->
                    ( model, searchUsers model.environment loggedInUser model.query )

                Err httpError ->
                    -- TODO handle error!
                    ( model, Cmd.none )

        None ->
            ( model, Cmd.none )


searchUsers : Environment -> LoggedInUser -> String -> Cmd Msg
searchUsers environment loggedInUser emailString =
    goodTimesRequest
        { token = loggedInUser.token
        , method = "GET"
        , url = "/users?email=" ++ emailString ++ "&user_id=" ++ String.fromInt loggedInUser.userInfo.goodTimesId
        , body = Nothing
        , expect = Http.expectJson UserWithFriendStatusResponse (Decode.list User.userWithStatusDecoder)
        , environment = environment
        }


addFriendLink : Environment -> LoggedInUser -> UserWithFriendStatus -> FriendStatus -> Cmd Msg
addFriendLink environment loggedInUser user status =
    goodTimesRequest
        { token = loggedInUser.token
        , method = "POST"
        , url = "/friend"
        , body =
            Just
                (Http.jsonBody
                    (friendLinkEncoder
                        loggedInUser.userInfo.goodTimesId
                        user.userInfo.goodTimesId
                        status
                    )
                )
        , expect = Http.expectJson FriendLinkAdded friendLinkDecoder
        , environment = environment
        }


view : Model -> Skeleton.Details Msg
view model =
    { title = "User Search"
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
                , onSubmit SearchUsers
                ]
                [ Html.input
                    [ placeholder "email"
                    , Attr.value model.query
                    , Html.Events.onInput UpdateQuery
                    ]
                    []
                , Html.button
                    [ Attr.disabled <| String.isEmpty model.query ]
                    [ Html.text "search!" ]
                ]
            , Html.div [ class "results" ]
                [ viewUsers model.searchResults ]
            ]
        ]


viewUsers : WebData (List UserWithFriendStatus) -> Html Msg
viewUsers foundUsers =
    case foundUsers of
        NotAsked ->
            Html.div [ class "page-text" ] [ Html.text "search for a friend by typing their email!" ]

        Loading ->
            Html.div [ class "page-text" ] [ Html.text "entering the database!" ]

        Failure error ->
            -- TODO show better error!
            Html.div [ class "page-text" ] [ Html.text "something went wrong" ]

        Success users ->
            if List.isEmpty users then
                Html.div [ class "page-text" ] [ Html.text "no results..." ]

            else
                Html.ul []
                    (List.map viewUser users)


viewUser : UserWithFriendStatus -> Html Msg
viewUser user =
    Html.li []
        [ Html.div [ class "user-card" ]
            [ Html.div [ class "user-image" ] [ viewUserPicture user.userInfo ]
            , Html.div [ class "user-info" ]
                [ Html.a [ Attr.href ("/user/" ++ String.fromInt user.userInfo.goodTimesId) ] [ Html.text (user.userInfo.firstName ++ " " ++ user.userInfo.lastName) ]
                , Html.text user.userInfo.email
                ]
            , viewFriendButton user
            ]
        ]


viewFriendButton : UserWithFriendStatus -> Html Msg
viewFriendButton user =
    Html.div [ class "user-button-wrapper" ] <|
        case user.status of
            Nothing ->
                [ Html.button
                    [ class "user-button"
                    , Html.Events.onClick (RequestFriend user Requested)
                    ]
                    [ Html.text "Add Friend >>" ]
                ]

            Just status ->
                [ Html.div [ class "user-status" ]
                    [ Html.text (User.friendStatusAsString status) ]
                ]



-- Helpers


{-| This has to do with the default behavior of forms
-}
onSubmit : msg -> Attribute msg
onSubmit msg =
    Html.Events.preventDefaultOn "submit"
        (Decode.map (\a -> ( a, True )) (Decode.succeed msg))
