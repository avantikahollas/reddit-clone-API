import gleam/erlang/process.{type Subject}
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/io
import gleam/otp/actor
import gleam/string
import message.{
  type ClientMsg, type RedditEngineMsg, CreateAccount, CreateCommentClient,
  CreateCommentReplyClient, CreatePostClient, CreateSubRedditClient,
  DownvotePostClient, GetDirectMessagesClient, GetFeedClient, Initialize,
  JoinSubRedditClient, LeaveSubRedditClient, SendMessageClient, TerminateClient,
  UpvotePostClient,
}

pub type ClientState {
  ClientState(
    username: String,
    password: String,
    client_subject: Subject(ClientMsg),
    engine_subject: Subject(RedditEngineMsg),
  )
}

pub fn handle(
  state: ClientState,
  message: ClientMsg,
) -> actor.Next(ClientState, ClientMsg) {
  case message {
    Initialize(client_subject, engine_subject) -> {
      actor.continue(ClientState(
        state.username,
        state.password,
        client_subject,
        engine_subject,
      ))
    }

    CreateAccount(username, password) -> {
      let req =
        build_base_req(http.Post, "/api/v1/users")
        |> request.set_query([
          #("username", username),
          #("password", password),
        ])
        |> request.set_body("")
      // Empty body, no JSON
      case httpc.send(req) {
        Ok(res) if res.status >= 200 && res.status < 300 -> {
          io.println("Created account: " <> res.body)
        }

        Ok(res) ->
          io.println(
            "Error: Status " <> int.to_string(res.status) <> " - " <> res.body,
          )
        Error(e) -> io.println("HTTP Error: " <> string.inspect(e))
      }
      actor.continue(state)
    }

    JoinSubRedditClient(subreddit_id) -> {
      let req =
        build_base_req(http.Post, "/api/v1/subscribe/sub")
        |> request.set_query([
          #("username", state.username),
          #("subreddit_id", subreddit_id),
        ])
        |> request.set_body("")
      case httpc.send(req) {
        Ok(res) if res.status >= 200 && res.status < 300 -> {
          io.println("Joined subreddit: " <> res.body)
        }

        Ok(res) ->
          io.println(
            "Error: Status " <> int.to_string(res.status) <> " - " <> res.body,
          )
        Error(e) -> io.println("HTTP Error: " <> string.inspect(e))
      }
      actor.continue(state)
    }

    LeaveSubRedditClient(subreddit_id) -> {
      let req =
        build_base_req(http.Delete, "/api/v1/subscribe/unsub")
        |> request.set_query([
          #("username", state.username),
          #("subreddit_id", subreddit_id),
        ])
        |> request.set_body("")
      case httpc.send(req) {
        Ok(res) if res.status >= 200 && res.status < 300 -> {
          io.println("Left subreddit: " <> res.body)
        }

        Ok(res) ->
          io.println(
            "Error: Status " <> int.to_string(res.status) <> " - " <> res.body,
          )
        Error(e) -> io.println("HTTP Error: " <> string.inspect(e))
      }
      actor.continue(state)
    }

    CreateSubRedditClient(name, description) -> {
      let req =
        build_base_req(http.Post, "/api/v1/site_admin")
        |> request.set_query([
          #("name", name),
          #("description", description),
        ])
        |> request.set_body("")
      case httpc.send(req) {
        Ok(res) if res.status >= 200 && res.status < 300 -> {
          io.println("Created subreddit: " <> res.body)
        }

        Ok(res) ->
          io.println(
            "Error: Status " <> int.to_string(res.status) <> " - " <> res.body,
          )
        Error(e) -> io.println("HTTP Error: " <> string.inspect(e))
      }
      actor.continue(state)
    }

    CreatePostClient(subreddit_id, content) -> {
      let req =
        build_base_req(http.Post, "/api/v1/live/create")
        |> request.set_query([
          #("subreddit_id", subreddit_id),
          #("content", content),
          #("username", state.username),
        ])
        |> request.set_body("")
      case httpc.send(req) {
        Ok(res) if res.status >= 200 && res.status < 300 -> {
          io.println("Created post: " <> res.body)
        }

        Ok(res) ->
          io.println(
            "Error: Status " <> int.to_string(res.status) <> " - " <> res.body,
          )
        Error(e) -> io.println("HTTP Error: " <> string.inspect(e))
      }
      actor.continue(state)
    }

    CreateCommentClient(subreddit_id, comment) -> {
      let req =
        build_base_req(http.Post, "/api/v1/comment")
        |> request.set_query([
          #("username", state.username),
          #("subreddit_id", subreddit_id),
          #("comment", comment),
        ])
        |> request.set_body("")
      case httpc.send(req) {
        Ok(res) if res.status >= 200 && res.status < 300 -> {
          io.println("Created comment: " <> res.body)
        }

        Ok(res) ->
          io.println(
            "Error: Status " <> int.to_string(res.status) <> " - " <> res.body,
          )
        Error(e) -> io.println("HTTP Error: " <> string.inspect(e))
      }
      actor.continue(state)
    }

    CreateCommentReplyClient(subreddit_id, reply) -> {
      let req =
        build_base_req(http.Post, "/api/v1/comment/reply")
        |> request.set_query([
          #("username", state.username),
          #("subreddit_id", subreddit_id),
          #("reply", reply),
        ])
        |> request.set_body("")
      case httpc.send(req) {
        Ok(res) if res.status >= 200 && res.status < 300 -> {
          io.println("Created comment: " <> res.body)
        }

        Ok(res) ->
          io.println(
            "Error: Status " <> int.to_string(res.status) <> " - " <> res.body,
          )
        Error(e) -> io.println("HTTP Error: " <> string.inspect(e))
      }
      actor.continue(state)
    }

    UpvotePostClient(subreddit_id) -> {
      let req =
        build_base_req(http.Post, "/api/v1/vote/1")
        |> request.set_query([
          #("username", state.username),
          #("subreddit_id", subreddit_id),
        ])
        |> request.set_body("")
      case httpc.send(req) {
        Ok(res) if res.status >= 200 && res.status < 300 -> {
          io.println("Upvoted post: " <> res.body)
        }

        Ok(res) ->
          io.println(
            "Error: Status " <> int.to_string(res.status) <> " - " <> res.body,
          )
        Error(e) -> io.println("HTTP Error: " <> string.inspect(e))
      }
      actor.continue(state)
    }

    DownvotePostClient(subreddit_id) -> {
      let req =
        build_base_req(http.Post, "/api/v1/vote/-1")
        |> request.set_query([
          #("username", state.username),
          #("subreddit_id", subreddit_id),
        ])
        |> request.set_body("")
      case httpc.send(req) {
        Ok(res) if res.status >= 200 && res.status < 300 -> {
          io.println("Downvoted post: " <> res.body)
        }

        Ok(res) ->
          io.println(
            "Error: Status " <> int.to_string(res.status) <> " - " <> res.body,
          )
        Error(e) -> io.println("HTTP Error: " <> string.inspect(e))
      }
      actor.continue(state)
    }

    SendMessageClient(receiver_id, message) -> {
      let req =
        build_base_req(http.Post, "/api/v1/compose")
        |> request.set_query([
          #("username", state.username),
          #("receiver_id", receiver_id),
          #("message", message),
        ])
        |> request.set_body("")
      case httpc.send(req) {
        Ok(res) if res.status >= 200 && res.status < 300 -> {
          io.println("Sent message: " <> res.body)
        }

        Ok(res) ->
          io.println(
            "Error: Status " <> int.to_string(res.status) <> " - " <> res.body,
          )
        Error(e) -> io.println("HTTP Error: " <> string.inspect(e))
      }
      actor.continue(state)
    }

    GetFeedClient -> {
      let req =
        build_base_req(http.Get, "/api/v1/live/thread")
        |> request.set_query([
          #("username", state.username),
        ])
        |> request.set_body("")
      case httpc.send(req) {
        Ok(res) if res.status >= 200 && res.status < 300 -> {
          io.println("Feed: " <> res.body)
        }

        Ok(res) ->
          io.println(
            "Error: Status " <> int.to_string(res.status) <> " - " <> res.body,
          )
        Error(e) -> io.println("HTTP Error: " <> string.inspect(e))
      }
      actor.continue(state)
    }

    GetDirectMessagesClient -> {
      let req =
        build_base_req(http.Get, "/api/v1/message/inbox")
        |> request.set_query([
          #("username", state.username),
        ])
        |> request.set_body("")
      case httpc.send(req) {
        Ok(res) if res.status >= 200 && res.status < 300 -> {
          io.println("Inbox: " <> res.body)
        }

        Ok(res) ->
          io.println(
            "Error: Status " <> int.to_string(res.status) <> " - " <> res.body,
          )
        Error(e) -> io.println("HTTP Error: " <> string.inspect(e))
      }
      actor.continue(state)
    }

    TerminateClient -> {
      actor.stop()
    }
  }
}

fn build_base_req(method: http.Method, path: String) -> request.Request(String) {
  request.new()
  |> request.set_method(method)
  |> request.set_scheme(http.Http)
  |> request.set_host("localhost")
  |> request.set_port(8000)
  |> request.set_path(path)
}
