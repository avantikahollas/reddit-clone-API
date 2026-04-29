import gleam/dict.{type Dict}
import gleam/json
import gleam/list
import gleam/string
import gleam/time/calendar
import gleam/time/timestamp
import types.{
  type Account, type Comment, type DirectMessage, type Post, type SubReddit,
}

pub fn account_to_json(account: Account) -> String {
  json.object([
    #("username", json.string(account.username)),
    #("karma", json.int(account.karma)),
    #(
      "subscriptions",
      json.preprocessed_array(
        list.map(account.subscriptions, fn(sub) {
          json.object([
            #("name", json.string(sub.name)),
            #("description", json.string(sub.description)),
          ])
        }),
      ),
    ),
    #(
      "inbox",
      json.dict(account.inbox, string.trim, fn(msgs) {
        json.preprocessed_array(
          list.map(msgs, fn(msg) {
            json.object([
              #("sender_id", json.string(msg.sender_id)),
              #("content", json.string(msg.content)),
              #(
                "timestamp",
                json.string(timestamp.to_rfc3339(
                  msg.timestamp,
                  calendar.utc_offset,
                )),
              ),
            ])
          }),
        )
      }),
    ),
  ])
  |> json.to_string
}

pub fn subreddit_to_json(subreddit: SubReddit) -> String {
  json.object([
    #("name", json.string(subreddit.name)),
    #("description", json.string(subreddit.description)),
    #(
      "members",
      json.preprocessed_array(
        list.map(subreddit.members, fn(member) { json.string(member.username) }),
      ),
    ),
    #(
      "posts",
      json.preprocessed_array(
        list.map(subreddit.posts, fn(post) {
          json.object([
            #("author", json.string(post.author)),
            #("content", json.string(post.content)),
            #(
              "timestamp",
              json.string(timestamp.to_rfc3339(
                post.timestamp,
                calendar.utc_offset,
              )),
            ),
            #("upvotes", json.int(post.upvotes)),
            #("downvotes", json.int(post.downvotes)),
            #(
              "comments",
              json.preprocessed_array(
                list.map(post.comments, fn(comment) {
                  json.object([
                    #("author", json.string(comment.author)),
                    #("content", json.string(comment.content)),
                    #(
                      "timestamp",
                      json.string(timestamp.to_rfc3339(
                        comment.timestamp,
                        calendar.utc_offset,
                      )),
                    ),
                    #("upvotes", json.int(comment.upvotes)),
                    #("downvotes", json.int(comment.downvotes)),
                  ])
                }),
              ),
            ),
          ])
        }),
      ),
    ),
  ])
  |> json.to_string
}

pub fn post_to_json(post: Post) -> String {
  json.object([
    #("author", json.string(post.author)),
    #("content", json.string(post.content)),
    #(
      "timestamp",
      json.string(timestamp.to_rfc3339(post.timestamp, calendar.utc_offset)),
    ),
    #("upvotes", json.int(post.upvotes)),
    #("downvotes", json.int(post.downvotes)),
    #(
      "comments",
      json.preprocessed_array(
        list.map(post.comments, fn(comment) {
          json.object([
            #("author", json.string(comment.author)),
            #("content", json.string(comment.content)),
            #(
              "timestamp",
              json.string(timestamp.to_rfc3339(
                comment.timestamp,
                calendar.utc_offset,
              )),
            ),
            #("upvotes", json.int(comment.upvotes)),
            #("downvotes", json.int(comment.downvotes)),
          ])
        }),
      ),
    ),
  ])
  |> json.to_string
}

pub fn comment_to_json(comment: Comment) -> String {
  json.object([
    #("author", json.string(comment.author)),
    #("content", json.string(comment.content)),
    #(
      "timestamp",
      json.string(timestamp.to_rfc3339(comment.timestamp, calendar.utc_offset)),
    ),
    #("upvotes", json.int(comment.upvotes)),
    #("downvotes", json.int(comment.downvotes)),
    #(
      "replies",
      json.preprocessed_array(
        list.map(comment.replies, fn(reply) {
          json.object([
            #("author", json.string(reply.author)),
            #("content", json.string(reply.content)),
            #(
              "timestamp",
              json.string(timestamp.to_rfc3339(
                reply.timestamp,
                calendar.utc_offset,
              )),
            ),
            #("upvotes", json.int(reply.upvotes)),
            #("downvotes", json.int(reply.downvotes)),
          ])
        }),
      ),
    ),
  ])
  |> json.to_string
}

pub fn direct_message_to_json(message: DirectMessage) -> String {
  json.object([
    #("sender_id", json.string(message.sender_id)),
    #("receiver_id", json.string(message.receiver_id)),
    #("content", json.string(message.content)),
    #(
      "timestamp",
      json.string(timestamp.to_rfc3339(message.timestamp, calendar.utc_offset)),
    ),
  ])
  |> json.to_string
}

pub fn posts_to_json(posts: List(Post)) -> String {
  json.preprocessed_array(
    list.map(posts, fn(post) {
      json.object([
        #("author", json.string(post.author)),
        #("content", json.string(post.content)),
        #(
          "timestamp",
          json.string(timestamp.to_rfc3339(post.timestamp, calendar.utc_offset)),
        ),
        #("upvotes", json.int(post.upvotes)),
        #("downvotes", json.int(post.downvotes)),
        #(
          "comments",
          json.preprocessed_array(
            list.map(post.comments, fn(comment) {
              json.object([
                #("author", json.string(comment.author)),
                #("content", json.string(comment.content)),
                #(
                  "timestamp",
                  json.string(timestamp.to_rfc3339(
                    comment.timestamp,
                    calendar.utc_offset,
                  )),
                ),
                #("upvotes", json.int(comment.upvotes)),
                #("downvotes", json.int(comment.downvotes)),
              ])
            }),
          ),
        ),
      ])
    }),
  )
  |> json.to_string
}

pub fn direct_messages_to_json(messages: List(DirectMessage)) -> String {
  json.preprocessed_array(
    list.map(messages, fn(message) {
      json.object([
        #("sender_id", json.string(message.sender_id)),
        #("receiver_id", json.string(message.receiver_id)),
        #("content", json.string(message.content)),
        #(
          "timestamp",
          json.string(timestamp.to_rfc3339(
            message.timestamp,
            calendar.utc_offset,
          )),
        ),
      ])
    }),
  )
  |> json.to_string
}

pub fn inbox_to_json(inbox: Dict(String, List(DirectMessage))) -> String {
  json.dict(inbox, string.trim, fn(msgs) {
    json.preprocessed_array(
      list.map(msgs, fn(msg) {
        json.object([
          #("sender_id", json.string(msg.sender_id)),
          #("receiver_id", json.string(msg.receiver_id)),
          #("content", json.string(msg.content)),
          #(
            "timestamp",
            json.string(timestamp.to_rfc3339(msg.timestamp, calendar.utc_offset)),
          ),
        ])
      }),
    )
  })
  |> json.to_string
}
