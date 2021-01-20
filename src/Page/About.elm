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
        [ Html.div [ id "content-wrap" ]
            [ Html.h2 [] [ Html.text "good times" ]
            , case loggedInUser of
                Just user ->
                    Html.text ("You are logged in" ++ user.userInfo.fullName)

                Nothing ->
                    Html.div []
                        [ Html.text "You need to log in"
                        , Html.div [] [ Html.a [ Attr.href auth0LoginUrl ] [ Html.text "login" ] ]
                        ]
            ]
        ]
