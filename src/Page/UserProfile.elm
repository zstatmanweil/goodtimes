module Page.UserProfile exposing (..)

import Book exposing (Book)
import Consumption exposing (Consumption, Status(..))
import Html exposing (Attribute, Html)
import Html.Attributes as Attr exposing (class, id)
import Html.Events
import Http
import Json.Decode as Decode
import Media exposing (..)
import Movie exposing (Movie)
import Overlap exposing (OverlapMedia)
import Recommendation exposing (RecommendationType(..), RecommendedByUserMedia, RecommendedToUserMedia, recByUserToRecTypeDecoder, recToUserToRecTypeDecoder, recommendedByUserMediaDecoder, recommendedToUserMediaDecoder)
import RemoteData exposing (RemoteData(..), WebData)
import Skeleton
import TV exposing (TV)
import User exposing (FriendLink, FriendStatus(..), LoggedInUser, Profile(..), UserInfo, UserWithFriendStatus, friendLinkDecoder, friendLinkEncoder, getUserEmail, getUserId, userInfoDecoder)



-- MODEL


type alias Model =
    { profileUser : WebData UserInfo
    , profileType : Profile
    , loggedInUserFriends : WebData (List UserInfo)
    , profileUserFriends : WebData (List UserInfo)
    , searchResults : WebData (List MediaType)
    , filteredMediaResults : WebData (List MediaType)
    , recommendedResults : WebData (List RecommendationType)
    , overlapResults : WebData (List OverlapMedia)
    , filteredOverlapResults : WebData (List OverlapMedia)
    , firstSelectedTab : FirstTabSelection
    , mediaSelectedTab : MediaTabSelection
    , consumptionSelectedTab : ConsumptionTabSelection
    , recommendationSelectedTab : RecommendationTabSelection
    , friendshipSelectedTab : FriendshipTabSelection
    }


type Msg
    = None
    | AddMediaTabRow FirstTabSelection
    | SearchBasedOnMediaTab MediaTabSelection
    | FilterBasedOnConsumptionTab ConsumptionTabSelection
    | AddMediaToProfile MediaType Consumption.Status
    | MediaAddedToProfile (Result Http.Error Consumption)
    | MediaResponse (Result Http.Error (List MediaType))
    | SearchFriendsBasedOnTab FriendshipTabSelection
    | UserResponse (Result Http.Error UserInfo)
    | FriendResponse (Result Http.Error (List UserInfo))
    | AddFriendLink Int FriendStatus
    | FriendLinkAdded (Result Http.Error FriendLink)
    | AddRecommendationTabRow
    | AddRecommendationMediaTabRow RecommendationTabSelection
    | Recommend MediaType UserInfo
    | RecommendationResponse (Result Http.Error Recommendation.Recommendation)
    | RecommendedMediaResponse (Result Http.Error (List RecommendationType))
    | OverlapResponse (Result Http.Error (List OverlapMedia))
    | UserWithFriendStatusResponse (Result Http.Error (List UserWithFriendStatus))


init : Int -> ( Model, Cmd Msg )
init profileUserId =
    ( { profileUser = NotAsked
      , profileType = NoProfile
      , loggedInUserFriends = NotAsked
      , profileUserFriends = NotAsked
      , searchResults = NotAsked
      , filteredMediaResults = NotAsked
      , recommendedResults = NotAsked
      , overlapResults = NotAsked
      , filteredOverlapResults = NotAsked
      , firstSelectedTab = NoFirstTab
      , mediaSelectedTab = NoMediaTab
      , consumptionSelectedTab = NoConsumptionTab
      , recommendationSelectedTab = NoRecommendationTab
      , friendshipSelectedTab = NoFriendshipTab
      }
    , getUser profileUserId
    )



-- UPDATE


