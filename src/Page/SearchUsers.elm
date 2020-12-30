module Page.SearchUsers exposing (..)

import Html exposing (Attribute, Html)
import Html.Attributes as Attr exposing (class, id, placeholder)
import Html.Events
import Http
import Json.Decode as Decode
import RemoteData exposing (RemoteData(..), WebData)
import Skeleton
import User exposing (User)



-- MODEL


type alias Model =
    { searchResults : WebData (List User)
    , query : String
    }


type Msg
    = None
    | SearchUsers
    | UpdateQuery String
    | UserResponse (Result Http.Error (List User))


init : () -> ( Model, Cmd Msg )
init _ =
    ( { searchResults = NotAsked
      , query = ""
      }
    , Cmd.none
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SearchUsers ->
            ( model, searchUsers model.query )

        UpdateQuery newString ->
            ( { model | query = newString }, Cmd.none )

        UserResponse userResponse ->
            let
                foundUsers =
                    RemoteData.fromResult userResponse
            in
            ( { model | searchResults = foundUsers }, Cmd.none )

        None ->
            ( model, Cmd.none )


searchUsers : String -> Cmd Msg
searchUsers emailString =
    Http.get
        { url = "http://localhost:5000/users?email=" ++ emailString
        , expect = Http.expectJson UserResponse (Decode.list User.decoder)
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


viewUsers : WebData (List User) -> Html Msg
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
                Html.ul [ class "book-list" ]
                    (List.map viewUser users)


viewUser : User -> Html Msg
viewUser user =
    Html.li []
        [ Html.div [ class "user-card" ]
            [ Html.div [ class "user-info" ]
                [ Html.b [] [ Html.text (user.firstName ++ " " ++ user.lastName) ]
                , Html.text user.email
                ]
            ]
        ]



-- Helpers


{-| This has to do with the default behavior of forms
-}
onSubmit : msg -> Attribute msg
onSubmit msg =
    Html.Events.preventDefaultOn "submit"
        (Decode.map (\a -> ( a, True )) (Decode.succeed msg))
