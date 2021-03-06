module Mutation.CreateGroup exposing (Response(..), request)

import Task exposing (Task)
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)
import Data.Group as Group exposing (Group)
import Data.ValidationFields as ValidationFields
import Data.ValidationError as ValidationError exposing (ValidationError)
import Session exposing (Session)
import GraphQL exposing (Document)


type Response
    = Success Group
    | Invalid (List ValidationError)


document : Document
document =
    GraphQL.document
        """
        mutation CreateGroup(
          $spaceId: ID!,
          $name: String!,
          $isPrivate: Boolean!
        ) {
          createGroup(
            spaceId: $spaceId,
            name: $name,
            isPrivate: $isPrivate
          ) {
            ...ValidationFields
            group {
              ...GroupFields
            }
          }
        }
        """
        [ Group.fragment
        , ValidationFields.fragment
        ]


variables : String -> String -> Bool -> Maybe Encode.Value
variables spaceId name isPrivate =
    Just <|
        Encode.object
            [ ( "spaceId", Encode.string spaceId )
            , ( "name", Encode.string name )
            , ( "isPrivate", Encode.bool isPrivate )
            ]


successDecoder : Decoder Response
successDecoder =
    Decode.map Success <|
        Decode.at [ "data", "createGroup", "group" ] Group.decoder


failureDecoder : Decoder Response
failureDecoder =
    Decode.map Invalid <|
        Decode.at [ "data", "createGroup", "errors" ]
            (Decode.list ValidationError.decoder)


decoder : Decoder Response
decoder =
    let
        conditionalDecoder : Bool -> Decoder Response
        conditionalDecoder success =
            case success of
                True ->
                    successDecoder

                False ->
                    failureDecoder
    in
        Decode.at [ "data", "createGroup", "success" ] Decode.bool
            |> Decode.andThen conditionalDecoder


request : String -> String -> Bool -> Session -> Task Session.Error ( Session, Response )
request spaceId name isPrivate session =
    Session.request session <|
        GraphQL.request document (variables spaceId name isPrivate) decoder
