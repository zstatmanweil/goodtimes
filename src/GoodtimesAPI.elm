module GoodtimesAPI exposing (..)

import Http exposing (..)
import User exposing (LoggedInUser)


goodTimesRequest : LoggedInUser -> String -> String -> Maybe Body -> Expect msg -> Cmd msg
goodTimesRequest loggedInUser method url body expect =
    Http.request
        { method = method
        , headers = [ header "Authorization" ("Bearer " ++ loggedInUser.token) ]
        , url = "http://localhost:5000" ++ url
        , body = Maybe.withDefault emptyBody body
        , expect = expect
        , timeout = Nothing
        , tracker = Nothing
        }
