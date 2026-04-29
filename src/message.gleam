import gleam/erlang/process.{type Subject}
import types.{type Account}

pub type SimulatorMsg {
  Start(
    nums_users: Int,
    num_subreddits: Int,
    simulation_time: Int,
    simulator_subject: Subject(SimulatorMsg),
    reddit_engine_subject: Subject(RedditEngineMsg),
    reddit_engine_pid: process.Pid,
  )
}

pub type RedditEngineMsg {
  Init(
    engine_subject: Subject(RedditEngineMsg),
    simulator_subject: Subject(SimulatorMsg),
  )

  AddAccount(
    reply_to: Subject(Result(String, String)),
    username: String,
    password: String,
  )
  UpdateAccount(account: Account)
  CreateSubReddit(
    reply_to: Subject(Result(String, String)),
    name: String,
    description: String,
  )
  JoinSubReddit(
    reply_to: Subject(Result(String, String)),
    user_id: String,
    subreddit_id: String,
  )
  LeaveSubReddit(
    reply_to: Subject(Result(String, String)),
    user_id: String,
    subreddit_id: String,
  )
  CreatePost(
    reply_to: Subject(Result(String, String)),
    user_id: String,
    subreddit_id: String,
    content: String,
  )
  CreateComment(
    reply_to: Subject(Result(String, String)),
    user_id: String,
    subreddit_id: String,
    comment: String,
  )
  CreateCommentReply(
    reply_to: Subject(Result(String, String)),
    user_id: String,
    subreddit_id: String,
    reply: String,
  )
  UpvotePost(
    reply_to: Subject(Result(String, String)),
    user_id: String,
    subreddit_id: String,
  )
  DownvotePost(
    reply_to: Subject(Result(String, String)),
    user_id: String,
    subreddit_id: String,
  )
  SendMessage(
    reply_to: Subject(Result(String, String)),
    sender_id: String,
    receiver_id: String,
    message: String,
  )
  GetFeed(reply_to: Subject(Result(String, String)), user_id: String)
  GetDirectMessages(reply_to: Subject(Result(String, String)), user_id: String)
  PrintStats
}

pub type ClientMsg {
  Initialize(
    client_subject: Subject(ClientMsg),
    engine_subject: Subject(RedditEngineMsg),
  )
  CreateAccount(username: String, password: String)
  CreateSubRedditClient(name: String, description: String)
  JoinSubRedditClient(subreddit_id: String)
  LeaveSubRedditClient(subreddit_id: String)
  CreatePostClient(subreddit_id: String, content: String)
  CreateCommentClient(post_id: String, comment: String)
  CreateCommentReplyClient(comment_id: String, reply: String)
  UpvotePostClient(post_id: String)
  DownvotePostClient(post_id: String)
  SendMessageClient(receiver_id: String, message: String)
  GetFeedClient
  GetDirectMessagesClient
  TerminateClient
}
