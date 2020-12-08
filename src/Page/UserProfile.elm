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
import Recommendation exposing (RecommendedMedia)
import RemoteData exposing (RemoteData(..), WebData)
import Skeleton
import TV
import User



-- MODEL


type alias Model =
    { user : WebData User.User
    , friends : WebData (List User.User)
    , searchResults : WebData (List MediaType)
    , recommendedResults : WebData (List RecommendedMedia)
    , selectedTab : TabSelection
    }


type Msg
    = None
    | SearchBasedOnTab TabSelection
    | MediaResponse (Result Http.Error (List MediaType))
    | UserResponse (Result Http.Error User.User)
    | FriendResponse (Result Http.Error (List User.User))
    | AddMediaToProfile MediaType Consumption.Status
    | MediaAddedToProfile (Result Http.Error Consumption)
    | Recommend MediaType User.User
    | RecommendationResponse (Result Http.Error Recommendation.Recommendation)
    | RecommendedMediaResponse (Result Http.Error (List RecommendedMedia))


type TabSelection
    = BookTab
    | MovieTab
    | TVTab
    | RecommendationTab
    | FriendsTab
    | NoTab


init : Int -> ( Model, Cmd Msg )
init userID =
    ( { user = NotAsked
      , friends = NotAsked
      , searchResults = NotAsked
      , recommendedResults = NotAsked
      , selectedTab = NoTab
      }
    , getUser userID
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SearchBasedOnTab tabSelection ->
            case tabSelection of
                BookTab ->
                    ( { model | selectedTab = BookTab }, searchUserBooks model.user )

                MovieTab ->
                    ( { model | selectedTab = MovieTab }, searchUserMovies model.user )

                TVTab ->
                    ( { model | selectedTab = TVTab }, searchUserTV model.user )

                RecommendationTab ->
                    ( { model | selectedTab = RecommendationTab }, getRecommendedMedia model.user )

                _ ->
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
                    ( { model | user = Success user }, getFriends user.id )

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

        AddMediaToProfile mediaType status ->
            ( model, addMediaToProfile mediaType status model.user )

        MediaAddedToProfile result ->
            case result of
                Ok consumption ->
                    case model.selectedTab of
                        BookTab ->
                            ( model, searchUserBooks model.user )

                        MovieTab ->
                            ( model, searchUserMovies model.user )

                        TVTab ->
                            ( model, searchUserTV model.user )

                        RecommendationTab ->
                            ( model, getRecommendedMedia model.user )

                        _ ->
                            ( model, Cmd.none )

                Err httpError ->
                    -- TODO handle error!
                    ( model, Cmd.none )

        Recommend mediaType friend ->
            ( model, recommendMedia (User.getUserId model.user) friend.id mediaType Recommendation.Pending )

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


getFriends : Int -> Cmd Msg
getFriends userID =
    Http.get
        { url = "http://localhost:5000/user/" ++ String.fromInt userID ++ "/friends"
        , expect = Http.expectJson FriendResponse (Decode.list User.decoder)
        }


getRecommendedMedia : WebData User.User -> Cmd Msg
getRecommendedMedia user =
    Http.get
        { url = "http://localhost:5000/user/" ++ String.fromInt (User.getUserId user) ++ "/recommendations"
        , expect = Http.expectJson RecommendedMediaResponse (Decode.list Recommendation.mediaDecoder)
        }


recommendMedia : Int -> Int -> MediaType -> Recommendation.Status -> Cmd Msg
recommendMedia recommenderUserID recommendedUserID mediaType recommendation =
    Http.post
        { url = "http://localhost:5000/media/" ++ Media.getMediaTypeAsString mediaType ++ "/recommendation"
        , body = Http.jsonBody (Recommendation.encoder mediaType recommenderUserID recommendedUserID recommendation)
        , expect = Http.expectJson RecommendationResponse Recommendation.decoder
        }


addMediaToProfile : MediaType -> Consumption.Status -> WebData User.User -> Cmd Msg
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
    Html.main_ [ class "content" ]
        [ Html.div [ id "content-wrap" ]
            [ Html.div [ id "user-profile" ] [ Html.text ("Welcome " ++ User.getUsername model.user ++ "!") ]
            , Html.div [ class "tab" ]
                [ createTab model BookTab "books"
                , createTab model MovieTab "movies"
                , createTab model TVTab "tv shows"
                , createTab model RecommendationTab "recommendations"
                ]
            , Html.div [ class "media-results" ]
                [ viewTabContent model ]
            ]
        ]


viewTabContent : Model -> Html Msg
viewTabContent model =
    case model.selectedTab of
        RecommendationTab ->
            viewRecommendations model.recommendedResults

        _ ->
            viewMedias model.searchResults model.friends


viewMedias : WebData (List MediaType) -> WebData (List User.User) -> Html Msg
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


viewMediaType : WebData (List User.User) -> MediaType -> Html Msg
viewMediaType friends mediaType =
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
                            [ viewMediaDropdown (BookType book)
                            , Html.div [ class "media-recommend" ] [ viewFriendsToRecommendDropdown (BookType book) friends ]
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
                            [ viewMediaDropdown (MovieType movie)
                            , Html.div [ class "media-recommend" ] [ viewFriendsToRecommendDropdown (MovieType movie) friends ]
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
                            [ viewMediaDropdown (TVType tv)
                            , Html.div [ class "media-recommend" ] [ viewFriendsToRecommendDropdown (TVType tv) friends ]
                            ]
                        ]
                    ]
                ]