update : LoggedInUser -> Msg -> Model -> ( Model, Cmd Msg )
update loggedInUser msg model =
    case msg of
        AddMediaTabRow firstTab ->
            ( { model
                | filteredMediaResults = NotAsked
                , filteredOverlapResults = NotAsked
                , firstSelectedTab = firstTab
                , mediaSelectedTab = NoSelectedMediaTab
                , friendshipSelectedTab = NoFriendshipTab
                , recommendationSelectedTab = NoRecommendationTab
                , consumptionSelectedTab = NoConsumptionTab
              }
            , Cmd.none
            )

        SearchBasedOnMediaTab mediaTabSelection ->
            case model.firstSelectedTab of
                MediaTab ->
                    case model.profileType of
                        LoggedInUserProfile ->
                            let
                                new_model =
                                    { model
                                        | mediaSelectedTab = mediaTabSelection
                                        , consumptionSelectedTab = AllTab
                                        , recommendationSelectedTab = NoRecommendationTab
                                        , friendshipSelectedTab = NoFriendshipTab
                                    }
                            in
                            case mediaTabSelection of
                                BookTab ->
                                    ( new_model
                                    , searchUserBooks loggedInUser loggedInUser.userInfo.goodTimesId
                                    )

                                MovieTab ->
                                    ( new_model
                                    , searchUserMovies loggedInUser loggedInUser.userInfo.goodTimesId
                                    )

                                TVTab ->
                                    ( new_model
                                    , searchUserTV loggedInUser loggedInUser.userInfo.goodTimesId
                                    )

                                _ ->
                                    ( model, Cmd.none )

                        FriendProfile ->
                            let
                                new_model =
                                    { model
                                        | mediaSelectedTab = mediaTabSelection
                                        , consumptionSelectedTab = AllTab
                                        , recommendationSelectedTab = NoRecommendationTab
                                        , friendshipSelectedTab = NoFriendshipTab
                                    }
                            in
                            case mediaTabSelection of
                                BookTab ->
                                    ( new_model
                                    , searchUserBooks loggedInUser (getUserId model.profileUser)
                                    )

                                MovieTab ->
                                    ( new_model
                                    , searchUserMovies loggedInUser (getUserId model.profileUser)
                                    )

                                TVTab ->
                                    ( new_model
                                    , searchUserTV loggedInUser (getUserId model.profileUser)
                                    )

                                _ ->
                                    ( model, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                RecommendationTab ->
                    let
                        new_model =
                            { model
                                | mediaSelectedTab = mediaTabSelection
                                , consumptionSelectedTab = NoConsumptionTab
                                , friendshipSelectedTab = NoFriendshipTab
                            }
                    in
                    case model.recommendationSelectedTab of
                        ToUserTab ->
                            ( new_model
                            , getRecommendedToUserMedia loggedInUser (mediaTabSelectionToString mediaTabSelection)
                            )

                        FromUserTab ->
                            ( new_model
                            , getRecommendedByUserMedia loggedInUser (mediaTabSelectionToString mediaTabSelection)
                            )

                        _ ->
                            ( model, Cmd.none )

                OverlapTab ->
                    let
                        new_model =
                            { model
                                | mediaSelectedTab = mediaTabSelection
                                , consumptionSelectedTab = AllTab
                                , recommendationSelectedTab = NoRecommendationTab
                                , friendshipSelectedTab = NoFriendshipTab
                            }
                    in
                    case mediaTabSelection of
                        BookTab ->
                            ( new_model
                            , getOverlappingMedia "book" loggedInUser (getUserId model.profileUser)
                            )

                        MovieTab ->
                            ( new_model
                            , getOverlappingMedia "movie" loggedInUser (getUserId model.profileUser)
                            )

                        TVTab ->
                            ( new_model
                            , getOverlappingMedia "tv" loggedInUser (getUserId model.profileUser)
                            )

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        FilterBasedOnConsumptionTab consumptionTab ->
            let
                filteredMedia =
                    RemoteData.map (List.filter (resultMatchesStatus consumptionTab)) model.searchResults

                filteredOverlapMedia =
                    RemoteData.map (List.filter (overlapResultMatchesStatus consumptionTab)) model.overlapResults
            in
            ( { model
                | consumptionSelectedTab = consumptionTab
                , filteredMediaResults = filteredMedia
                , filteredOverlapResults = filteredOverlapMedia
              }
            , Cmd.none
            )

        AddMediaToProfile mediaType status ->
            ( model, addMediaToProfile mediaType status loggedInUser )

        MediaAddedToProfile result ->
            case result of
                Ok _ ->
                    case ( model.firstSelectedTab, model.profileType, model.mediaSelectedTab ) of
                        ( MediaTab, LoggedInUserProfile, BookTab ) ->
                            ( model, searchUserBooks loggedInUser loggedInUser.userInfo.goodTimesId )

                        ( MediaTab, LoggedInUserProfile, MovieTab ) ->
                            ( model, searchUserMovies loggedInUser loggedInUser.userInfo.goodTimesId )

                        ( MediaTab, LoggedInUserProfile, TVTab ) ->
                            ( model, searchUserTV loggedInUser loggedInUser.userInfo.goodTimesId )

                        ( MediaTab, FriendProfile, BookTab ) ->
                            ( model, searchUserBooks loggedInUser (getUserId model.profileUser) )

                        ( MediaTab, FriendProfile, MovieTab ) ->
                            ( model, searchUserMovies loggedInUser (getUserId model.profileUser) )

                        ( MediaTab, FriendProfile, TVTab ) ->
                            ( model, searchUserTV loggedInUser (getUserId model.profileUser) )

                        ( OverlapTab, FriendProfile, BookTab ) ->
                            ( model, getOverlappingMedia "book" loggedInUser (getUserId model.profileUser) )

                        ( OverlapTab, FriendProfile, MovieTab ) ->
                            ( model, getOverlappingMedia "movie" loggedInUser (getUserId model.profileUser) )

                        ( OverlapTab, FriendProfile, TVTab ) ->
                            ( model, getOverlappingMedia "tv" loggedInUser (getUserId model.profileUser) )

                        _ ->
                            ( model, Cmd.none )

                Err httpError ->
                    -- TODO handle error!
                    ( model, Cmd.none )

        MediaResponse mediaResponse ->
            let
                receivedMedia =
                    RemoteData.fromResult mediaResponse
            in
            ( { model
                | searchResults = receivedMedia
                , filteredMediaResults = RemoteData.map (List.filter (resultMatchesStatus model.consumptionSelectedTab)) receivedMedia
              }
            , Cmd.none
            )

        SearchFriendsBasedOnTab friendshipTab ->
            case model.profileType of
                LoggedInUserProfile ->
                    let
                        new_model =
                            { model
                                | firstSelectedTab = FriendsTab
                                , mediaSelectedTab = NoMediaTab
                                , consumptionSelectedTab = NoConsumptionTab
                                , recommendationSelectedTab = NoRecommendationTab
                                , friendshipSelectedTab = friendshipTab
                                , loggedInUserFriends = Loading
                            }
                    in
                    case friendshipTab of
                        ExistingFriendsTab ->
                            ( new_model
                            , getExistingFriends loggedInUser loggedInUser.userInfo.goodTimesId
                            )

                        RequestedFriendsTab ->
                            ( new_model
                            , getFriendRequests loggedInUser
                            )

                        _ ->
                            ( model, Cmd.none )

                FriendProfile ->
                    let
                        new_model =
                            { model
                                | firstSelectedTab = FriendsTab
                                , mediaSelectedTab = NoMediaTab
                                , consumptionSelectedTab = NoConsumptionTab
                                , recommendationSelectedTab = NoRecommendationTab
                                , friendshipSelectedTab = NoFriendshipTab
                                , profileUserFriends = Loading
                            }
                    in
                    ( new_model
                    , getExistingFriends loggedInUser (getUserId model.profileUser)
                    )

                _ ->
                    ( model, Cmd.none )

        UserResponse userResponse ->
            case userResponse of
                Ok user ->
                    if loggedInUser.userInfo.goodTimesId == user.goodTimesId then
                        ( { model
                            | profileType = LoggedInUserProfile
                            , profileUser = Success user
                          }
                        , getExistingFriends loggedInUser loggedInUser.userInfo.goodTimesId
                        )

                    else
                        ( { model
                            | profileUser = Success user
                          }
                        , searchUsers loggedInUser.userInfo.goodTimesId user.email
                        )

                -- TODO: handle error
                Err resp ->
                    ( model, Cmd.none )

        UserWithFriendStatusResponse users ->
            let
                --searching by exact email there will only be one result
                userResults =
                    RemoteData.fromResult users
            in
            case userResults of
                Success userList ->
                    case List.head userList of
                        Just userWithFriendStatus ->
                            case userWithFriendStatus.status of
                                Just status ->
                                    case status of
                                        Accepted ->
                                            ( { model | profileType = FriendProfile }, Cmd.none )

                                        _ ->
                                            ( { model | profileType = StrangerProfile userWithFriendStatus }, Cmd.none )

                                Nothing ->
                                    ( { model | profileType = StrangerProfile userWithFriendStatus }, Cmd.none )

                        Nothing ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        FriendResponse friendResponse ->
            case friendResponse of
                Ok friends ->
                    case model.profileType of
                        FriendProfile ->
                            ( { model | profileUserFriends = Success friends }, Cmd.none )

                        _ ->
                            ( { model | loggedInUserFriends = Success friends }, Cmd.none )

                -- TODO: handle error
                Err resp ->
                    ( model, Cmd.none )

        AddFriendLink userId friendStatus ->
            ( model, addFriendLink loggedInUser userId friendStatus )

        FriendLinkAdded result ->
            case result of
                Ok _ ->
                    case model.profileType of
                        LoggedInUserProfile ->
                            ( model, getFriendRequests loggedInUser )

                        _ ->
                            ( model, searchUsers loggedInUser.userInfo.goodTimesId (getUserEmail model.profileUser) )

                Err httpError ->
                    -- TODO handle error!
                    ( model, Cmd.none )

        AddRecommendationTabRow ->
            ( { model
                | filteredMediaResults = NotAsked
                , recommendedResults = NotAsked
                , firstSelectedTab = RecommendationTab
                , mediaSelectedTab = NoMediaTab
                , recommendationSelectedTab = NoSelectedRecommendationTab
                , consumptionSelectedTab = NoConsumptionTab
                , friendshipSelectedTab = NoFriendshipTab
              }
            , Cmd.none
            )

        AddRecommendationMediaTabRow recTab ->
            ( { model
                | recommendedResults = NotAsked
                , mediaSelectedTab = NoSelectedMediaTab
                , friendshipSelectedTab = NoFriendshipTab
                , recommendationSelectedTab = recTab
              }
            , Cmd.none
            )

        Recommend mediaType friend ->
            ( model, recommendMedia loggedInUser friend.goodTimesId mediaType Recommendation.Pending )

        RecommendationResponse rec ->
            -- TODO: what do do with this response?
            case rec of
                Ok _ ->
                    ( model, Cmd.none )

                -- TODO: handle error
                Err resp ->
                    ( model, Cmd.none )

        RecommendedMediaResponse recommendedMediaResponse ->
            let
                receivedRecommendation =
                    RemoteData.fromResult recommendedMediaResponse
            in
            ( { model | recommendedResults = receivedRecommendation }, Cmd.none )

        OverlapResponse overlapMediaResponse ->
            let
                receivedOverlapMedia =
                    RemoteData.fromResult overlapMediaResponse
            in
            ( { model
                | overlapResults = receivedOverlapMedia
                , filteredOverlapResults = receivedOverlapMedia
              }
            , Cmd.none
            )

        None ->
            ( model, Cmd.none )


searchUserBooks : LoggedInUser -> Int -> Cmd Msg
searchUserBooks loggedInUser userId =
    Http.get
        { url = "http://localhost:5000/user/" ++ String.fromInt userId ++ "/media/book"
        , expect = Http.expectJson MediaResponse (Decode.list (Media.bookToMediaDecoder Book.decoder))
        }


searchUserMovies : LoggedInUser -> Int -> Cmd Msg
searchUserMovies loggedInUser userId =
    Http.get
        { url = "http://localhost:5000/user/" ++ String.fromInt userId ++ "/media/movie"
        , expect = Http.expectJson MediaResponse (Decode.list (Media.movieToMediaDecoder Movie.decoder))
        }


searchUserTV : LoggedInUser -> Int -> Cmd Msg
searchUserTV loggedInUser userId =
    Http.get
        { url = "http://localhost:5000/user/" ++ String.fromInt userId ++ "/media/tv"
        , expect = Http.expectJson MediaResponse (Decode.list (Media.tvToMediaDecoder TV.decoder))
        }


getUser : Int -> Cmd Msg
getUser userID =
    Http.get
        { url = "http://localhost:5000/user/" ++ String.fromInt userID
        , expect = Http.expectJson UserResponse userInfoDecoder
        }


getExistingFriends : LoggedInUser -> Int -> Cmd Msg
getExistingFriends loggedInUser userId =
    Http.get
        { url = "http://localhost:5000/user/" ++ String.fromInt userId ++ "/friends"
        , expect = Http.expectJson FriendResponse (Decode.list userInfoDecoder)
        }


getFriendRequests : LoggedInUser -> Cmd Msg
getFriendRequests loggedInUser =
    Http.get
        { url = "http://localhost:5000/user/" ++ String.fromInt loggedInUser.userInfo.goodTimesId ++ "/requests"
        , expect = Http.expectJson FriendResponse (Decode.list userInfoDecoder)
        }


addFriendLink : LoggedInUser -> Int -> FriendStatus -> Cmd Msg
addFriendLink loggedInUser currentUserId status =
    Http.post
        { url = "http://localhost:5000/friend"
        , body = Http.jsonBody (friendLinkEncoder loggedInUser.userInfo.goodTimesId currentUserId status)
        , expect = Http.expectJson FriendLinkAdded friendLinkDecoder
        }


searchUsers : Int -> String -> Cmd Msg
searchUsers userId emailString =
    Http.get
        { url = "http://localhost:5000/users?email=" ++ emailString ++ "&user_id=" ++ String.fromInt userId
        , expect = Http.expectJson UserWithFriendStatusResponse (Decode.list User.userWithStatusDecoder)
        }


getRecommendedToUserMedia : LoggedInUser -> String -> Cmd Msg
getRecommendedToUserMedia loggedInUser mediaType =
    Http.get
        { url = "http://localhost:5000/user/" ++ String.fromInt loggedInUser.userInfo.goodTimesId ++ "/recommendations/" ++ mediaType
        , expect = Http.expectJson RecommendedMediaResponse (Decode.list (recToUserToRecTypeDecoder recommendedToUserMediaDecoder))
        }


getRecommendedByUserMedia : LoggedInUser -> String -> Cmd Msg
getRecommendedByUserMedia loggedInUser mediaType =
    Http.get
        { url = "http://localhost:5000/user/" ++ String.fromInt loggedInUser.userInfo.goodTimesId ++ "/recommended/" ++ mediaType
        , expect = Http.expectJson RecommendedMediaResponse (Decode.list (recByUserToRecTypeDecoder recommendedByUserMediaDecoder))
        }


recommendMedia : LoggedInUser -> Int -> MediaType -> Recommendation.Status -> Cmd Msg
recommendMedia recommenderUser recommendedUserID mediaType recommendation =
    Http.post
        { url = "http://localhost:5000/media/" ++ Media.getMediaTypeAsString mediaType ++ "/recommendation"
        , body = Http.jsonBody (Recommendation.encoder mediaType recommenderUser.userInfo.goodTimesId recommendedUserID recommendation)
        , expect = Http.expectJson RecommendationResponse Recommendation.decoder
        }


getOverlappingMedia : String -> LoggedInUser -> Int -> Cmd Msg
getOverlappingMedia mediaType loggedInUser friendUserId =
    Http.get
        { url = "http://localhost:5000/overlaps/" ++ mediaType ++ "/" ++ String.fromInt loggedInUser.userInfo.goodTimesId ++ "/" ++ String.fromInt friendUserId
        , expect = Http.expectJson OverlapResponse (Decode.list Overlap.overlapMediaDecoder)
        }


addMediaToProfile : MediaType -> Consumption.Status -> LoggedInUser -> Cmd Msg
addMediaToProfile mediaType status loggedInUser =
    case mediaType of
        BookType book ->
            Http.post
                { url = "http://localhost:5000/user/" ++ String.fromInt loggedInUser.userInfo.goodTimesId ++ "/media/book"
                , body = Http.jsonBody (Book.encoderWithStatus book status)
                , expect = Http.expectJson MediaAddedToProfile Consumption.consumptionDecoder
                }

        MovieType movie ->
            Http.post
                { url = "http://localhost:5000/user/" ++ String.fromInt loggedInUser.userInfo.goodTimesId ++ "/media/movie"
                , body = Http.jsonBody (Movie.encoderWithStatus movie status)
                , expect = Http.expectJson MediaAddedToProfile Consumption.consumptionDecoder
                }

        TVType tv ->
            Http.post
                { url = "http://localhost:5000/user/" ++ String.fromInt loggedInUser.userInfo.goodTimesId ++ "/media/tv"
                , body = Http.jsonBody (TV.encoderWithStatus tv status)
                , expect = Http.expectJson MediaAddedToProfile Consumption.consumptionDecoder
                }



-- VIEW


view : LoggedInUser -> Model -> Skeleton.Details Msg
view loggedInUser model =
    { title = "User Profile"
    , attrs = []
    , kids =
        [ Html.div [ class "container", id "page-container" ]
            [ body loggedInUser model
            ]
        ]
    }


body : LoggedInUser -> Model -> Html Msg
body loggedInUser model =
    case model.profileType of
        LoggedInUserProfile ->
            Html.main_ [ class "content" ]
                [ Html.div [ id "content-wrap" ]
                    [ Html.div [ id "user-profile" ] [ Html.text ("welcome " ++ String.toLower loggedInUser.userInfo.fullName ++ "!") ]
                    , Html.div [ class "tab" ]
                        [ createFirstTab model MediaTab "my media"
                        , createFirstTab model RecommendationTab "recommendations"
                        , createFirstTab model FriendsTab "friends"
                        ]
                    , viewFriendshipTabRow model
                    , viewRecommendationTabRow model
                    , viewMediaTabRow model
                    , viewConsumptionTabRow model
                    , Html.div [ class "results" ]
                        [ viewTabContent model (Success loggedInUser.userInfo) ]
                    ]
                ]

        FriendProfile ->
            Html.main_ [ class "content" ]
                [ Html.div [ id "content-wrap" ]
                    [ Html.div [ id "user-profile" ] [ Html.text (String.toLower (User.getUserFullName model.profileUser) ++ "'s profile!") ]
                    , Html.div [ class "tab" ]
                        [ createFirstTab model MediaTab (User.getUserFirstName model.profileUser ++ "'s media")
                        , createFirstTab model OverlapTab "overlapping media"
                        , createFirstTab model FriendsTab (User.getUserFirstName model.profileUser ++ "'s friends")
                        ]
                    , viewFriendshipTabRow model
                    , viewRecommendationTabRow model
                    , viewMediaTabRow model
                    , viewConsumptionTabRow model
                    , Html.div [ class "results" ]
                        [ viewTabContent model model.profileUser ]
                    ]
                ]

        StrangerProfile userWithFriendStatus ->
            Html.main_ [ class "content" ]
                [ Html.div [ id "content-wrap" ]
                    [ Html.div [ id "user-profile" ] [ Html.text (String.toLower (User.getUserFullName model.profileUser) ++ "'s profile!") ]
                    , Html.div [ class "results", class "page-text" ] [ Html.text ("Become " ++ User.getUserFullName model.profileUser ++ "'s friend to see their profile...") ]
                    , viewFriendButton userWithFriendStatus
                    ]
                ]

        NoProfile ->
            Html.main_ [ class "content" ]
                [ Html.div [ id "content-wrap" ] [ Html.text "something is up" ] ]


viewFriendButton : UserWithFriendStatus -> Html Msg
viewFriendButton user =
    Html.div [ class "user-button-wrapper" ] <|
        case user.status of
            Nothing ->
                [ Html.button
                    [ class "user-button"
                    , Html.Events.onClick (AddFriendLink user.id Requested)
                    ]
                    [ Html.text "Add Friend >>" ]
                ]

            Just status ->
                [ Html.div [ class "user-status" ]
                    [ Html.text (User.friendStatusAsString status) ]
                ]


viewTabContent : Model -> WebData UserInfo -> Html Msg
viewTabContent model profileUserInfo =
    case model.firstSelectedTab of
        RecommendationTab ->
            viewRecommendations model.recommendedResults

        MediaTab ->
            viewMedias model.filteredMediaResults model.loggedInUserFriends profileUserInfo model.profileType

        FriendsTab ->
            case ( model.profileType, model.friendshipSelectedTab ) of
                ( LoggedInUserProfile, ExistingFriendsTab ) ->
                    viewFriends model.loggedInUserFriends

                ( LoggedInUserProfile, RequestedFriendsTab ) ->
                    viewFriendRequests model.loggedInUserFriends

                ( FriendProfile, _ ) ->
                    viewFriends model.profileUserFriends

                ( _, _ ) ->
                    Html.div [ class "page-text" ] [ Html.text "something went wrong" ]

        OverlapTab ->
            viewOverlapMedias model.filteredOverlapResults

        _ ->
            Html.div [ class "page-text" ] [ Html.text "select a tab and start exploring!" ]


viewMediaTabRow : Model -> Html Msg
viewMediaTabRow model =
    if model.mediaSelectedTab /= NoMediaTab then
        Html.div [ class "tab" ]
            [ createMediaTab model BookTab "books"
            , createMediaTab model MovieTab "movies"
            , createMediaTab model TVTab "tv shows"
            ]

    else
        Html.div [] []


viewConsumptionTabRow : Model -> Html Msg
viewConsumptionTabRow model =
    if model.consumptionSelectedTab /= NoConsumptionTab then
        Html.div [ class "tab" ]
            [ createConsumptionTab model AllTab (consumptionTabSelectionToString model.mediaSelectedTab AllTab)
            , createConsumptionTab model WantToConsumeTab (consumptionTabSelectionToString model.mediaSelectedTab WantToConsumeTab)
            , createConsumptionTab model ConsumingTab (consumptionTabSelectionToString model.mediaSelectedTab ConsumingTab)
            , createConsumptionTab model FinishedTab (consumptionTabSelectionToString model.mediaSelectedTab FinishedTab)
            ]

    else
        Html.div [] []


viewRecommendationTabRow : Model -> Html Msg
viewRecommendationTabRow model =
    if model.recommendationSelectedTab /= NoRecommendationTab then
        Html.div [ class "tab" ]
            [ createRecommendationTab model ToUserTab "to me"
            , createRecommendationTab model FromUserTab "from me"
            ]

    else
        Html.div [] []


viewFriendshipTabRow : Model -> Html Msg
viewFriendshipTabRow model =
    case model.profileType of
        LoggedInUserProfile ->
            if model.friendshipSelectedTab /= NoFriendshipTab then
                Html.div [ class "tab" ]
                    [ createFriendshipTab model ExistingFriendsTab "existing"
                    , createFriendshipTab model RequestedFriendsTab "requests"
                    ]

            else
                Html.div [] []

        _ ->
            Html.div [] []


viewFriends : WebData (List UserInfo) -> Html Msg
viewFriends friends =
    case friends of
        NotAsked ->
            Html.div [ class "page-text" ] [ Html.text "you want friends" ]

        Loading ->
            Html.div [ class "page-text" ] [ Html.text "looking for friends!" ]

        Failure error ->
            -- TODO show better error!
            Html.div [ class "page-text" ] [ Html.text "something went wrong" ]

        Success users ->
            if List.isEmpty users then
                Html.div [ class "page-text" ] [ Html.text "no friends..." ]

            else
                Html.ul []
                    (List.map viewFriend users)


viewFriend : UserInfo -> Html Msg
viewFriend user =
    Html.li []
        [ Html.div [ class "user-card" ]
            [ Html.div [ class "user-info" ]
                [ Html.a [ Attr.href (String.fromInt user.goodTimesId) ] [ Html.text (String.toLower (user.firstName ++ " " ++ user.lastName)) ]
                , Html.text user.email
                ]
            ]
        ]


viewFriendRequests : WebData (List UserInfo) -> Html Msg
viewFriendRequests friends =
    case friends of
        NotAsked ->
            Html.text "looking for friends?"

        Loading ->
            Html.text "entering the database!"

        Failure error ->
            -- TODO show better error!
            Html.text "something went wrong"

        Success users ->
            if List.isEmpty users then
                Html.text "no friend requests..."

            else
                Html.ul []
                    (List.map viewFriendRequest users)


viewFriendRequest : UserInfo -> Html Msg
viewFriendRequest user =
    Html.li []
        [ Html.div [ class "user-card" ]
            [ Html.div [ class "user-info" ]
                [ Html.b [] [ Html.text (user.firstName ++ " " ++ user.lastName) ]
                , Html.text user.email
                ]
            , viewAcceptFriendButton user
            ]
        ]


viewAcceptFriendButton : UserInfo -> Html Msg
viewAcceptFriendButton user =
    Html.div [ class "user-button-wrapper" ] <|
        [ Html.button
            [ class "user-button"
            , Html.Events.onClick (AddFriendLink user.goodTimesId Accepted)
            ]
            [ Html.text "Accept Friend >>" ]
        ]


viewMedias : WebData (List MediaType) -> WebData (List UserInfo) -> WebData UserInfo -> Profile -> Html Msg
viewMedias receivedMedia friends userInfo profileType =
    case receivedMedia of
        NotAsked ->
            Html.div [ class "page-text" ] [ Html.text "select a media type" ]

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
                    (List.map (viewMediaType friends profileType) (List.sortBy Media.getTitle media))


viewMediaType : WebData (List UserInfo) -> Profile -> MediaType -> Html Msg
viewMediaType friends profileType mediaType =
    case mediaType of
        BookType book ->
            Html.li []
                [ Html.div [ class "media-card" ]
                    [ Html.div [ class "media-image" ] [ viewMediaCover book.coverUrl ]
                    , Html.div [ class "media-info" ]
                        [ viewBookDetails book
                        , Html.div [ class "media-buttons" ]
                            [ viewFriendMediaStatus (BookType book)
                            , Html.div
                                []
                                [ viewFriendsToRecommendDropdown profileType (BookType book) friends ]
                            ]
                        ]
                    ]
                ]

        MovieType movie ->
            Html.li []
                [ Html.div [ class "media-card" ]
                    [ Html.div [ class "media-image" ] [ viewMediaCover movie.posterUrl ]
                    , Html.div [ class "media-info" ]
                        [ viewMovieDetails movie
                        , Html.div [ class "media-buttons" ]
                            [ viewFriendMediaStatus (MovieType movie)
                            , Html.div []
                                [ viewFriendsToRecommendDropdown profileType (MovieType movie) friends ]
                            ]
                        ]
                    ]
                ]

        TVType tv ->
            Html.li []
                [ Html.div [ class "media-card" ]
                    [ Html.div [ class "media-image" ] [ viewMediaCover tv.posterUrl ]
                    , Html.div [ class "media-info" ]
                        [ viewTVDetails tv
                        , Html.div [ class "media-buttons" ]
                            [ viewFriendMediaStatus (TVType tv)
                            , Html.div []
                                [ viewFriendsToRecommendDropdown profileType (TVType tv) friends ]
                            ]
                        ]
                    ]
                ]


viewOverlapMedias : WebData (List OverlapMedia) -> Html Msg
viewOverlapMedias overlapMedia =
    case overlapMedia of
        NotAsked ->
            Html.div [ class "page-text" ] [ Html.text "see your overlapping media" ]

        Loading ->
            Html.div [ class "page-text" ] [ Html.text "entering the database!" ]

        Failure error ->
            -- TODO show better error!
            Html.div [ class "page-text" ] [ Html.text "something went wrong" ]

        Success media ->
            if List.isEmpty media then
                Html.div [ class "page-text" ] [ Html.text "no overlapping media..." ]

            else
                Html.ul [ class "book-list" ]
                    (List.map viewOverlappingMedia media)


viewOverlappingMedia : OverlapMedia -> Html Msg
viewOverlappingMedia overlapMedia =
    case overlapMedia.media of
        BookType book ->
            Html.li []
                [ Html.div [ class "media-card", class "media-card-long" ]
                    [ Html.div [ class "media-image" ] [ viewMediaCover book.coverUrl ]
                    , Html.div [ class "media-info" ]
                        [ viewBookDetails book
                        , viewOverlappingMediaStatus (BookType book) overlapMedia.otherUserStatus
                        ]
                    ]
                ]

        MovieType movie ->
            Html.li []
                [ Html.div [ class "media-card", class "media-card-long" ]
                    [ Html.div [ class "media-image" ] [ viewMediaCover movie.posterUrl ]
                    , Html.div [ class "media-info" ]
                        [ viewMovieDetails movie
                        , viewOverlappingMediaStatus (MovieType movie) overlapMedia.otherUserStatus
                        ]
                    ]
                ]

        TVType tv ->
            Html.li []
                [ Html.div [ class "media-card", class "media-card-long" ]
                    [ Html.div [ class "media-image" ] [ viewMediaCover tv.posterUrl ]
                    , Html.div [ class "media-info" ]
                        [ viewTVDetails tv
                        , viewOverlappingMediaStatus (TVType tv) overlapMedia.otherUserStatus
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


viewMediaStatusDropdown : MediaType -> Html Msg
viewMediaStatusDropdown mediaType =
    Html.div [ class "dropdown" ] <|
        case mediaType of
            BookType book ->
                [ Html.button [ class "dropbtn-existing-status" ] [ Html.text (Book.maybeStatusAsString book.status ++ " >>") ]
                , viewDropdownContent (BookType book) "to read" "reading" "read" "abandon"
                ]

            MovieType movie ->
                [ Html.button [ class "dropbtn-existing-status" ] [ Html.text (Movie.maybeStatusAsString movie.status ++ " >>") ]
                , viewDropdownContent (MovieType movie) "to watch" "watching" "watched" "abandon"
                ]

            TVType tv ->
                [ Html.button [ class "dropbtn-existing-status" ] [ Html.text (TV.maybeStatusAsString tv.status ++ " >>") ]
                , viewDropdownContent (TVType tv) "to watch" "watching" "watched" "abandon"
                ]


viewFriendMediaStatus : MediaType -> Html Msg
viewFriendMediaStatus mediaType =
    Html.div [ class "media-status" ] <|
        case mediaType of
            BookType book ->
                [ Html.button [ class "friend-media-existing-status-not-btn" ]
                    [ Html.text ("friend's status: " ++ Book.maybeStatusAsString book.status ++ " >>") ]
                ]

            MovieType movie ->
                [ Html.button [ class "friend-media-existing-status-not-btn" ]
                    [ Html.text ("friend's status: " ++ Movie.maybeStatusAsString movie.status ++ " >>") ]
                ]

            TVType tv ->
                [ Html.button [ class "friend-media-existing-status-not-btn" ]
                    [ Html.text ("friend's status: " ++ TV.maybeStatusAsString tv.status ++ " >>") ]
                ]


viewOverlappingMediaStatus : MediaType -> Consumption.Status -> Html Msg
viewOverlappingMediaStatus mediaType otherUserStatus =
    case mediaType of
        BookType book ->
            Html.div [ class "media-buttons" ]
                [ Html.div [ class "media-status" ]
                    [ Html.div [ class "dropdown" ]
                        [ Html.div [ class "dropbtn-existing-status" ]
                            [ Html.text ("your status: " ++ Book.maybeStatusAsString book.status ++ " >>") ]
                        , viewDropdownContent (BookType book) "to read" "reading" "read" "abandon"
                        ]
                    ]
                , Html.div [ class "media-status" ]
                    [ Html.div [ class "friend-media-existing-status-not-btn" ] [ Html.text ("friend's status: " ++ Book.maybeStatusAsString (Just otherUserStatus)) ]
                    ]
                ]

        MovieType movie ->
            Html.div [ class "media-buttons" ]
                [ Html.div [ class "media-status" ]
                    [ Html.div [ class "dropdown" ]
                        [ Html.div [ class "dropbtn-existing-status" ]
                            [ Html.text ("your status: " ++ Movie.maybeStatusAsString movie.status ++ " >>") ]
                        , viewDropdownContent (MovieType movie) "to watch" "watching" "watched" "abandon"
                        ]
                    ]
                , Html.div [ class "media-status" ]
                    [ Html.div [ class "friend-media-existing-status-not-btn" ] [ Html.text ("friend's status: " ++ Movie.maybeStatusAsString (Just otherUserStatus)) ]
                    ]
                ]

        TVType tv ->
            Html.div [ class "media-buttons" ]
                [ Html.div [ class "media-status" ]
                    [ Html.div [ class "dropdown" ]
                        [ Html.div [ class "dropbtn-existing-status" ]
                            [ Html.text ("your status: " ++ TV.maybeStatusAsString tv.status ++ " >>") ]
                        , viewDropdownContent (TVType tv) "to watch" "watching" "watched" "abandon"
                        ]
                    ]
                , Html.div [ class "media-status" ]
                    [ Html.div [ class "friend-media-existing-status-not-btn" ] [ Html.text ("friend's status: " ++ TV.maybeStatusAsString (Just otherUserStatus)) ]
                    ]
                ]


viewDropdownContent : MediaType -> String -> String -> String -> String -> Html Msg
viewDropdownContent mediaType wantToConsume consuming finished abandoned =
    Html.div [ class "dropdown-content" ]
        [ Html.p [ Html.Events.onClick (AddMediaToProfile mediaType WantToConsume) ] [ Html.text wantToConsume ]
        , Html.p [ Html.Events.onClick (AddMediaToProfile mediaType Consuming) ] [ Html.text consuming ]
        , Html.p [ Html.Events.onClick (AddMediaToProfile mediaType Finished) ] [ Html.text finished ]
        , Html.p [ Html.Events.onClick (AddMediaToProfile mediaType Abandoned) ] [ Html.text abandoned ]
        ]


viewFriendsToRecommendDropdown : Profile -> MediaType -> WebData (List UserInfo) -> Html Msg
viewFriendsToRecommendDropdown profileType mediaType userFriends =
    case userFriends of
        NotAsked ->
            Html.text ""

        Loading ->
            Html.text "finding your friends"

        Failure error ->
            -- TODO show better error!
            Html.text "something went wrong"

        Success friends ->
            case profileType of
                LoggedInUserProfile ->
                    if List.isEmpty friends then
                        Html.div [ class "dropdown" ] <|
                            [ Html.button [ class "dropbtn" ] [ Html.text "recommend >>" ]
                            , Html.div [ class "dropdown-content" ]
                                --TODO: make this onClick Event
                                [ Html.a [ Attr.href "/search/users" ] [ Html.text "find friends to recommend!" ] ]
                            ]

                    else
                        Html.div [ class "dropdown" ] <|
                            [ Html.button [ class "dropbtn" ] [ Html.text "recommend >>" ]
                            , Html.div [ class "dropdown-content" ]
                                (List.map (viewFriendFullName mediaType) (List.sortBy .fullName friends))
                            ]

                _ ->
                    Html.div [] []


viewFriendFullName : MediaType -> UserInfo -> Html Msg
viewFriendFullName mediaType friend =
    Html.p [ Html.Events.onClick (Recommend mediaType friend) ] [ Html.text friend.fullName ]


viewMediaCover : Maybe String -> Html Msg
viewMediaCover maybeCoverUrl =
    case maybeCoverUrl of
        Just srcUrl ->
            Html.img
                [ Attr.src srcUrl ]
                []

        Nothing ->
            Html.div [ class "no-media" ] []


viewRecommendations : WebData (List RecommendationType) -> Html Msg
viewRecommendations recommendedMedia =
    case recommendedMedia of
        NotAsked ->
            Html.div [ class "page-text" ] [ Html.text "see your recommendations" ]

        Loading ->
            Html.div [ class "page-text" ] [ Html.text "entering the database!" ]

        Failure error ->
            -- TODO show better error!
            Html.div [ class "page-text" ] [ Html.text "something went wrong" ]

        Success rec ->
            if List.isEmpty rec then
                Html.div [ class "page-text" ] [ Html.text "no recommendations..." ]

            else
                Html.ul [ class "book-list" ]
                    (List.map viewRecommendedMedia rec)


viewRecommendedMedia : RecommendationType -> Html Msg
viewRecommendedMedia recommendationType =
    viewRecommendationType recommendationType


viewRecommendationType : RecommendationType -> Html Msg
viewRecommendationType recommendationType =
    case recommendationType of
        RecToUserType recommendedMedia ->
            case recommendedMedia.media of
                BookType book ->
                    Html.li []
                        [ Html.div [ class "media-card", class "media-card-long" ]
                            [ Html.div [ class "media-image" ] [ viewMediaCover book.coverUrl ]
                            , Html.div [ class "media-info" ]
                                [ Html.i [] [ Html.text (recommendedMedia.recommenderFullName ++ " recommends...") ]
                                , viewBookDetails book
                                , viewRecommendedMediaDropdown (BookType book)
                                ]
                            ]
                        ]

                MovieType movie ->
                    Html.li []
                        [ Html.div [ class "media-card", class "media-card-long" ]
                            [ Html.div [ class "media-image" ] [ viewMediaCover movie.posterUrl ]
                            , Html.div [ class "media-info" ]
                                [ Html.i [] [ Html.text (recommendedMedia.recommenderFullName ++ " recommends...") ]
                                , viewMovieDetails movie
                                , viewRecommendedMediaDropdown (MovieType movie)
                                ]
                            ]
                        ]

                TVType tv ->
                    Html.li []
                        [ Html.div [ class "media-card", class "media-card-long" ]
                            [ Html.div [ class "media-image" ] [ viewMediaCover tv.posterUrl ]
                            , Html.div [ class "media-info" ]
                                [ Html.i [] [ Html.text (recommendedMedia.recommenderFullName ++ " recommends...") ]
                                , viewTVDetails tv
                                , viewRecommendedMediaDropdown (TVType tv)
                                ]
                            ]
                        ]

        RecByUserType recommendedMedia ->
            case recommendedMedia.media of
                BookType book ->
                    Html.li []
                        [ Html.div [ class "media-card" ]
                            [ Html.div [ class "media-image" ] [ viewMediaCover book.coverUrl ]
                            , Html.div [ class "media-info" ]
                                [ Html.i []
                                    [ Html.text ("I recommended to " ++ recommendedMedia.recommendedFullName ++ "...") ]
                                , viewBookDetails book
                                ]
                            ]
                        ]

                MovieType movie ->
                    Html.li []
                        [ Html.div [ class "media-card" ]
                            [ Html.div [ class "media-image" ] [ viewMediaCover movie.posterUrl ]
                            , Html.div [ class "media-info" ]
                                [ Html.i [] [ Html.text ("I recommended to " ++ recommendedMedia.recommendedFullName ++ "...") ]
                                , viewMovieDetails movie
                                ]
                            ]
                        ]

                TVType tv ->
                    Html.li []
                        [ Html.div [ class "media-card" ]
                            [ Html.div [ class "media-image" ] [ viewMediaCover tv.posterUrl ]
                            , Html.div [ class "media-info" ]
                                [ Html.i [] [ Html.text ("I recommended to " ++ recommendedMedia.recommendedFullName ++ "...") ]
                                , viewTVDetails tv
                                ]
                            ]
                        ]


viewRecommendedMediaDropdown : MediaType -> Html Msg
viewRecommendedMediaDropdown mediaType =
    Html.div [ class "dropdown" ] <|
        case mediaType of
            BookType book ->
                case book.status of
                    Nothing ->
                        [ Html.button [ class "dropbtn" ] [ Html.text "Add Book >>" ]
                        , viewDropdownContent (BookType book) "to read" "reading" "read" "abandon"
                        ]

                    Just status ->
                        [ Html.text (Book.statusAsString status) ]

            MovieType movie ->
                case movie.status of
                    Nothing ->
                        [ Html.button [ class "dropbtn" ] [ Html.text "Add Movie >>" ]
                        , viewDropdownContent (MovieType movie) "to watch" "watching" "watched" "abandon"
                        ]

                    Just status ->
                        [ Html.text (Movie.statusAsString status) ]

            TVType tv ->
                case tv.status of
                    Nothing ->
                        [ Html.button [ class "dropbtn" ] [ Html.text "Add TV Show >>" ]
                        , viewDropdownContent (TVType tv) "to watch" "watching" "watched" "abandon"
                        ]

                    Just status ->
                        [ Html.text (TV.statusAsString status) ]



-- TABS
-- cascading tabs


type FirstTabSelection
    = MediaTab
    | RecommendationTab
    | FriendsTab
    | OverlapTab
    | NoFirstTab


type MediaTabSelection
    = BookTab
    | MovieTab
    | TVTab
    | NoSelectedMediaTab
    | NoMediaTab


type ConsumptionTabSelection
    = AllTab
    | WantToConsumeTab
    | ConsumingTab
    | FinishedTab
    | NoConsumptionTab


type RecommendationTabSelection
    = ToUserTab
    | FromUserTab
    | NoSelectedRecommendationTab
    | NoRecommendationTab


type FriendshipTabSelection
    = RequestedFriendsTab
    | ExistingFriendsTab
    | NoFriendshipTab


mediaTabSelectionToString : MediaTabSelection -> String
mediaTabSelectionToString mediaTab =
    case mediaTab of
        BookTab ->
            "book"

        MovieTab ->
            "movie"

        TVTab ->
            "tv"

        _ ->
            "that is not a valid media tab"


consumptionTabSelectionToString : MediaTabSelection -> ConsumptionTabSelection -> String
consumptionTabSelectionToString mediaTab consumptionTab =
    case mediaTab of
        BookTab ->
            case consumptionTab of
                AllTab ->
                    "all"

                WantToConsumeTab ->
                    "want to read"

                ConsumingTab ->
                    "reading"

                FinishedTab ->
                    "read"

                _ ->
                    ""

        NoMediaTab ->
            "something went wrong"

        _ ->
            case consumptionTab of
                AllTab ->
                    "all"

                WantToConsumeTab ->
                    "want to watch"

                ConsumingTab ->
                    "watching"

                FinishedTab ->
                    "watched"

                _ ->
                    ""


createFirstTab : Model -> FirstTabSelection -> String -> Html Msg
createFirstTab model firstTabSelection tabString =
    if model.firstSelectedTab == firstTabSelection then
        createFirstTabWithActiveState firstTabSelection "tablinks active" tabString

    else
        createFirstTabWithActiveState firstTabSelection "tablinks" tabString


createFirstTabWithActiveState : FirstTabSelection -> String -> String -> Html Msg
createFirstTabWithActiveState firstTabSelection activeState tabString =
    case firstTabSelection of
        MediaTab ->
            Html.button
                [ class activeState, Html.Events.onClick (AddMediaTabRow MediaTab) ]
                [ Html.text tabString ]

        OverlapTab ->
            Html.button
                [ class activeState, Html.Events.onClick (AddMediaTabRow OverlapTab) ]
                [ Html.text tabString ]

        RecommendationTab ->
            Html.button
                [ class activeState, Html.Events.onClick AddRecommendationTabRow ]
                [ Html.text tabString ]

        FriendsTab ->
            Html.button
                [ class activeState, Html.Events.onClick (SearchFriendsBasedOnTab ExistingFriendsTab) ]
                [ Html.text tabString ]

        _ ->
            Html.button [ class activeState ] [ Html.text tabString ]


createMediaTab : Model -> MediaTabSelection -> String -> Html Msg
createMediaTab model mediaTabSelection tabString =
    if model.mediaSelectedTab == mediaTabSelection then
        Html.button
            [ class "tablinks active", Html.Events.onClick (SearchBasedOnMediaTab mediaTabSelection) ]
            [ Html.text tabString ]

    else
        Html.button
            [ class "tablinks", Html.Events.onClick (SearchBasedOnMediaTab mediaTabSelection) ]
            [ Html.text tabString ]


createConsumptionTab : Model -> ConsumptionTabSelection -> String -> Html Msg
createConsumptionTab model consumptionTabSelection tabString =
    if model.consumptionSelectedTab == consumptionTabSelection then
        Html.button
            [ class "tablinks active", Html.Events.onClick (FilterBasedOnConsumptionTab consumptionTabSelection) ]
            [ Html.text tabString ]

    else
        Html.button
            [ class "tablinks", Html.Events.onClick (FilterBasedOnConsumptionTab consumptionTabSelection) ]
            [ Html.text tabString ]


createRecommendationTab : Model -> RecommendationTabSelection -> String -> Html Msg
createRecommendationTab model recommendationTabSelection tabString =
    if model.recommendationSelectedTab == recommendationTabSelection then
        Html.button
            [ class "tablinks active", Html.Events.onClick (AddRecommendationMediaTabRow recommendationTabSelection) ]
            [ Html.text tabString ]

    else
        Html.button
            [ class "tablinks", Html.Events.onClick (AddRecommendationMediaTabRow recommendationTabSelection) ]
            [ Html.text tabString ]


createFriendshipTab : Model -> FriendshipTabSelection -> String -> Html Msg
createFriendshipTab model friendshipTabSelection tabString =
    if model.friendshipSelectedTab == friendshipTabSelection then
        Html.button
            [ class "tablinks active", Html.Events.onClick (SearchFriendsBasedOnTab friendshipTabSelection) ]
            [ Html.text tabString ]

    else
        Html.button
            [ class "tablinks", Html.Events.onClick (SearchFriendsBasedOnTab friendshipTabSelection) ]
            [ Html.text tabString ]


resultMatchesStatus : ConsumptionTabSelection -> MediaType -> Bool
resultMatchesStatus consumptionTabSelection media =
    case Media.getMediaStatus media of
        Just status ->
            case consumptionTabSelection of
                AllTab ->
                    True

                WantToConsumeTab ->
                    status == Consumption.WantToConsume

                ConsumingTab ->
                    status == Consumption.Consuming

                FinishedTab ->
                    status == Consumption.Finished

                _ ->
                    False

        Nothing ->
            False


overlapResultMatchesStatus : ConsumptionTabSelection -> OverlapMedia -> Bool
overlapResultMatchesStatus consumptionTabSelection overlapMedia =
    case Media.getMediaStatus overlapMedia.media of
        Just primaryUserStatus ->
            case consumptionTabSelection of
                AllTab ->
                    True

                WantToConsumeTab ->
                    (primaryUserStatus == overlapMedia.otherUserStatus) && (primaryUserStatus == Consumption.WantToConsume)

                ConsumingTab ->
                    (primaryUserStatus == overlapMedia.otherUserStatus) && (primaryUserStatus == Consumption.Consuming)

                FinishedTab ->
                    (primaryUserStatus == overlapMedia.otherUserStatus) && (primaryUserStatus == Consumption.Finished)

                _ ->
                    False

        Nothing ->
            False
