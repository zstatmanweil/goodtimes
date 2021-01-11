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
import Recommendation exposing (RecommendationType(..), RecommendedByUserMedia, RecommendedToUserMedia, recByUserToRecTypeDecoder, recToUserToRecTypeDecoder, recommendedByUserMediaDecoder, recommendedToUserMediaDecoder)
import RemoteData exposing (RemoteData(..), WebData)
import Skeleton
import TV exposing (TV)
import User exposing (FriendLink, FriendStatus(..), UserInfo, friendLinkDecoder, friendLinkEncoder, getUserFullName, getUserId, userInfoDecoder)



-- MODEL


type alias Model =
    { logged_in_user : WebData UserInfo
    , profile_user : WebData UserInfo
    , friends : WebData (List UserInfo)
    , searchResults : WebData (List MediaType)
    , filteredMediaResults : WebData (List MediaType)
    , recommendedResults : WebData (List RecommendationType)
    , firstSelectedTab : FirstTabSelection
    , mediaSelectedTab : MediaTabSelection
    , consumptionSelectedTab : ConsumptionTabSelection
    , recommendationSelectedTab : RecommendationTabSelection
    , friendshipSelectedTab : FriendshipTabSelection
    }


type Msg
    = None
    | AddMediaTabRow
    | SearchBasedOnMediaTab MediaTabSelection
    | FilterBasedOnConsumptionTab ConsumptionTabSelection
    | AddMediaToProfile MediaType Consumption.Status
    | MediaAddedToProfile (Result Http.Error Consumption)
    | MediaResponse (Result Http.Error (List MediaType))
    | SearchFriendsBasedOnTab FriendshipTabSelection
    | UserResponse (Result Http.Error UserInfo)
    | FriendResponse (Result Http.Error (List UserInfo))
    | AddFriendLink UserInfo FriendStatus
    | FriendLinkAdded (Result Http.Error FriendLink)
    | AddRecommendationTabRow
    | AddRecommendationMediaTabRow RecommendationTabSelection
    | Recommend MediaType UserInfo
    | RecommendationResponse (Result Http.Error Recommendation.Recommendation)
    | RecommendedMediaResponse (Result Http.Error (List RecommendationType))


init : Int -> ( Model, Cmd Msg )
init userID =
    ( { logged_in_user = Success (UserInfo 1 "123" "zoe" "statman-weil" "zoe statman-weil " "zstatmanweil@gmail.com" "mypicture")
      , profile_user = NotAsked
      , friends = NotAsked
      , searchResults = NotAsked
      , filteredMediaResults = NotAsked
      , recommendedResults = NotAsked
      , firstSelectedTab = NoFirstTab
      , mediaSelectedTab = NoMediaTab
      , consumptionSelectedTab = NoConsumptionTab
      , recommendationSelectedTab = NoRecommendationTab
      , friendshipSelectedTab = NoFriendshipTab
      }
    , getUser userID
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AddMediaTabRow ->
            ( { model
                | filteredMediaResults = NotAsked
                , firstSelectedTab = MediaTab
                , mediaSelectedTab = NoSelectedMediaTab
                , friendshipSelectedTab = NoFriendshipTab
                , recommendationSelectedTab = NoRecommendationTab
              }
            , Cmd.none
            )

        SearchBasedOnMediaTab mediaTabSelection ->
            case model.firstSelectedTab of
                MediaTab ->
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
                            , searchUserBooks model.logged_in_user
                            )

                        MovieTab ->
                            ( new_model
                            , searchUserMovies model.logged_in_user
                            )

                        TVTab ->
                            ( new_model
                            , searchUserTV model.logged_in_user
                            )

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
                            , getRecommendedToUserMedia model.logged_in_user (mediaTabSelectionToString mediaTabSelection)
                            )

                        FromUserTab ->
                            ( new_model
                            , getRecommendedByUserMedia model.logged_in_user (mediaTabSelectionToString mediaTabSelection)
                            )

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        FilterBasedOnConsumptionTab consumptionTab ->
            let
                filteredMedia =
                    RemoteData.map (List.filter (resultMatchesStatus consumptionTab)) model.searchResults
            in
            ( { model
                | filteredMediaResults = filteredMedia
                , consumptionSelectedTab = consumptionTab
              }
            , Cmd.none
            )

        AddMediaToProfile mediaType status ->
            ( model, addMediaToProfile mediaType status model.logged_in_user )

        MediaAddedToProfile result ->
            case result of
                Ok consumption ->
                    case model.mediaSelectedTab of
                        BookTab ->
                            ( model, searchUserBooks model.logged_in_user )

                        MovieTab ->
                            ( model, searchUserMovies model.logged_in_user )

                        TVTab ->
                            ( model, searchUserTV model.logged_in_user )

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
            let
                new_model =
                    { model
                        | firstSelectedTab = FriendsTab
                        , mediaSelectedTab = NoMediaTab
                        , consumptionSelectedTab = NoConsumptionTab
                        , recommendationSelectedTab = NoRecommendationTab
                        , friendshipSelectedTab = friendshipTab
                        , friends = Loading
                    }
            in
            case friendshipTab of
                ExistingFriendsTab ->
                    ( new_model
                    , getExistingFriends (User.getUserId model.logged_in_user)
                    )

                RequestedFriendsTab ->
                    ( new_model
                    , getFriendRequests (User.getUserId model.logged_in_user)
                    )

                _ ->
                    ( model, Cmd.none )

        UserResponse userResponse ->
            case userResponse of
                Ok user ->
                    if User.getUserId model.logged_in_user == user.goodTimesId then
                        ( { model | profile_user = Success user }, getExistingFriends user.goodTimesId )

                    else
                        -- TODO: command here should be something like get if profile user is friends with logged in user,
                        -- of if friendship has been requested
                        ( { model | profile_user = Success user }, Cmd.none )

                -- TODO: handle error
                Err resp ->
                    ( model, Cmd.none )

        FriendResponse friendResponse ->
            case friendResponse of
                Ok friends ->
                    ( { model | friends = Success friends }, Cmd.none )

                -- TODO: handle error
                Err resp ->
                    ( model, Cmd.none )

        AddFriendLink user friendStatus ->
            ( model, addFriendLink user (User.getUserId model.logged_in_user) friendStatus )

        FriendLinkAdded result ->
            case result of
                Ok friendLink ->
                    ( model, getFriendRequests (User.getUserId model.logged_in_user) )

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
            ( model, recommendMedia (User.getUserId model.logged_in_user) friend.goodTimesId mediaType Recommendation.Pending )

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

        None ->
            ( model, Cmd.none )


