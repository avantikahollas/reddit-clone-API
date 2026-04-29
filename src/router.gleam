import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/otp/actor
import message.{
  type RedditEngineMsg, AddAccount, CreateComment, CreateCommentReply,
  CreatePost, CreateSubReddit, DownvotePost, GetDirectMessages, GetFeed,
  JoinSubReddit, LeaveSubReddit, SendMessage, UpvotePost,
}
import web
import wisp.{type Request, type Response}

pub fn handle_request(
  req: Request,
  engine_subject: Subject(RedditEngineMsg),
) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    ["api", "v1", "users"] -> create_account(req, engine_subject)
    ["api", "v1", "subscribe", "sub"] -> join_subreddit(req, engine_subject)
    ["api", "v1", "subscribe", "unsub"] -> leave_subreddit(req, engine_subject)
    ["api", "v1", "site_admin"] -> create_subreddit(req, engine_subject)
    ["api", "v1", "live", "create"] -> create_post(req, engine_subject)
    ["api", "v1", "comment"] -> create_comment(req, engine_subject)
    ["api", "v1", "comment", "reply"] -> create_comment_reply(req, engine_subject)
    ["api", "v1", "vote", "1"] -> upvote_post(req, engine_subject)
    ["api", "v1", "vote", "-1"] -> downvote_post(req, engine_subject)
    ["api", "v1", "compose"] -> send_message(req, engine_subject)
    ["api", "v1", "live", "thread"] -> get_feed(req, engine_subject)
    ["api", "v1", "message", "inbox"] -> get_messages(req, engine_subject)

    // This matches all other paths.
    _ -> wisp.not_found()
  }
}

fn create_account(
  req: Request,
  engine_subject: Subject(RedditEngineMsg),
) -> Response {
  let query_params = wisp.get_query(req)

  case
    list.key_find(query_params, "username"),
    list.key_find(query_params, "password")
  {
    Ok(username), Ok(password) -> {
      let response =
        actor.call(engine_subject, 1000, fn(reply) {
          AddAccount(reply, username, password)
        })
      case response {
        Ok(response) -> wisp.created() |> wisp.string_body(response)
        Error(response) -> wisp.response(400) |> wisp.string_body(response)
      }
    }
    _, _ -> {
      wisp.response(400)
      |> wisp.string_body("Missing or invalid username/password")
    }
  }
}

fn join_subreddit(
  req: Request,
  engine_subject: Subject(RedditEngineMsg),
) -> Response {
  let query_params = wisp.get_query(req)
  case
    list.key_find(query_params, "username"),
    list.key_find(query_params, "subreddit_id")
  {
    Ok(username), Ok(subreddit_id) -> {
      let response =
        actor.call(engine_subject, 1000, fn(reply) {
          JoinSubReddit(reply, username, subreddit_id)
        })
      case response {
        Ok(response) -> wisp.created() |> wisp.string_body(response)
        Error(response) -> wisp.response(400) |> wisp.string_body(response)
      }
    }
    _, _ -> {
      wisp.response(400)
      |> wisp.string_body("Missing or invalid username/password")
    }
  }
}

fn leave_subreddit(
  req: Request,
  engine_subject: Subject(RedditEngineMsg),
) -> Response {
  let query_params = wisp.get_query(req)
  case
    list.key_find(query_params, "username"),
    list.key_find(query_params, "subreddit_id")
  {
    Ok(username), Ok(subreddit_id) -> {
      let response =
        actor.call(engine_subject, 1000, fn(reply) {
          LeaveSubReddit(reply, username, subreddit_id)
        })
      case response {
        Ok(response) -> wisp.ok() |> wisp.string_body(response)
        Error(response) -> wisp.response(400) |> wisp.string_body(response)
      }
    }
    _, _ -> {
      wisp.response(400)
      |> wisp.string_body("Missing or invalid username/password")
    }
  }
}

fn create_subreddit(
  req: Request,
  engine_subject: Subject(RedditEngineMsg),
) -> Response {
  let query_params = wisp.get_query(req)
  case
    list.key_find(query_params, "name"),
    list.key_find(query_params, "description")
  {
    Ok(name), Ok(description) -> {
      let response =
        actor.call(engine_subject, 1000, fn(reply) {
          CreateSubReddit(reply, name, description)
        })
      case response {
        Ok(response) -> wisp.created() |> wisp.string_body(response)
        Error(response) -> wisp.response(400) |> wisp.string_body(response)
      }
    }
    _, _ -> {
      wisp.response(400)
      |> wisp.string_body("Missing or invalid name/description")
    }
  }
}

fn create_post(
  req: Request,
  engine_subject: Subject(RedditEngineMsg),
) -> Response {
  let query_params = wisp.get_query(req)
  case
    list.key_find(query_params, "username"),
    list.key_find(query_params, "subreddit_id"),
    list.key_find(query_params, "content")
  {
    Ok(username), Ok(subreddit_id), Ok(content) -> {
      let response =
        actor.call(engine_subject, 1000, fn(reply) {
          CreatePost(reply, username, subreddit_id, content)
        })
      case response {
        Ok(response) -> wisp.created() |> wisp.string_body(response)
        Error(response) -> wisp.response(400) |> wisp.string_body(response)
      }
    }
    _, _, _ -> {
      wisp.response(400)
      |> wisp.string_body("Missing or invalid subreddit_id/content")
    }
  }
}

