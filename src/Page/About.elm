module Page.About exposing (..)

-- MODEL

import GoodtimesAuth0 exposing (auth0LoginUrl)
import Html exposing (Html)
import Html.Attributes as Attr exposing (class, id)
import Skeleton
import User exposing (LoggedInUser)


view : Maybe LoggedInUser -> Skeleton.Details msg
view loggedInUser =
    { title = "About"
    , attrs = []
    , kids =
        [ Html.div [ class "container", id "page-container" ]
            [ body loggedInUser
            ]
        ]
    }


body : Maybe LoggedInUser -> Html msg
body loggedInUser =
    Html.main_ [ class "content" ]
        [ Html.div [ id "content-wrap" ] <|
            case loggedInUser of
                Just user ->
                    [ Html.div [ id "user-profile" ]
                        [ Html.text ("welcome " ++ String.toLower user.userInfo.fullName ++ "!") ]
                    , Html.div [ class "about-box" ]
                        [ Html.h1 [] [ Html.text "about good times" ]
                        , viewAboutText
                        , Html.h2 [] [ Html.a [ Attr.href ("/user/" ++ String.fromInt user.userInfo.goodTimesId) ] [ Html.text "your profile" ] ]
                        ]
                    ]

                Nothing ->
                    [ Html.div [ class "about-box" ]
                        [ Html.h1 [] [ Html.text "welcome to good times" ]
                        , viewAboutText
                        , Html.br [] []
                        , Html.div [ class "page-text-center" ]
                            [ Html.text
                                "Already a good times enthusiast?"
                            ]
                        , Html.h2 [] [ Html.a [ Attr.href auth0LoginUrl ] [ Html.text "login" ] ]
                        , Html.div [ class "page-text-center" ]
                            [ Html.text
                                "Need to make an account?"
                            ]
                        , Html.h2 [] [ Html.a [ Attr.href auth0LoginUrl ] [ Html.text "sign up" ] ]
                        ]
                    ]
        ]


viewAboutText : Html msg
viewAboutText =
    Html.p [ class "page-text " ]
        [ Html.div []
            [ Html.text <|
                """
            Good Times was a product of the Covid-19 pandemic. As we all tried to stay inside and protect our community,
            we turned to books, movies and TV to bring us joy and entertainment. The Good Times platform can be used to track and share
            the media we are absorbing, make recommendations to friends, and see the overlaps between a friend's list
            and ours. Can't make a selection on movie night? Use Good Times to see what movies you and your roommate both
            want to watch! Tired of getting multiple TV recommendations a week but then not being able to remember one
            of them when it comes Friday night? Good Times will help you track your personal list and your recommendations.
            """
            ]
        , Html.br [] []
        , Html.div []
            [ Html.text <|
                """This website was born from the pandemic quarantine in another significant way as it gave its
            creators, Aaron Strick and Zoe Statman-Weil, a productive outlet when they got tired of reading and watching movies and TV.
            Aaron and Zoe met when they were 14, learned to code  in their mid-20s, attended """
            , Html.a [ Attr.href "https://www.recurse.com/" ] [ Html.text "Recurse Center" ]
            , Html.text <|
                """ enthusiastically but separately in 2018/19, and paired up starting in Fall 2020 to tackle Good Times one
            virtual coding session at a time."""
            ]
        ]
