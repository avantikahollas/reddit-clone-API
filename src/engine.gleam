import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/otp/actor
import gleam/result
import gleam/string
import gleam/time/timestamp
import json_formatter
import message.{
  type RedditEngineMsg, type SimulatorMsg, AddAccount, CreateComment,
  CreateCommentReply, CreatePost, CreateSubReddit, DownvotePost,
  GetDirectMessages, GetFeed, Init, JoinSubReddit, LeaveSubReddit, PrintStats,
  SendMessage, UpdateAccount, UpvotePost,
}
import types.{
  type Account, type SubReddit, Account, Comment, DirectMessage, Post, SubReddit,
}

pub type RedditEngineState {
  RedditEngineState(
    accounts: Dict(String, Account),
    subreddits: Dict(String, SubReddit),
    num_posts: Int,
    num_comments: Int,
    num_messages: Int,
    num_upvotes: Int,
    num_downvotes: Int,
    engine_subject: Subject(RedditEngineMsg),
    simulator_subject: Subject(SimulatorMsg),
  )
}

pub fn handle(
  state: RedditEngineState,
  message: RedditEngineMsg,
) -> actor.Next(RedditEngineState, RedditEngineMsg) {
  // Placeholder for handling messages
  case message {
    Init(engine_subject, simulator_subject) -> {
      actor.continue(RedditEngineState(
        dict.new(),
        dict.new(),
        state.num_posts,
        state.num_comments,
        state.num_messages,
        state.num_upvotes,
        state.num_downvotes,
        engine_subject,
        simulator_subject,
      ))
    }

    AddAccount(reply_to, username, password) -> {
      case dict.has_key(state.accounts, username) {
        True -> {
          process.send(reply_to, Error("Username already exists"))
          io.println("Error: Username already exists: " <> username)
          actor.continue(state)
        }
        False -> {
          // Proceed to create the account
          let account = Account(username, password, 0, [], dict.new())
          let updated_accounts = dict.insert(state.accounts, username, account)
          let json_response = json_formatter.account_to_json(account)
          process.send(reply_to, Ok(json_response))
          io.println("JSON Response: " <> json_response)
          actor.continue(RedditEngineState(
            updated_accounts,
            state.subreddits,
            state.num_posts,
            state.num_comments,
            state.num_messages,
            state.num_upvotes,
            state.num_downvotes,
            state.engine_subject,
            state.simulator_subject,
          ))
        }
      }
    }

    UpdateAccount(account) -> {
      let updated_accounts =
        dict.insert(state.accounts, account.username, account)
      // echo updated_accounts
      actor.continue(RedditEngineState(
        updated_accounts,
        state.subreddits,
        state.num_posts,
        state.num_comments,
        state.num_messages,
        state.num_upvotes,
        state.num_downvotes,
        state.engine_subject,
        state.simulator_subject,
      ))
    }

    CreateSubReddit(reply_to, name, description) -> {
      case dict.has_key(state.subreddits, name) {
        True -> {
          process.send(reply_to, Error("SubReddit already exists: " <> name))
          io.println("Error: SubReddit already exists: " <> name)
          actor.continue(state)
        }
        False -> {
          // Proceed to create the subreddit
          let subreddit = SubReddit(name, description, [], [])
          let updated_subreddits =
            dict.insert(state.subreddits, name, subreddit)
          let json_response = json_formatter.subreddit_to_json(subreddit)
          io.println("JSON Response: " <> json_response)
          process.send(reply_to, Ok(json_response))
          actor.continue(RedditEngineState(
            state.accounts,
            updated_subreddits,
            state.num_posts,
            state.num_comments,
            state.num_messages,
            state.num_upvotes,
            state.num_downvotes,
            state.engine_subject,
            state.simulator_subject,
          ))
        }
      }
    }

    JoinSubReddit(reply_to, user_id, subreddit_id) -> {
      case dict.has_key(state.accounts, user_id) {
        False -> {
          process.send(reply_to, Error("User does not exist: " <> user_id))
          io.println("Error: User does not exist: " <> user_id)
          actor.continue(state)
        }
        True -> {
          case dict.has_key(state.subreddits, subreddit_id) {
            False -> {
              process.send(
                reply_to,
                Error("SubReddit does not exist: " <> subreddit_id),
              )
              io.println("Error: SubReddit does not exist: " <> subreddit_id)
              actor.continue(state)
            }
            True -> {
              let account =
                result.unwrap(
                  dict.get(state.accounts, user_id),
                  Account("", "", 0, [], dict.new()),
                )
              let subreddit =
                result.unwrap(
                  dict.get(state.subreddits, subreddit_id),
                  SubReddit("", "", [], []),
                )
              case list.contains(account.subscriptions, subreddit) {
                False -> {
                  // Update account's subscriptions
                  let updated_account =
                    Account(
                      account.username,
                      account.password,
                      account.karma,
                      list.append(account.subscriptions, [subreddit]),
                      account.inbox,
                    )
                  let updated_accounts =
                    dict.insert(state.accounts, user_id, updated_account)
                  // Update subreddit's members
                  let updated_subreddit =
                    SubReddit(
                      subreddit.name,
                      subreddit.description,
                      list.append(subreddit.members, [updated_account]),
                      subreddit.posts,
                    )
                  let updated_subreddits =
                    dict.insert(
                      state.subreddits,
                      subreddit_id,
                      updated_subreddit,
                    )
                  let json_response =
                    json_formatter.account_to_json(updated_account)
                  process.send(reply_to, Ok(json_response))
                  io.println("JSON Response: " <> json_response)
                  actor.continue(RedditEngineState(
                    updated_accounts,
                    updated_subreddits,
                    state.num_posts,
                    state.num_comments,
                    state.num_messages,
                    state.num_upvotes,
                    state.num_downvotes,
                    state.engine_subject,
                    state.simulator_subject,
                  ))
                }
                True -> {
                  process.send(
                    reply_to,
                    Error(
                      "User "
                      <> user_id
                      <> " has already joined SubReddit "
                      <> subreddit_id,
                    ),
                  )
                  io.println("Error: User " <> user_id <> " has already joined SubReddit " <> subreddit_id)
                  actor.continue(state)
                }
              }
            }
          }
        }
      }
    }

    LeaveSubReddit(reply_to, user_id, subreddit_id) -> {
      case dict.has_key(state.accounts, user_id) {
        False -> {
          process.send(reply_to, Error("User does not exist: " <> user_id))
          io.println("Error: User does not exist: " <> user_id)
          actor.continue(state)
        }
        True -> {
          case dict.has_key(state.subreddits, subreddit_id) {
            False -> {
              process.send(
                reply_to,
                Error("SubReddit does not exist: " <> subreddit_id),
              )
              io.println("Error: SubReddit does not exist: " <> subreddit_id)
              actor.continue(state)
            }
            True -> {
              let account =
                result.unwrap(
                  dict.get(state.accounts, user_id),
                  Account("", "", 0, [], dict.new()),
                )
              let subreddit =
                result.unwrap(
                  dict.get(state.subreddits, subreddit_id),
                  SubReddit("", "", [], []),
                )
              let updated_subscriptions =
                list.filter(account.subscriptions, fn(sub) {
                  sub.name != subreddit_id
                })
              let updated_account =
                Account(
                  account.username,
                  account.password,
                  account.karma,
                  updated_subscriptions,
                  account.inbox,
                )
              let updated_accounts =
                dict.insert(state.accounts, user_id, updated_account)
              let updated_members =
                list.filter(subreddit.members, fn(mem) {
                  mem.username != user_id
                })
              let updated_subreddits =
                dict.insert(
                  state.subreddits,
                  subreddit_id,
                  SubReddit(
                    subreddit.name,
                    subreddit.description,
                    updated_members,
                    subreddit.posts,
                  ),
                )
              let json_response =
                json_formatter.account_to_json(updated_account)
              io.println("JSON Response: " <> json_response)
              process.send(reply_to, Ok(json_response))
              io.println("JSON Response: " <> json_response)
              actor.continue(RedditEngineState(
                updated_accounts,
                updated_subreddits,
                state.num_posts,
                state.num_comments,
                state.num_messages,
                state.num_upvotes,
                state.num_downvotes,
                state.engine_subject,
                state.simulator_subject,
              ))
            }
          }
        }
      }
    }

    CreatePost(reply_to, user_id, subreddit_id, content) -> {
      case dict.has_key(state.accounts, user_id) {
        False -> {
          process.send(reply_to, Error("User does not exist: " <> user_id))
          io.println("Error: User does not exist: " <> user_id)
          actor.continue(state)
        }
        True -> {
          case dict.has_key(state.subreddits, subreddit_id) {
            False -> {
              process.send(
                reply_to,
                Error("SubReddit does not exist: " <> subreddit_id),
              )
              io.println("Error: SubReddit does not exist: " <> subreddit_id)
              actor.continue(state)
            }
            True -> {
              let subreddit =
                result.unwrap(
                  dict.get(state.subreddits, subreddit_id),
                  SubReddit("", "", [], []),
                )
              let post =
                Post(user_id, content, timestamp.system_time(), 0, 0, [])
              let updated_subreddit =
                SubReddit(
                  subreddit.name,
                  subreddit.description,
                  subreddit.members,
                  list.append(subreddit.posts, [post]),
                )
              let updated_subreddits =
                dict.insert(state.subreddits, subreddit_id, updated_subreddit)
              let updated_state =
                RedditEngineState(
                  state.accounts,
                  updated_subreddits,
                  state.num_posts + 1,
                  state.num_comments,
                  state.num_messages,
                  state.num_upvotes,
                  state.num_downvotes,
                  state.engine_subject,
                  state.simulator_subject,
                )
              process.send(reply_to, Ok(json_formatter.post_to_json(post)))
              io.println("JSON Response: " <> json_formatter.post_to_json(post))
              actor.continue(updated_state)
            }
          }
        }
      }
    }

    CreateComment(reply_to, user_id, subreddit_id, comment) -> {
      case dict.has_key(state.accounts, user_id) {
        False -> {
          process.send(reply_to, Error("User does not exist: " <> user_id))
          io.println("Error: User does not exist: " <> user_id)
          actor.continue(state)
        }
        True -> {
          case dict.has_key(state.subreddits, subreddit_id) {
            False -> {
              process.send(
                reply_to,
                Error("SubReddit does not exist: " <> subreddit_id),
              )
              io.println("Error: SubReddit does not exist: " <> subreddit_id)
              actor.continue(state)
            }
            True -> {
              let subreddit =
                result.unwrap(
                  dict.get(state.subreddits, subreddit_id),
                  SubReddit("", "", [], []),
                )
              case subreddit.posts {
                [] -> {
                  actor.continue(state)
                }
                _ -> {
                  // Get a random post to comment on
                  let post_id = int.random(list.length(subreddit.posts))
                  let comment_obj =
                    types.Comment(
                      user_id,
                      comment,
                      timestamp.system_time(),
                      0,
                      0,
                      [],
                    )
                  let posts =
                    list.index_map(subreddit.posts, fn(p, i) {
                      case i == post_id {
                        True -> {
                          Post(
                            p.author,
                            p.content,
                            p.timestamp,
                            p.upvotes,
                            p.downvotes,
                            list.append(p.comments, [comment_obj]),
                          )
                        }
                        False -> {
                          p
                        }
                      }
                    })
                  let updated_subreddit =
                    SubReddit(
                      subreddit.name,
                      subreddit.description,
                      subreddit.members,
                      posts,
                    )
                  process.send(
                    reply_to,
                    Ok(json_formatter.comment_to_json(comment_obj)),
                  )
                  io.println("JSON Response: " <> json_formatter.comment_to_json(comment_obj))
                  actor.continue(RedditEngineState(
                    state.accounts,
                    dict.insert(
                      state.subreddits,
                      subreddit_id,
                      updated_subreddit,
                    ),
                    state.num_posts,
                    state.num_comments + 1,
                    state.num_messages,
                    state.num_upvotes,
                    state.num_downvotes,
                    state.engine_subject,
                    state.simulator_subject,
                  ))
                }
              }
            }
          }
        }
      }
    }

    UpvotePost(reply_to, user_id, subreddit_id) -> {
      case dict.has_key(state.accounts, user_id) {
        False -> {
          process.send(reply_to, Error("User does not exist: " <> user_id))
          io.println("Error: User does not exist: " <> user_id)
          actor.continue(state)
        }
        True -> {
          case dict.has_key(state.subreddits, subreddit_id) {
            False -> {
              process.send(
                reply_to,
                Error("SubReddit does not exist: " <> subreddit_id),
              )
              io.println("Error: SubReddit does not exist: " <> subreddit_id)
              actor.continue(state)
            }
            True -> {
              let subreddit =
                result.unwrap(
                  dict.get(state.subreddits, subreddit_id),
                  SubReddit("", "", [], []),
                )
              case subreddit.posts {
                [] -> {
                  process.send(
                    reply_to,
                    Error("No posts in SubReddit: " <> subreddit_id),
                  )
                  io.println("Error: No posts in SubReddit: " <> subreddit_id)
                  actor.continue(state)
                }
                _ -> {
                  // Get a random post to upvote
                  let post_id = int.random(list.length(subreddit.posts))
                  let posts =
                    list.index_map(subreddit.posts, fn(p, i) {
                      case i == post_id {
                        True -> {
                          let account =
                            result.unwrap(
                              dict.get(state.accounts, user_id),
                              Account("", "", 0, [], dict.new()),
                            )
                          let updated_account =
                            Account(
                              account.username,
                              account.password,
                              account.karma + 1,
                              account.subscriptions,
                              account.inbox,
                            )
                          actor.send(
                            state.engine_subject,
                            UpdateAccount(updated_account),
                          )
                          Post(
                            p.author,
                            p.content,
                            p.timestamp,
                            p.upvotes + 1,
                            p.downvotes,
                            p.comments,
                          )
                        }
                        False -> {
                          p
                        }
                      }
                    })
                  let updated_subreddit =
                    SubReddit(
                      subreddit.name,
                      subreddit.description,
                      subreddit.members,
                      posts,
                    )

                  let updated_post =
                    list.drop(posts, post_id)
                    |> list.first
                    |> result.unwrap(
                      Post("", "", timestamp.system_time(), 0, 0, []),
                    )
                  process.send(
                    reply_to,
                    Ok(json_formatter.post_to_json(updated_post)),
                  )
                  actor.continue(RedditEngineState(
                    state.accounts,
                    dict.insert(
                      state.subreddits,
                      subreddit_id,
                      updated_subreddit,
                    ),
                    state.num_posts,
                    state.num_comments,
                    state.num_messages,
                    state.num_upvotes + 1,
                    state.num_downvotes,
                    state.engine_subject,
                    state.simulator_subject,
                  ))
                }
              }
            }
          }
        }
      }
    }

    DownvotePost(reply_to, user_id, subreddit_id) -> {
      // Handle post downvoting
      case dict.has_key(state.accounts, user_id) {
        False -> {
          process.send(reply_to, Error("User does not exist: " <> user_id))
          io.println("Error: User does not exist: " <> user_id)
          actor.continue(state)
        }
        True -> {
          case dict.has_key(state.subreddits, subreddit_id) {
            False -> {
              process.send(
                reply_to,
                Error("SubReddit does not exist: " <> subreddit_id),
              )
              io.println("Error: SubReddit does not exist: " <> subreddit_id)
              actor.continue(state)
            }
            True -> {
              let subreddit =
                result.unwrap(
                  dict.get(state.subreddits, subreddit_id),
                  SubReddit("", "", [], []),
                )
              case subreddit.posts {
                [] -> {
                  process.send(
                    reply_to,
                    Error("No posts in SubReddit: " <> subreddit_id),
                  )
                  io.println("Error: No posts in SubReddit: " <> subreddit_id)
                  actor.continue(state)
                }
                _ -> {
                  // Get a random post to downvote
                  let post_id = int.random(list.length(subreddit.posts))
                  let posts =
                    list.index_map(subreddit.posts, fn(p, i) {
                      case i == post_id {
                        True -> {
                          let account =
                            result.unwrap(
                              dict.get(state.accounts, user_id),
                              Account("", "", 0, [], dict.new()),
                            )
                          let updated_account =
                            Account(
                              account.username,
                              account.password,
                              account.karma - 1,
                              account.subscriptions,
                              account.inbox,
                            )
                          actor.send(
                            state.engine_subject,
                            UpdateAccount(updated_account),
                          )
                          Post(
                            user_id,
                            p.content,
                            p.timestamp,
                            p.upvotes,
                            p.downvotes + 1,
                            p.comments,
                          )
                        }
                        False -> {
                          p
                        }
                      }
                    })
                  let updated_subreddit =
                    SubReddit(
                      subreddit.name,
                      subreddit.description,
                      subreddit.members,
                      posts,
                    )
                  let updated_post =
                    list.drop(posts, post_id)
                    |> list.first
                    |> result.unwrap(
                      Post("", "", timestamp.system_time(), 0, 0, []),
                    )
                  process.send(
                    reply_to,
                    Ok(json_formatter.post_to_json(updated_post)),
                  )
                  io.println("JSON Response: " <> json_formatter.post_to_json(updated_post))
                  actor.continue(RedditEngineState(
                    state.accounts,
                    dict.insert(
                      state.subreddits,
                      subreddit_id,
                      updated_subreddit,
                    ),
                    state.num_posts,
                    state.num_comments,
                    state.num_messages,
                    state.num_upvotes,
                    state.num_downvotes + 1,
                    state.engine_subject,
                    state.simulator_subject,
                  ))
                }
              }
            }
          }
        }
      }
    }

    SendMessage(reply_to, sender_id, receiver_id, message) -> {
      case
        dict.has_key(state.accounts, sender_id)
        && dict.has_key(state.accounts, receiver_id)
        && order.to_int(string.compare(sender_id, receiver_id)) != 0
      {
        False -> {
          process.send(
            reply_to,
            Error(
              "Invalid sender or receiver ID: "
              <> sender_id
              <> ", "
              <> receiver_id,
            ),
          )
          io.println(
            "Error: Invalid sender or receiver ID: "
            <> sender_id
            <> ", "
            <> receiver_id,
          )
          actor.continue(state)
        }
        True -> {
          let message =
            DirectMessage(
              sender_id,
              receiver_id,
              message,
              timestamp.system_time(),
            )
          let receiver_account =
            result.unwrap(
              dict.get(state.accounts, receiver_id),
              Account("", "", 0, [], dict.new()),
            )
          let messages =
            result.unwrap(dict.get(receiver_account.inbox, sender_id), [])
          let updated_messages = list.append(messages, [message])
          let updated_receiver_account =
            Account(
              receiver_account.username,
              receiver_account.password,
              receiver_account.karma,
              receiver_account.subscriptions,
              dict.insert(receiver_account.inbox, sender_id, updated_messages),
            )
          process.send(
            reply_to,
            Ok(json_formatter.direct_message_to_json(message)),
          )
          io.println("JSON Response: " <> json_formatter.direct_message_to_json(message))
          actor.continue(RedditEngineState(
            dict.insert(
              state.accounts,
              updated_receiver_account.username,
              updated_receiver_account,
            ),
            state.subreddits,
            state.num_posts,
            state.num_comments,
            state.num_messages + 1,
            state.num_upvotes,
            state.num_downvotes,
            state.engine_subject,
            state.simulator_subject,
          ))
        }
      }
    }

    CreateCommentReply(reply_to, user_id, subreddit_id, reply) -> {
      case dict.has_key(state.accounts, user_id) {
        False -> {
          process.send(reply_to, Error("User does not exist: " <> user_id))
          io.println("Error: User does not exist: " <> user_id)
          actor.continue(state)
        }
        True -> {
          case dict.has_key(state.subreddits, subreddit_id) {
            False -> {
              process.send(
                reply_to,
                Error("SubReddit does not exist: " <> subreddit_id),
              )
              io.println("Error: SubReddit does not exist: " <> subreddit_id)
              actor.continue(state)
            }
            True -> {
              let subreddit =
                result.unwrap(
                  dict.get(state.subreddits, subreddit_id),
                  SubReddit("", "", [], []),
                )
              case subreddit.posts {
                [] -> {
                  process.send(
                    reply_to,
                    Error("No posts in SubReddit: " <> subreddit_id),
                  )
                  io.println("Error: No posts in SubReddit: " <> subreddit_id)
                  actor.continue(state)
                }
                _ -> {
                  // Get a random post to comment on
                  let post_id = int.random(list.length(subreddit.posts))

                  let post =
                    list.drop(subreddit.posts, post_id)
                    |> list.first
                    |> result.unwrap(
                      Post("", "", timestamp.system_time(), 0, 0, []),
                    )

                  let comment_id = int.random(list.length(post.comments))
                  let posts =
                    list.index_map(subreddit.posts, fn(p, i) {
                      case i == post_id {
                        True -> {
                          //Get a random comment to reply to
                          // let comment_id = int.random(list.length(p.comments))
                          let comments =
                            list.index_map(p.comments, fn(comment, id) {
                              case id == comment_id {
                                True -> {
                                  let comment_reply =
                                    types.Comment(
                                      user_id,
                                      reply,
                                      timestamp.system_time(),
                                      0,
                                      0,
                                      [],
                                    )
                                  Comment(
                                    comment.author,
                                    comment.content,
                                    comment.timestamp,
                                    comment.upvotes,
                                    comment.downvotes,
                                    list.append(comment.replies, [comment_reply]),
                                  )
                                }
                                False -> {
                                  comment
                                }
                              }
                            })
                          Post(
                            p.author,
                            p.content,
                            p.timestamp,
                            p.upvotes,
                            p.downvotes,
                            comments,
                          )
                        }
                        False -> {
                          p
                        }
                      }
                    })
                  let updated_subreddit =
                    SubReddit(
                      subreddit.name,
                      subreddit.description,
                      subreddit.members,
                      posts,
                    )

                  let updated_post =
                    list.drop(posts, post_id)
                    |> list.first
                    |> result.unwrap(
                      Post("", "", timestamp.system_time(), 0, 0, []),
                    )
                  let updated_comment =
                    list.drop(updated_post.comments, comment_id)
                    |> list.first
                    |> result.unwrap(
                      Comment("", "", timestamp.system_time(), 0, 0, []),
                    )
                  process.send(
                    reply_to,
                    Ok(json_formatter.comment_to_json(updated_comment)),
                  )
                  io.println("JSON Response: " <> json_formatter.comment_to_json(updated_comment))
                  actor.continue(RedditEngineState(
                    state.accounts,
                    dict.insert(
                      state.subreddits,
                      subreddit_id,
                      updated_subreddit,
                    ),
                    state.num_posts,
                    state.num_comments,
                    state.num_messages,
                    state.num_upvotes,
                    state.num_downvotes,
                    state.engine_subject,
                    state.simulator_subject,
                  ))
                }
              }
            }
          }
        }
      }
    }

    GetFeed(reply_to, user_id) -> {
      case dict.has_key(state.accounts, user_id) {
        False -> {
          process.send(
            reply_to,
            Error("User " <> user_id <> " does not exist."),
          )
          io.println("Error: User " <> user_id <> " does not exist.")
          actor.continue(state)
        }
        True -> {
          let account =
            result.unwrap(
              dict.get(state.accounts, user_id),
              Account("", "", 0, [], dict.new()),
            )
          let posts =
            list.flat_map(account.subscriptions, fn(subreddit) {
              list.map(subreddit.posts, fn(post) { post })
            })
          process.send(reply_to, Ok(json_formatter.posts_to_json(posts)))
          io.println("JSON Response: " <> json_formatter.posts_to_json(posts))
          actor.continue(state)
        }
      }
    }

    GetDirectMessages(reply_to, user_id) -> {
      case dict.has_key(state.accounts, user_id) {
        False -> {
          process.send(
            reply_to,
            Error("User " <> user_id <> " does not exist."),
          )
          io.println("Error: User " <> user_id <> " does not exist.")
          actor.continue(state)
        }
        True -> {
          let account =
            result.unwrap(
              dict.get(state.accounts, user_id),
              Account("", "", 0, [], dict.new()),
            )
          let inbox = account.inbox
          list.each(dict.to_list(inbox), fn(tuple) {
            let #(sender_id, messages) = tuple
            list.each(messages, fn(msg) {
              io.println("Sender: " <> sender_id <> " Message: " <> msg.content)
            })
          })

          // let messages = list.map(dict.values(inbox), fn(msgs) { msgs })
          process.send(reply_to, Ok(json_formatter.inbox_to_json(inbox)))
          io.println("JSON Response: " <> json_formatter.inbox_to_json(inbox))
          actor.continue(state)
        }
      }
    }

    PrintStats -> {
      io.println("Reddit Engine Statistics:")
      io.println("Total Accounts: " <> int.to_string(dict.size(state.accounts)))
      io.println(
        "Total SubReddits: " <> int.to_string(dict.size(state.subreddits)),
      )
      io.println("Total Posts: " <> int.to_string(state.num_posts))
      io.println("Total Comments: " <> int.to_string(state.num_comments))
      io.println("Total Messages: " <> int.to_string(state.num_messages))
      io.println("Total Upvotes: " <> int.to_string(state.num_upvotes))
      io.println("Total Downvotes: " <> int.to_string(state.num_downvotes))
      process.sleep(3000)
      actor.stop()
    }
  }
}