fn upvote_post(
  req: Request,
  engine_subject: Subject(RedditEngineMsg),
) -> Response {
  let query_params = wisp.get_query(req)
  case
    list.key_find(query_params, "username"),
    list.key_find(query_params, "subreddit_id")
  {
    Ok(username), Ok(subreddit_id) -> {
      let response =
        actor.call(engine_subject, 1000, fn(reply) {
          UpvotePost(reply, username, subreddit_id)
        })
      case response {
        Ok(response) -> wisp.ok() |> wisp.string_body(response)
        Error(response) -> wisp.response(400) |> wisp.string_body(response)
      }
    }
    _, _ -> {
      wisp.response(400)
      |> wisp.string_body("Missing or invalid subreddit_id/username")
    }
  }
}

fn downvote_post(
  req: Request,
  engine_subject: Subject(RedditEngineMsg),
) -> Response {
  let query_params = wisp.get_query(req)
  case
    list.key_find(query_params, "username"),
    list.key_find(query_params, "subreddit_id")
  {
    Ok(username), Ok(subreddit_id) -> {
      let response =
        actor.call(engine_subject, 1000, fn(reply) {
          DownvotePost(reply, username, subreddit_id)
        })
      case response {
        Ok(response) -> wisp.ok() |> wisp.string_body(response)
        Error(response) -> wisp.response(400) |> wisp.string_body(response)
      }
    }
    _, _ -> {
      wisp.response(400)
      |> wisp.string_body("Missing or invalid subreddit_id/username")
    }
  }
}

fn create_comment(
  req: Request,
  engine_subject: Subject(RedditEngineMsg),
) -> Response {
  let query_params = wisp.get_query(req)
  case
    list.key_find(query_params, "username"),
    list.key_find(query_params, "subreddit_id"),
    list.key_find(query_params, "comment")
  {
    Ok(username), Ok(subreddit_id), Ok(comment) -> {
      let response =
        actor.call(engine_subject, 1000, fn(reply) {
          CreateComment(reply, username, subreddit_id, comment)
        })
      case response {
        Ok(response) -> wisp.created() |> wisp.string_body(response)
        Error(response) -> wisp.response(400) |> wisp.string_body(response)
      }
    }
    _, _, _ -> {
      wisp.response(400)
      |> wisp.string_body("Missing or invalid subreddit_id/comment")
    }
  }
}

fn create_comment_reply(
  req: Request,
  engine_subject: Subject(RedditEngineMsg),
) -> Response {
  let query_params = wisp.get_query(req)
  case
    list.key_find(query_params, "username"),
    list.key_find(query_params, "subreddit_id"),
    list.key_find(query_params, "reply")
  {
    Ok(username), Ok(subreddit_id), Ok(reply) -> {
      let response =
        actor.call(engine_subject, 1000, fn(reply_msg) {
          CreateCommentReply(reply_msg, username, subreddit_id, reply)
        })
      case response {
        Ok(response) -> wisp.created() |> wisp.string_body(response)
        Error(response) -> wisp.response(400) |> wisp.string_body(response)
      }
    }
    _, _, _ -> {
      wisp.response(400)
      |> wisp.string_body("Missing or invalid subreddit_id/reply")
    }
  }
}

fn send_message(
  req: Request,
  engine_subject: Subject(RedditEngineMsg),
) -> Response {
  let query_params = wisp.get_query(req)
  case
    list.key_find(query_params, "username"),
    list.key_find(query_params, "receiver_username"),
    list.key_find(query_params, "message")
  {
    Ok(username), Ok(receiver_username), Ok(message) -> {
      let response =
        actor.call(engine_subject, 1000, fn(reply) {
          SendMessage(reply, username, receiver_username, message)
        })
      case response {
        Ok(response) -> wisp.created() |> wisp.string_body(response)
        Error(response) -> wisp.response(400) |> wisp.string_body(response)
      }
    }
    _, _, _ -> {
      wisp.response(400)
      |> wisp.string_body("Missing or invalid sender_id/receiver_id/message")
    }
  }
}

fn get_feed(req: Request, engine_subject: Subject(RedditEngineMsg)) -> Response {
  let query_params = wisp.get_query(req)
  case list.key_find(query_params, "username") {
    Ok(username) -> {
      let response =
        actor.call(engine_subject, 1000, fn(reply) { GetFeed(reply, username) })
      case response {
        Ok(response) -> wisp.ok() |> wisp.string_body(response)
        Error(response) -> wisp.response(400) |> wisp.string_body(response)
      }
    }
    _ -> {
      wisp.response(400)
      |> wisp.string_body("Missing or invalid username")
    }
  }
}

fn get_messages(
  req: Request,
  engine_subject: Subject(RedditEngineMsg),
) -> Response {
  let query_params = wisp.get_query(req)
  case list.key_find(query_params, "username") {
    Ok(username) -> {
      let response =
        actor.call(engine_subject, 1000, fn(reply) {
          GetDirectMessages(reply, username)
        })
      case response {
        Ok(response) -> wisp.ok() |> wisp.string_body(response)
        Error(response) -> wisp.response(400) |> wisp.string_body(response)
      }
    }
    _ -> {
      wisp.response(400)
      |> wisp.string_body("Missing or invalid username")
    }
  }
}
