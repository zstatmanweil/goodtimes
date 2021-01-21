module GoodtimesAPI exposing (..)

import Http exposing (..)
import User exposing (LoggedInUser)


type alias GoodTimesRequestInfo msg =
    { loggedInUser : LoggedInUser
    , method : String
    , url : String
    , body : Maybe Body
    , expect : Expect msg
    }


goodTimesRequest : GoodTimesRequestInfo msg -> Cmd msg
goodTimesRequest requsetInfo =
    Http.request
        { method = requsetInfo.method
        , headers = [ header "Authorization" ("Bearer " ++ requsetInfo.loggedInUser.token) ]
        , url = "http://localhost:5000" ++ requsetInfo.url
        , body = Maybe.withDefault emptyBody requsetInfo.body
        , expect = requsetInfo.expect
        , timeout = Nothing
        , tracker = Nothing
        }
