module Main exposing (..)

import Book exposing (Book)
import Browser
import Html exposing (Attribute, Html)
import Html.Attributes as Attr exposing (class, id, placeholder)
import Html.Events
import Http
import Json.Decode as Decode exposing (Decoder)
import List.Extra
import Media exposing (Consumption, Status(..))
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
    | AddBookToProfile Book Media.Status
    | BookAddedToProfile (Result Http.Error Consumption)


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

        AddBookToProfile book status ->
            let
                bookUpdater =
                    List.Extra.updateIf
                        (\b -> b == book)
                        (\b -> { b | status = Loading })

                newBooks =
                    RemoteData.map bookUpdater model.books
            in
            ( { model | books = newBooks }, addBookToProfile book status )

        BookAddedToProfile result ->
            case result of
                Ok consumption ->
                    let
                        bookUpdater =
                            List.Extra.updateIf
                                (\b -> b.sourceId == consumption.sourceId)
                                (\b -> { b | status = Success consumption.status })

                        newBooks =
                            RemoteData.map bookUpdater model.books
                    in
                    ( { model | books = newBooks }
                    , Cmd.none
                    )

                Err httpError ->
                    -- TODO handle error!
                    ( model, Cmd.none )

        None ->
            ( model, Cmd.none )


searchBooks : String -> Cmd Msg
searchBooks titleString =
    Http.get
        { url = "http://localhost:5000/books?title=" ++ titleString
        , expect = Http.expectJson BooksResponse (Decode.list Book.decoder)
        }


addBookToProfile : Book -> Media.Status -> Cmd Msg
addBookToProfile book status =
    Http.post
        { url = "http://localhost:5000/user/" ++ String.fromInt 1 ++ "/media/book"
        , body = Http.jsonBody (Book.encoderWithStatus book status)
        , expect = Http.expectJson BookAddedToProfile Media.consumptionDecoder
        }



-- View


view : Model -> Html Msg
view model =
    Html.div [ class "container", id "page-container" ]
        [ header model
        , body model
        , Html.footer [ id "footer" ] [ footer model ]
        ]


header : Model -> Html Msg
header model =
    Html.header [ class "header" ]
        [ Html.h1 [] [ Html.text "good times" ]
        , Html.p [] [ Html.text "a book, movie & tv finder - for having a good time" ]
        ]


footer : Model -> Html Msg
footer model =
    Html.p []
        [ Html.text "made by "
        , Html.a [ class "footer-url", Attr.href "https://zoestatmanweil.com" ] [ Html.text "zboknows" ]
        , Html.text " and "
        , Html.a [ class "footer-url", Attr.href "https://aaronstrick.com" ] [ Html.text "strickinato" ]
        , Html.text " - powered by google books api and tmdb"
        ]


body : Model -> Html Msg
body model =
    Html.main_ [ class "content" ]
        [ Html.div [ id "content-wrap" ]
            [ Html.form
                [ class "book-searcher"
                , onSubmit SearchBooks
                ]
                [ Html.input
                    [ placeholder "book title or author"
                    , Attr.value model.query
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
                    , Html.text (String.join ", " book.authorNames)
                    ]
                , case book.publishYear of
                    Just year ->
                        Html.text <| "(" ++ String.fromInt year ++ ")"

                    Nothing ->
                        Html.text ""
                , viewBookDropdown book
                ]
            ]
        ]


viewBookDropdown : Book -> Html Msg
viewBookDropdown book =
    Html.div [ class "dropdown" ] <|
        case book.status of
            NotAsked ->
                [ Html.button [ class "dropbtn" ] [ Html.text "Add Book >>" ]
                , Html.div [ class "dropdown-content" ]
                    [ Html.p [ Html.Events.onClick (AddBookToProfile book WantToConsume) ] [ Html.text "to read" ]
                    , Html.p [ Html.Events.onClick (AddBookToProfile book Consuming) ] [ Html.text "reading" ]
                    , Html.p [ Html.Events.onClick (AddBookToProfile book Finished) ] [ Html.text "read" ]
                    ]
                ]

            Loading ->
                [ Html.text "..." ]

            Failure _ ->
                [ Html.text "Something went wrong" ]

            Success status ->
                [ Html.text (Book.statusAsString status) ]


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


isJust : Maybe a -> Bool
isJust maybe =
    case maybe of
        Just _ ->
            True

        Nothing ->
            False
