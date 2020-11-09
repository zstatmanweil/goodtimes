module Main exposing (..)

import Browser
import Html exposing (Html)


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type Msg
    = None


init : () -> ( Int, Cmd Msg )
init flags =
    ( 0, Cmd.none )


view : Int -> Html Msg
view model =
    Html.text "HELLO!!"


update : Msg -> Int -> ( Int, Cmd Msg )
update msg model =
    ( 0, Cmd.none )


subscriptions : Int -> Sub Msg
subscriptions model =
    Sub.none
