module Main exposing (..)

import Browser
import Html exposing (Html)
import Html.Events
import Html.Attributes
import Http
import Json.Decode exposing (Decoder)


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }

type alias Model =
    { books : List Book
    , query : String
    }

type Msg
    = None
    | SearchBooks
    | UpdateQuery String
    | GotBooks (Result Http.Error (List Book))


type alias Book =
    { title : String }

init : () -> ( Model, Cmd Msg )
init flags =
    ( { books = [], query = "" }
    , Cmd.none
    )


view : Model -> Html Msg
view model =
    Html.div []
        [ Html.input
              [ Html.Attributes.id "our-input"
              , Html.Attributes.value model.query
              , Html.Events.onInput UpdateQuery
              ]
              []
        , Html.button
              [ Html.Events.onClick SearchBooks ]
              [ Html.text "Search!" ]
        , viewBooks model.books
        ]


viewBooks : List Book -> Html Msg
viewBooks books =
    if List.isEmpty books then
        Html.text "No books"
    else
        Html.ul []
            (List.map viewBook books)


viewBook : Book -> Html Msg
viewBook book =
    Html.li [] [ Html.text book.title ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SearchBooks ->
            (model, searchBooks model.query)

        GotBooks booksResult ->

            case booksResult of
                Ok booksList ->
                    ( { books = booksList
                      , query = ""
                      }
                    , Cmd.none )

                Err httpError ->
                    ( model, Cmd.none )
            
        UpdateQuery newString ->
            ( { model | query = newString }, Cmd.none )

        None ->
            ( model, Cmd.none )


searchBooks : String -> Cmd Msg
searchBooks titleString =
    Http.get
        { url = "http://localhost:5000/books?title=" ++ titleString
        , expect = bookExpectation
        }

bookExpectation : Http.Expect Msg
bookExpectation =
    Http.expectJson GotBooks booksDecoder


booksDecoder : Decoder (List Book)
booksDecoder =
    Json.Decode.list bookDecoder


bookDecoder : Decoder Book
bookDecoder =
    Json.Decode.field "title" Json.Decode.string
        |> Json.Decode.map Book

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