searchUserBooks : WebData UserInfo -> Cmd Msg
searchUserBooks user =
    Http.get
        { url = "http://localhost:5000/user/" ++ String.fromInt (User.getUserId user) ++ "/media/book"
        , expect = Http.expectJson MediaResponse (Decode.list (Media.bookToMediaDecoder Book.decoder))
        }


searchUserMovies : WebData UserInfo -> Cmd Msg
searchUserMovies user =
    Http.get
        { url = "http://localhost:5000/user/" ++ String.fromInt (User.getUserId user) ++ "/media/movie"
        , expect = Http.expectJson MediaResponse (Decode.list (Media.movieToMediaDecoder Movie.decoder))
        }


searchUserTV : WebData UserInfo -> Cmd Msg
searchUserTV user =
    Http.get
        { url = "http://localhost:5000/user/" ++ String.fromInt (User.getUserId user) ++ "/media/tv"
        , expect = Http.expectJson MediaResponse (Decode.list (Media.tvToMediaDecoder TV.decoder))
        }


getUser : Int -> Cmd Msg
getUser userID =
    Http.get
        { url = "http://localhost:5000/user/" ++ String.fromInt userID
        , expect = Http.expectJson UserResponse userInfoDecoder
        }


getExistingFriends : Int -> Cmd Msg
getExistingFriends userID =
    Http.get
        { url = "http://localhost:5000/user/" ++ String.fromInt userID ++ "/friends"
        , expect = Http.expectJson FriendResponse (Decode.list userInfoDecoder)
        }


getFriendRequests : Int -> Cmd Msg
getFriendRequests userID =
    Http.get
        { url = "http://localhost:5000/user/" ++ String.fromInt userID ++ "/requests"
        , expect = Http.expectJson FriendResponse (Decode.list userInfoDecoder)
        }


addFriendLink : UserInfo -> Int -> FriendStatus -> Cmd Msg
addFriendLink user currentUserId status =
    Http.post
        { url = "http://localhost:5000/friend"
        , body = Http.jsonBody (friendLinkEncoder user.goodTimesId currentUserId status)
        , expect = Http.expectJson FriendLinkAdded friendLinkDecoder
        }


