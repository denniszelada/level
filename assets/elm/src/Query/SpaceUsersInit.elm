module Query.SpaceUsersInit exposing (Response, request)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Task exposing (Task)
import Connection exposing (Connection)
import Data.SpaceUser as SpaceUser exposing (SpaceUser)
import GraphQL exposing (Document)
import Route.SpaceUsers exposing (Params(..))
import Session exposing (Session)


type alias Response =
    { spaceUsers : Connection SpaceUser
    }


document : Params -> Document
document params =
    GraphQL.document (documentBody params)
        [ Connection.fragment "SpaceUserConnection" SpaceUser.fragment
        ]


documentBody : Params -> String
documentBody params =
    case params of
        Root ->
            """
            query SpaceUsersInit(
              $spaceId: ID!,
              $limit: Int!
            ) {
              space(id: $spaceId) {
                spaceUsers(first: $limit) {
                  ...SpaceUserConnectionFields
                }
              }
            }
            """

        After _ ->
            """
            query SpaceUsersInit(
              $spaceId: ID!,
              $cursor: Cursor!,
              $limit: Int!
            ) {
              space(id: $spaceId) {
                spaceUsers(first: $limit, after: $cursor) {
                  ...SpaceUserConnectionFields
                }
              }
            }
            """

        Before _ ->
            """
            query SpaceUsersInit(
              $spaceId: ID!,
              $cursor: Cursor!,
              $limit: Int!
            ) {
              space(id: $spaceId) {
                spaceUsers(last: $limit, before: $cursor) {
                  ...SpaceUserConnectionFields
                }
              }
            }
            """


variables : String -> Params -> Int -> Maybe Encode.Value
variables spaceId params limit =
    let
        paramVariables =
            case params of
                After cursor ->
                    [ ( "cursor", Encode.string cursor ) ]

                Before cursor ->
                    [ ( "cursor", Encode.string cursor ) ]

                Root ->
                    []
    in
        Just <|
            Encode.object <|
                List.append paramVariables
                    [ ( "spaceId", Encode.string spaceId )
                    , ( "limit", Encode.int limit )
                    ]


decoder : Decoder Response
decoder =
    Decode.at [ "data", "space", "spaceUsers" ] <|
        Decode.map Response (Connection.decoder SpaceUser.decoder)


request : String -> Params -> Int -> Session -> Task Session.Error ( Session, Response )
request spaceId params limit session =
    Session.request session <|
        GraphQL.request (document params) (variables spaceId params limit) decoder