viewMediaDropdown : MediaType -> Html Msg
viewMediaDropdown mediaType =
    Html.div [ class "dropdown" ] <|
        case mediaType of
            BookType book ->
                [ Html.button [ class "dropbtn-existing-status " ] [ Html.text (Book.maybeStatusAsString book.status) ]
                , viewDropdownContent (BookType book) "to read" "reading" "read"
                ]

            MovieType movie ->
                [ Html.button [ class "dropbtn-existing-status " ] [ Html.text (Movie.maybeStatusAsString movie.status) ]
                , viewDropdownContent (MovieType movie) "to watch" "watching" "watched"
                ]

            TVType tv ->
                [ Html.button [ class "dropbtn-existing-status " ] [ Html.text (TV.maybeStatusAsString tv.status) ]
                , viewDropdownContent (TVType tv) "to watch" "watching" "watched"
                ]


viewDropdownContent : MediaType -> String -> String -> String -> Html Msg
viewDropdownContent mediaType wantToConsume consuming finished =
    Html.div [ class "dropdown-content" ]
        [ Html.p [ Html.Events.onClick (AddMediaToProfile mediaType WantToConsume) ] [ Html.text wantToConsume ]
        , Html.p [ Html.Events.onClick (AddMediaToProfile mediaType Consuming) ] [ Html.text consuming ]
        , Html.p [ Html.Events.onClick (AddMediaToProfile mediaType Finished) ] [ Html.text finished ]
        ]


viewFriendsToRecommendDropdown : MediaType -> WebData (List User.User) -> Html Msg
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
            Html.div [ class "dropdown" ] <|
                [ Html.button [ class "dropbtn" ] [ Html.text "Recommend >>" ]
                , Html.div [ class "dropdown-content" ]
                    (List.map (viewFriendUsername mediaType) (List.sortBy .username friends))
                ]


viewFriendUsername : MediaType -> User.User -> Html Msg
viewFriendUsername mediaType friend =
    Html.p [ Html.Events.onClick (Recommend mediaType friend) ] [ Html.text friend.username ]


viewMediaCover : Maybe String -> Html Msg
viewMediaCover maybeCoverUrl =
    case maybeCoverUrl of
        Just srcUrl ->
            Html.img
                [ Attr.src srcUrl ]
                []

        Nothing ->
            Html.div [ class "no-media" ] []


