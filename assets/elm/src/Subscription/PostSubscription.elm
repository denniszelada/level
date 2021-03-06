module Subscription.PostSubscription
    exposing
        ( subscribe
        , unsubscribe
        , replyCreatedDecoder
        )

import Json.Decode as Decode
import Json.Encode as Encode
import Data.SpaceUser
import Data.Reply exposing (Reply)
import GraphQL exposing (Document)
import Socket


-- SOCKETS


subscribe : String -> Cmd msg
subscribe postId =
    Socket.send (clientId postId) document (variables postId)


unsubscribe : String -> Cmd msg
unsubscribe postId =
    Socket.cancel (clientId postId)



-- DECODERS


replyCreatedDecoder : Decode.Decoder Reply
replyCreatedDecoder =
    let
        payloadDecoder typename =
            if typename == "ReplyCreatedPayload" then
                Decode.field "reply" Data.Reply.decoder
            else
                Decode.fail "payload does not match"
    in
        decodeByTypename payloadDecoder



-- INTERNAL


clientId : String -> String
clientId id =
    "post_subscription_" ++ id


document : Document
document =
    GraphQL.document
        """
        subscription PostSubscription(
          $postId: ID!
        ) {
          postSubscription(postId: $postId) {
            __typename
            ... on ReplyCreatedPayload {
              reply {
                ...ReplyFields
              }
            }
          }
        }
        """
        [ Data.Reply.fragment
        , Data.SpaceUser.fragment
        ]


variables : String -> Maybe Encode.Value
variables postId =
    Just <|
        Encode.object
            [ ( "postId", Encode.string postId )
            ]


decodeByTypename : (String -> Decode.Decoder a) -> Decode.Decoder a
decodeByTypename payloadDecoder =
    Decode.at [ "data", "postSubscription" ] <|
        (Decode.field "__typename" Decode.string
            |> Decode.andThen payloadDecoder
        )
