module Media exposing (..)

import Book exposing (Book)
import Consumption exposing (Status)
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
bookToMediaDecoder maybeBook =
    Decode.map BookType maybeBook


movieToMediaDecoder : Decoder Movie -> Decoder MediaType
movieToMediaDecoder maybeMovie =
    Decode.map MovieType maybeMovie


tvToMediaDecoder : Decoder TV -> Decoder MediaType
tvToMediaDecoder maybeTV =
    Decode.map TVType maybeTV


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


getSourceId : MediaType -> String
getSourceId mediaType =
    case mediaType of
        BookType book ->
            book.sourceId

        MovieType movie ->
            movie.sourceId

        TVType tv ->
            tv.sourceId
