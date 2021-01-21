module Page.SearchUsers exposing (..)

import GoodtimesAPI exposing (goodTimesRequest)
import Html exposing (Attribute, Html)
import Html.Attributes as Attr exposing (class, id, placeholder)
import Html.Events
import Http
import Json.Decode as Decode
import RemoteData exposing (RemoteData(..), WebData)
import Skeleton
import User exposing (FriendLink, FriendStatus(..), LoggedInUser, UserWithFriendStatus, friendLinkDecoder, friendLinkEncoder)



-- MODEL


type alias Model =
    { searchResults : WebData (List UserWithFriendStatus)
    , query : String
    }


type Msg
    = None
    | SearchUsers
    | UpdateQuery String
    | UserWithFriendStatusResponse (Result Http.Error (List UserWithFriendStatus))
    | RequestFriend UserWithFriendStatus FriendStatus
    | FriendLinkAdded (Result Http.Error FriendLink)


init : () -> ( Model, Cmd Msg )
init _ =
    ( { searchResults = NotAsked
      , query = ""
      }
    , Cmd.none
    )



-- UPDATE


update : LoggedInUser -> Msg -> Model -> ( Model, Cmd Msg )
update loggedInUser msg model =
    case msg of
        SearchUsers ->
            ( model, searchUsers loggedInUser model.query )

        UpdateQuery newString ->
            ( { model | query = newString }, Cmd.none )

        UserWithFriendStatusResponse userResponse ->
            let
                foundUsers =
                    RemoteData.fromResult userResponse
            in
            ( { model | searchResults = foundUsers }, Cmd.none )

        RequestFriend user status ->
            ( model, addFriendLink loggedInUser user status )

        FriendLinkAdded result ->
            case result of
                Ok _ ->
                    ( model, searchUsers loggedInUser model.query )

                Err httpError ->
                    -- TODO handle error!
                    ( model, Cmd.none )

        None ->
            ( model, Cmd.none )


searchUsers : LoggedInUser -> String -> Cmd Msg
searchUsers loggedInUser emailString =
    goodTimesRequest
        loggedInUser
        "GET"
        ("/users?email=" ++ emailString ++ "&user_id=" ++ String.fromInt loggedInUser.userInfo.goodTimesId)
        Nothing
        (Http.expectJson UserWithFriendStatusResponse (Decode.list User.userWithStatusDecoder))


addFriendLink : LoggedInUser -> UserWithFriendStatus -> FriendStatus -> Cmd Msg
addFriendLink loggedInUser user status =
    goodTimesRequest
        loggedInUser
        "POST"
        "/friend"
        (Just
            (Http.jsonBody
                (friendLinkEncoder loggedInUser.userInfo.goodTimesId user.goodTimesId status)
            )
        )
        (Http.expectJson FriendLinkAdded friendLinkDecoder)


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
            Html.text "search for a friend by typing their email!"

        Loading ->
            Html.text "entering the database!"

        Failure error ->
            -- TODO show better error!
            Html.text "something went wrong"

        Success users ->
            if List.isEmpty users then
                Html.text "no results..."

            else
                Html.ul []
                    (List.map viewUser users)


viewUser : UserWithFriendStatus -> Html Msg
viewUser user =
    Html.li []
        [ Html.div [ class "user-card" ]
            [ Html.div [ class "user-info" ]
                [ Html.a [ Attr.href ("/user/" ++ String.fromInt user.goodTimesId) ] [ Html.text (user.firstName ++ " " ++ user.lastName) ]
                , Html.text user.email
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
