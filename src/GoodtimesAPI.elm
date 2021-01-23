module GoodtimesAPI exposing (..)

import Http exposing (..)


type alias GoodTimesRequestInfo msg =
    { token : String
    , method : String
    , url : String
    , body : Maybe Body
    , expect : Expect msg
    }


goodTimesRequest : GoodTimesRequestInfo msg -> Cmd msg
goodTimesRequest requestInfo =
    Http.request
        { method = requestInfo.method
        , headers = [ header "Authorization" ("Bearer " ++ requestInfo.token) ]
        , url = "http://localhost:5000" ++ requestInfo.url
        , body = Maybe.withDefault emptyBody requestInfo.body
        , expect = requestInfo.expect
        , timeout = Nothing
        , tracker = Nothing
        }