getRecommendedToUserMedia : WebData UserInfo -> String -> Cmd Msg
getRecommendedToUserMedia user mediaType =
    Http.get
        { url = "http://localhost:5000/user/" ++ String.fromInt (User.getUserId user) ++ "/recommendations/" ++ mediaType
        , expect = Http.expectJson RecommendedMediaResponse (Decode.list (recToUserToRecTypeDecoder recommendedToUserMediaDecoder))
        }


getRecommendedByUserMedia : WebData UserInfo -> String -> Cmd Msg
getRecommendedByUserMedia user mediaType =
    Http.get
        { url = "http://localhost:5000/user/" ++ String.fromInt (User.getUserId user) ++ "/recommended/" ++ mediaType
        , expect = Http.expectJson RecommendedMediaResponse (Decode.list (recByUserToRecTypeDecoder recommendedByUserMediaDecoder))
        }


recommendMedia : Int -> Int -> MediaType -> Recommendation.Status -> Cmd Msg
recommendMedia recommenderUserID recommendedUserID mediaType recommendation =
    Http.post
        { url = "http://localhost:5000/media/" ++ Media.getMediaTypeAsString mediaType ++ "/recommendation"
        , body = Http.jsonBody (Recommendation.encoder mediaType recommenderUserID recommendedUserID recommendation)
        , expect = Http.expectJson RecommendationResponse Recommendation.decoder
        }


