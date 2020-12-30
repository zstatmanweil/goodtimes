module Skeleton exposing (..)

import Browser exposing (Document)
import Html exposing (Attribute, Html)
import Html.Attributes as Attr exposing (class, id)



-- NODE
--TODO: switch to Config


type alias Details msg =
    { title : String
    , attrs : List (Attribute msg)
    , kids : List (Html msg)
    }



-- VIEW


view : (a -> msg) -> Details a -> Document msg
view toMsg details =
    { title = details.title
    , body =
        [ Html.div [ class "container", id "page-container" ]
            [ header
            , Html.map toMsg <|
                Html.div (class "center" :: details.attrs) details.kids
            , Html.footer [ id "footer" ] [ footer ]
            ]
        ]
    }


header : Html msg
header =
    Html.header [ class "header" ]
        [ Html.h1 [] [ Html.text "good times" ]
        , Html.ul []
            [ Html.li [] [ Html.a [ Attr.href "/search" ] [ Html.text "Search Media" ] ]
            , Html.li [] [ Html.a [ Attr.href "/search/users" ] [ Html.text "Find Friends" ] ]
            , Html.li [] [ Html.a [ Attr.href "/user/1" ] [ Html.text "My Profile" ] ]
            ]
        , Html.br [] []
        , Html.p [] [ Html.text "a book, movie & tv finder - for having a good time" ]
        ]


footer : Html msg
footer =
    Html.p []
        [ Html.text "made by "
        , Html.a [ class "footer-url", Attr.href "https://zoestatmanweil.com" ] [ Html.text "zboknows" ]
        , Html.text " and "
        , Html.a [ class "footer-url", Attr.href "https://aaronstrick.com" ] [ Html.text "strickinato" ]
        , Html.text " - powered by google books api and tmdb"
        ]
