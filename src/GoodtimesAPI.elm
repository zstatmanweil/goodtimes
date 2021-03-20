module GoodtimesAPI exposing (..)

import Environment exposing (Environment)
import Http exposing (..)


type alias GoodTimesRequestInfo msg =
    { token : String
    , method : String
    , url : String
    , body : Maybe Body
    , expect : Expect msg
    , environment : Environment
    }


goodTimesRequest : GoodTimesRequestInfo msg -> Cmd msg
goodTimesRequest requestInfo =
    Http.request
        { method = requestInfo.method
        , headers = [ header "Authorization" ("Bearer " ++ requestInfo.token) ]
        , url = Environment.apiUrl requestInfo.environment ++ requestInfo.url
        , body = Maybe.withDefault emptyBody requestInfo.body
        , expect = requestInfo.expect
        , timeout = Nothing
        , tracker = Nothing
        }