viewRecommendations : WebData (List RecommendedMedia) -> Html Msg
viewRecommendations recommendedMedia =
    case recommendedMedia of
        NotAsked ->
            Html.text "see your recommendations"

        Loading ->
            Html.text "entering the database!"

        Failure error ->
            -- TODO show better error!
            Html.text "something went wrong"

        Success media ->
            if List.isEmpty media then
                Html.text "no recommendations..."

            else
                Html.ul [ class "book-list" ]
                    (List.map viewRecommendedMedia media)


viewRecommendedMedia : RecommendedMedia -> Html Msg
viewRecommendedMedia recommendedMedia =
    viewRecommendedMediaType recommendedMedia


viewRecommendedMediaType : RecommendedMedia -> Html Msg
viewRecommendedMediaType recommendedMedia =
    case recommendedMedia.media of
        BookType book ->
            Html.li []
                [ Html.div [ class "media-card", class "media-card-long" ]
                    [ Html.div [ class "media-image" ] [ viewMediaCover book.coverUrl ]
                    , Html.div [ class "media-info" ]
                        [ Html.i [] [ Html.text (recommendedMedia.recommenderUsername ++ " recommends...") ]
                        , Html.b [] [ Html.text book.title ]
                        , Html.div []
                            [ Html.text "by "
                            , Html.text (String.join ", " book.authorNames)
                            ]
                        , case book.publishYear of
                            Just year ->
                                Html.text <| "(" ++ String.fromInt year ++ ")"

                            Nothing ->
                                Html.text ""
                        , viewRecommendedMediaDropdown (BookType book)
                        ]
                    ]
                ]

        MovieType movie ->
            Html.li []
                [ Html.div [ class "media-card", class "media-card-long" ]
                    [ Html.div [ class "media-image" ] [ viewMediaCover movie.posterUrl ]
                    , Html.div [ class "media-info" ]
                        [ Html.i [] [ Html.text (recommendedMedia.recommenderUsername ++ " recommends...") ]
                        , Html.b [] [ Html.text movie.title ]
                        , Html.text <| "(" ++ movie.releaseDate ++ ")"
                        , viewRecommendedMediaDropdown (MovieType movie)
                        ]
                    ]
                ]

        TVType tv ->
            Html.li []
                [ Html.div [ class "media-card", class "media-card-long" ]
                    [ Html.div [ class "media-image" ] [ viewMediaCover tv.posterUrl ]
                    , Html.div [ class "media-info" ]
                        [ Html.i [] [ Html.text (recommendedMedia.recommenderUsername ++ " recommends...") ]
                        , Html.b [] [ Html.text tv.title ]
                        , Html.div [] [ Html.text (String.join ", " tv.networks) ]
                        , case tv.firstAirDate of
                            Just date ->
                                Html.text <| "(" ++ date ++ ")"

                            Nothing ->
                                Html.text ""
                        , viewRecommendedMediaDropdown (TVType tv)
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
                        , viewDropdownContent (BookType book) "to read" "reading" "read"
                        ]

                    Just status ->
                        [ Html.text (Book.statusAsString status) ]

            MovieType movie ->
                case movie.status of
                    Nothing ->
                        [ Html.button [ class "dropbtn" ] [ Html.text "Add Movie >>" ]
                        , viewDropdownContent (MovieType movie) "to watch" "watching" "watched"
                        ]

                    Just status ->
                        [ Html.text (Movie.statusAsString status) ]

            TVType tv ->
                case tv.status of
                    Nothing ->
                        [ Html.button [ class "dropbtn" ] [ Html.text "Add TV Show >>" ]
                        , viewDropdownContent (TVType tv) "to watch" "watching" "watched"
                        ]

                    Just status ->
                        [ Html.text (TV.statusAsString status) ]



-- TABS


createTab : Model -> TabSelection -> String -> Html Msg
createTab model tabSelection tabString =
    if model.selectedTab == tabSelection then
        Html.button [ class "tablinks active", Html.Events.onClick (SearchBasedOnTab tabSelection) ] [ Html.text tabString ]

    else
        Html.button [ class "tablinks", Html.Events.onClick (SearchBasedOnTab tabSelection) ] [ Html.text tabString ]
