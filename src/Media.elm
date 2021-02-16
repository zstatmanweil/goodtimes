module Media exposing (..)

import Book exposing (Book)
import Consumption exposing (Status(..))
import Html exposing (Html)
import Html.Attributes as Attr exposing (class)
import Json.Decode as Decode exposing (Decoder)
import Movie exposing (Movie)
import TV exposing (TV)


type MediaSelection
    = BookSelection
    | TVSelection
    | MovieSelection
    | NoSelection


type MediaType
    = BookType Book
    | TVType TV
    | MovieType Movie


bookToMediaDecoder : Decoder Book -> Decoder MediaType
bookToMediaDecoder book =
    Decode.map BookType book


movieToMediaDecoder : Decoder Movie -> Decoder MediaType
movieToMediaDecoder movie =
    Decode.map MovieType movie


tvToMediaDecoder : Decoder TV -> Decoder MediaType
tvToMediaDecoder tv =
    Decode.map TVType tv


unknownMediaDecoder : Decoder MediaType
unknownMediaDecoder =
    Decode.oneOf
        [ bookToMediaDecoder Book.decoder
        , movieToMediaDecoder Movie.decoder
        , tvToMediaDecoder TV.decoder
        ]


setMediaStatus : Consumption.Status -> MediaType -> MediaType
setMediaStatus status mediaType =
    case mediaType of
        BookType book ->
            BookType { book | status = Just status }

        MovieType movie ->
            MovieType { movie | status = Just status }

        TVType tv ->
            TVType { tv | status = Just status }


getMediaStatus : MediaType -> Maybe Consumption.Status
getMediaStatus mediaType =
    case mediaType of
        BookType book ->
            book.status

        MovieType movie ->
            movie.status

        TVType tv ->
            tv.status


getMediaSourceId : MediaType -> String
getMediaSourceId mediaType =
    case mediaType of
        BookType book ->
            book.sourceId

        MovieType movie ->
            movie.sourceId

        TVType tv ->
            tv.sourceId


getSourceId : MediaType -> String
getSourceId mediaType =
    case mediaType of
        BookType book ->
            book.sourceId

        MovieType movie ->
            movie.sourceId

        TVType tv ->
            tv.sourceId


getTitle : MediaType -> String
getTitle mediaType =
    case mediaType of
        BookType book ->
            book.title

        MovieType movie ->
            movie.title

        TVType tv ->
            tv.title


getMediaTypeAsString : MediaType -> String
getMediaTypeAsString mediaType =
    case mediaType of
        BookType _ ->
            "book"

        MovieType _ ->
            "movie"

        TVType _ ->
            "tv"


getMediaCover : MediaType -> Maybe String
getMediaCover mediaType =
    case mediaType of
        BookType book ->
            book.coverUrl

        MovieType movie ->
            movie.posterUrl

        TVType tv ->
            tv.posterUrl



-- SHARED VIEW FUNCTIONS


viewMediaCover : MediaType -> Html msg
viewMediaCover mediaType =
    case getMediaCover mediaType of
        Just srcUrl ->
            Html.img
                [ Attr.src srcUrl ]
                []

        Nothing ->
            Html.div [ class "no-media" ] []


type Person
    = Second
    | Third


conjugate : Person -> Status -> MediaType -> String
conjugate person status mediaType =
    case ( mediaType, status, person ) of
        ( BookType _, WantToConsume, Second ) ->
            "want to read"

        ( BookType _, WantToConsume, Third ) ->
            "wants to read"

        ( BookType _, Consuming, Second ) ->
            "are reading"

        ( BookType _, Consuming, Third ) ->
            "is reading"

        ( BookType _, Finished, _ ) ->
            "read"

        ( _, WantToConsume, Second ) ->
            "want to watch"

        ( _, WantToConsume, Third ) ->
            "wants to watch"

        ( _, Consuming, Second ) ->
            "are watching "

        ( _, Consuming, Third ) ->
            "is watching "

        ( _, Finished, _ ) ->
            "watched"

        ( _, Abandoned, _ ) ->
            "abandoned"