addMediaToProfile : MediaType -> Consumption.Status -> WebData UserInfo -> Cmd Msg
addMediaToProfile mediaType status user =
    case mediaType of
        BookType book ->
            Http.post
                { url = "http://localhost:5000/user/" ++ String.fromInt (User.getUserId user) ++ "/media/book"
                , body = Http.jsonBody (Book.encoderWithStatus book status)
                , expect = Http.expectJson MediaAddedToProfile Consumption.consumptionDecoder
                }

        MovieType movie ->
            Http.post
                { url = "http://localhost:5000/user/" ++ String.fromInt (User.getUserId user) ++ "/media/movie"
                , body = Http.jsonBody (Movie.encoderWithStatus movie status)
                , expect = Http.expectJson MediaAddedToProfile Consumption.consumptionDecoder
                }

        TVType tv ->
            Http.post
                { url = "http://localhost:5000/user/" ++ String.fromInt (User.getUserId user) ++ "/media/tv"
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
    if getUserId model.logged_in_user == getUserId model.profile_user then
        Html.main_ [ class "content" ]
            [ Html.div [ id "content-wrap" ]
                [ Html.div [ id "user-profile" ] [ Html.text ("welcome " ++ getUserFullName model.logged_in_user ++ "!") ]
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
                    [ viewTabContent model ]
                ]
            ]

    else
        Html.main_ [ class "content" ]
            [ Html.div [ id "content-wrap" ] [ Html.text "here is another user!" ] ]


viewTabContent : Model -> Html Msg
viewTabContent model =
    case model.firstSelectedTab of
        RecommendationTab ->
            viewRecommendations model.recommendedResults

        MediaTab ->
            viewMedias model.filteredMediaResults model.friends

        FriendsTab ->
            case model.friendshipSelectedTab of
                ExistingFriendsTab ->
                    viewFriends model.friends

                RequestedFriendsTab ->
                    viewFriendRequests model.friends

                _ ->
                    Html.text "something went wrong"

        _ ->
            Html.div [] [ Html.text "select a tab and start exploring!" ]


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
    if model.friendshipSelectedTab /= NoFriendshipTab then
        Html.div [ class "tab" ]
            [ createFriendshipTab model ExistingFriendsTab "existing"
            , createFriendshipTab model RequestedFriendsTab "requests"
            ]

    else
        Html.div [] []


viewFriends : WebData (List UserInfo) -> Html Msg
viewFriends friends =
    case friends of
        NotAsked ->
            Html.text "you want friends"

        Loading ->
            Html.text "looking for friends!"

        Failure error ->
            -- TODO show better error!
            Html.text "something went wrong"

        Success users ->
            if List.isEmpty users then
                Html.text "no friends..."

            else
                Html.ul []
                    (List.map viewFriend users)


viewFriend : UserInfo -> Html Msg
viewFriend user =
    Html.li []
        [ Html.div [ class "user-card" ]
            [ Html.div [ class "user-info" ]
                [ Html.b [] [ Html.text (user.firstName ++ " " ++ user.lastName) ]
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
            , Html.Events.onClick (AddFriendLink user Accepted)
            ]
            [ Html.text "Accept Friend >>" ]
        ]


viewMedias : WebData (List MediaType) -> WebData (List UserInfo) -> Html Msg
viewMedias receivedMedia friends =
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
                    (List.map (viewMediaType friends) (List.sortBy Media.getTitle media))


viewMediaType : WebData (List UserInfo) -> MediaType -> Html Msg
viewMediaType friends mediaType =
    case mediaType of
        BookType book ->
            Html.li []
                [ Html.div [ class "media-card" ]
                    [ Html.div [ class "media-image" ] [ viewMediaCover book.coverUrl ]
                    , Html.div [ class "media-info" ]
                        [ viewBookDetails book
                        , Html.div [ class "media-status" ]
                            [ viewMediaDropdown (BookType book)
                            , Html.div
                                [ class "media-recommend" ]
                                [ viewFriendsToRecommendDropdown (BookType book) friends ]
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
                        , Html.div [ class "media-status" ]
                            [ viewMediaDropdown (MovieType movie)
                            , Html.div [ class "media-recommend" ]
                                [ viewFriendsToRecommendDropdown (MovieType movie) friends ]
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
                        , Html.div [ class "media-status" ]
                            [ viewMediaDropdown (TVType tv)
                            , Html.div [ class "media-recommend" ]
                                [ viewFriendsToRecommendDropdown (TVType tv) friends ]
                            ]
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


viewMediaDropdown : MediaType -> Html Msg
viewMediaDropdown mediaType =
    Html.div [ class "dropdown" ] <|
        case mediaType of
            BookType book ->
                [ Html.button [ class "dropbtn-existing-status " ] [ Html.text (Book.maybeStatusAsString book.status) ]
                , viewDropdownContent (BookType book) "to read" "reading" "read" "abandon"
                ]

            MovieType movie ->
                [ Html.button [ class "dropbtn-existing-status " ] [ Html.text (Movie.maybeStatusAsString movie.status) ]
                , viewDropdownContent (MovieType movie) "to watch" "watching" "watched" "abandon"
                ]

            TVType tv ->
                [ Html.button [ class "dropbtn-existing-status " ] [ Html.text (TV.maybeStatusAsString tv.status) ]
                , viewDropdownContent (TVType tv) "to watch" "watching" "watched" "abandon"
                ]


viewDropdownContent : MediaType -> String -> String -> String -> String -> Html Msg
viewDropdownContent mediaType wantToConsume consuming finished abandoned =
    Html.div [ class "dropdown-content" ]
        [ Html.p [ Html.Events.onClick (AddMediaToProfile mediaType WantToConsume) ] [ Html.text wantToConsume ]
        , Html.p [ Html.Events.onClick (AddMediaToProfile mediaType Consuming) ] [ Html.text consuming ]
        , Html.p [ Html.Events.onClick (AddMediaToProfile mediaType Finished) ] [ Html.text finished ]
        , Html.p [ Html.Events.onClick (AddMediaToProfile mediaType Abandoned) ] [ Html.text abandoned ]
        ]


viewFriendsToRecommendDropdown : MediaType -> WebData (List UserInfo) -> Html Msg
viewFriendsToRecommendDropdown mediaType userFriends =
    case userFriends of
        NotAsked ->
            Html.text ""

        Loading ->
            Html.text "finding your friends"

        Failure error ->
            -- TODO show better error!
            Html.text "something went wrong"

        Success friends ->
            if List.isEmpty friends then
                Html.div [ class "dropdown" ] <|
                    [ Html.button [ class "dropbtn" ] [ Html.text "recommend >>" ]
                    , Html.div [ class "dropdown-content" ]
                        [ Html.a [ Attr.href "/search/users" ] [ Html.text "find friends to recommend!" ] ]
                    ]

            else
                Html.div [ class "dropdown" ] <|
                    [ Html.button [ class "dropbtn" ] [ Html.text "recommend >>" ]
                    , Html.div [ class "dropdown-content" ]
                        (List.map (viewFriendFullName mediaType) (List.sortBy .fullName friends))
                    ]


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
            Html.text "see your recommendations"

        Loading ->
            Html.text "entering the database!"

        Failure error ->
            -- TODO show better error!
            Html.text "something went wrong"

        Success rec ->
            if List.isEmpty rec then
                Html.text "no recommendations..."

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
                [ class activeState, Html.Events.onClick AddMediaTabRow ]
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
