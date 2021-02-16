module Skeleton exposing (..)

import Browser exposing (Document)
import GoodtimesAuth0 exposing (AuthStatus(..), auth0LoginUrl)
import Html exposing (Attribute, Html)
import Html.Attributes as Attr exposing (class, id)
import Html.Events



-- NODE
--TODO: switch to Config


type alias Details msg =
    { title : String
    , attrs : List (Attribute msg)
    , kids : List (Html msg)
    }



-- VIEW


type alias Msgs msg =
    { toggleViewMenu : msg
    , logOut : msg
    }


view : Bool -> AuthStatus -> Msgs msg -> (a -> msg) -> Details a -> Document msg
view menuOpen authStatus { toggleViewMenu, logOut } toMsg details =
    { title = details.title
    , body =
        [ Html.div [ class "container", id "page-container" ]
            [ header authStatus toggleViewMenu
            , sidebar authStatus logOut menuOpen
            , if GoodtimesAuth0.isMidAuthentication authStatus then
                -- Here's some fun options: https://projects.lukehaas.me/css-loaders/
                Html.text "loading..."

              else
                Html.map toMsg <|
                    Html.div (class "center" :: details.attrs) details.kids
            , Html.footer [ id "footer" ] [ footer ]
            ]
        ]
    }


header : AuthStatus -> msg -> Html msg
header authStatus toggleViewMenu =
    Html.header [ class "header" ]
        [ Html.div [ class "hamburger", Html.Events.onClick toggleViewMenu ] [ Html.div [ class "bar" ] [], Html.div [ class "bar" ] [], Html.div [ class "bar" ] [] ]
        , Html.h1 [] [ Html.a [ Attr.href (homeUrl authStatus) ] [ Html.text "good times" ] ]
        , Html.p [] [ Html.text "a book, movie & tv show finder - for having a good time" ]
        ]


homeUrl : AuthStatus -> String
homeUrl authStatus =
    case authStatus of
        Authenticated _ ->
            "/feed"

        _ ->
            "/about"


sidebar : AuthStatus -> msg -> Bool -> Html msg
sidebar authStatus logOut menuOpen =
    case menuOpen of
        True ->
            Html.div [ class "sidenav" ] <|
                case authStatus of
                    Authenticated loggedInUser ->
                        --TODO pas through UserInfo and if authenticated show below (with user id passed in) and if not authenticated just show log in and about good times
                        [ Html.a [ Attr.href ("/user/" ++ String.fromInt loggedInUser.userInfo.goodTimesId) ] [ Html.text "my profile" ]
                        , Html.a [ Attr.href "/search" ] [ Html.text "search media" ]
                        , Html.a [ Attr.href "/search/users" ] [ Html.text "find friends" ]
                        , Html.a [ Attr.href "/feed" ] [ Html.text "event feed" ]
                        , Html.a [ Attr.href "/about" ] [ Html.text "about goodtimes" ]
                        , Html.a [ Attr.href "/", Html.Events.onClick logOut ] [ Html.text "log out" ]
                        ]

                    _ ->
                        [ Html.a [ Attr.href "/about" ] [ Html.text "about goodtimes" ]
                        , Html.a [ Attr.href auth0LoginUrl ] [ Html.text "login" ]
                        ]

        False ->
            Html.text ""


footer : Html msg
footer =
    Html.p []
        [ Html.text "made by "
        , Html.a [ class "footer-url", Attr.href "https://zoestatmanweil.com" ] [ Html.text "zboknows" ]
        , Html.text " and "
        , Html.a [ class "footer-url", Attr.href "https://aaronstrick.com" ] [ Html.text "strickinato" ]
        , Html.text " - powered by google books api and tmdb"
        ]
