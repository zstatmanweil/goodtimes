module Main exposing (..)

import Browser
import Html exposing (Html)
import Html.Attributes exposing (height, src, width)
import Html.Events
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


type alias Book =
    { title : String
    , authorName : Maybe String
    , publishYear : Maybe Int
    , coverUrl : Maybe String
    }


type Msg
    = None
    | SearchBooks
    | UpdateQuery String
    | GotBooks (Result Http.Error (List Book))


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
        Html.div [] [ Html.text "No books matched your search. Try again!" ]

    else
        Html.ul []
            (List.map viewBook books)


viewBook : Book -> Html Msg
viewBook book =
    Html.li []
        [ Html.div []
            [ Html.div [] [ Html.img [ src (Maybe.withDefault "http://covers.openlibrary.org/b/id/9405185-S.jpg" book.coverUrl) ] [] ]
            , Html.text book.title
            , Html.div [] [ Html.text (Maybe.withDefault "Unknown" book.authorName) ]
            , Html.div [] [ Html.text (String.fromInt (Maybe.withDefault 0 book.publishYear)) ]
            ]
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SearchBooks ->
            ( model, searchBooks model.query )

        GotBooks booksResult ->
            case booksResult of
                Ok booksList ->
                    ( { books = booksList
                      , query = ""
                      }
                    , Cmd.none
                    )

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
    Json.Decode.map4 Book
        (Json.Decode.field "title" Json.Decode.string)
        (Json.Decode.field "author_name" (Json.Decode.nullable Json.Decode.string))
        (Json.Decode.field "publish_year" (Json.Decode.nullable Json.Decode.int))
        (Json.Decode.field "cover_url" (Json.Decode.nullable Json.Decode.string))


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
