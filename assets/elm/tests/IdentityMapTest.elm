module IdentityMapTest exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (string)
import IdentityMap
import Test exposing (..)


type alias TestRecord =
    { id : String
    , name : String
    }


tests : Test
tests =
    describe "IdentityMap.get"
        [ fuzz2 string string "returns the record from the map if exists" <|
            \id name ->
                let
                    record =
                        TestRecord id name

                    map =
                        record
                            |> IdentityMap.set IdentityMap.init .id

                    default =
                        TestRecord id "Stale"
                in
                    default
                        |> IdentityMap.get map .id
                        |> .name
                        |> Expect.equal name
        , fuzz2 string string "returns the default if not in the map" <|
            \id name ->
                let
                    record =
                        TestRecord id name

                    map =
                        TestRecord "other" "other"
                            |> IdentityMap.set IdentityMap.init .id
                in
                    record
                        |> IdentityMap.get map .id
                        |> .name
                        |> Expect.equal name
        ]
