module Main exposing (..)

import Book exposing (Book)
import Browser
import Html exposing (Attribute, Html)
import Html.Attributes as Attr exposing (class, id)
import Html.Events
import Http
import Json.Decode as Decode exposing (Decoder)
import RemoteData exposing (RemoteData(..), WebData)


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- Model


type alias Model =
    { books : WebData (List Book)
    , query : String
    }


type Msg
    = None
    | SearchBooks
    | UpdateQuery String
    | BooksResponse (Result Http.Error (List Book))


init : () -> ( Model, Cmd Msg )
init flags =
    ( { books = NotAsked, query = "" }
    , Cmd.none
    )



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SearchBooks ->
            ( model, searchBooks model.query )

        BooksResponse booksResponse ->
            let
                receivedBooks =
                    RemoteData.fromResult booksResponse
            in
            ( { model | books = receivedBooks }, Cmd.none )

        UpdateQuery newString ->
            ( { model | query = newString }, Cmd.none )

        None ->
            ( model, Cmd.none )


searchBooks : String -> Cmd Msg
searchBooks titleString =
    Http.get
        { url = "http://localhost:5000/books?title=" ++ titleString
        , expect = Http.expectJson BooksResponse (Decode.list Book.decoder)
        }



-- View


view : Model -> Html Msg
view model =
    Html.div [ class "container" ]
        [ header model
        , body model
        ]


header : Model -> Html Msg
header model =
    Html.header [ class "header" ]
        [ Html.h1 [] [ Html.text "good times" ]
        , Html.p [] [ Html.text "a book finder - for having a good time" ]
        ]


body : Model -> Html Msg
body model =
    Html.main_ [ class "content" ]
        [ Html.form
            [ class "book-searcher"
            , onSubmit SearchBooks
            ]
            [ Html.input
                [ Attr.value model.query
                , Html.Events.onInput UpdateQuery
                ]
                []
            , Html.button
                [ Attr.disabled <| String.isEmpty model.query ]
                [ Html.text "Find a book!" ]
            ]
        , Html.div [ class "book-results" ]
            [ viewBooks model.books ]
        ]


viewBooks : WebData (List Book) -> Html Msg
viewBooks receivedBooks =
    case receivedBooks of
        NotAsked ->
            Html.text "go ahead, search for a book!"

        Loading ->
            Html.text "entering the book database!"

        Failure error ->
            -- TODO show better error!
            Html.text "something went wrong"

        Success books ->
            if List.isEmpty books then
                Html.text "no results..."

            else
                Html.ul [ class "book-list" ]
                    (List.map viewBook books)


viewBook : Book -> Html Msg
viewBook book =
    Html.li []
        [ Html.div [ class "media-card" ]
            [ Html.div [ class "media-image" ] [ viewBookCover book.coverUrl ]
            , Html.div [ class "media-info" ]
                [ Html.b [] [ Html.text book.title ]
                , Html.div []
                    [ Html.text "by "
                    , Html.text (Maybe.withDefault "Unknown" book.authorName)
                    ]
                , case book.publishYear of
                    Just year ->
                        Html.text <| "(" ++ String.fromInt year ++ ")"

                    Nothing ->
                        Html.text ""
                ]
            ]
        ]


viewBookCover : Maybe String -> Html Msg
viewBookCover maybeCoverUrl =
    case maybeCoverUrl of
        Just srcUrl ->
            Html.img
                [ Attr.src srcUrl ]
                []

        Nothing ->
            Html.div [ class "no-media" ] []


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- Helpers


{-| This has to do with the default behavior of forms
-}
onSubmit : msg -> Attribute msg
onSubmit msg =
    Html.Events.preventDefaultOn "submit"
        (Decode.map (\a -> ( a, True )) (Decode.succeed msg))
