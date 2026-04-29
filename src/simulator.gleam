import client.{ClientState}
import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/otp/actor
import gleam/result
import gleam/time/duration
import gleam/time/timestamp
import message.{
  type ClientMsg, type SimulatorMsg, CreateAccount, CreateCommentClient,
  CreatePostClient, CreateSubRedditClient, DownvotePostClient,
  GetDirectMessagesClient, GetFeedClient, Init, Initialize, JoinSubRedditClient,
  LeaveSubRedditClient, SendMessageClient, Start, UpvotePostClient,
}

pub type SimulatorState {
  SimulatorState(
    num_users: Int,
    num_subreddits: Int,
    simulation_time: Int,
    simulator_subject: Subject(SimulatorMsg),
  )
}

pub fn handle(
  _state: SimulatorState,
  message: SimulatorMsg,
) -> actor.Next(SimulatorState, SimulatorMsg) {
  case message {
    Start(
      num_users,
      num_subreddits,
      simulation_time,
      simulator_subject,
      reddit_engine_subject,
      reddit_engine_pid,
    ) -> {
      actor.send(
        reddit_engine_subject,
        Init(reddit_engine_subject, simulator_subject),
      )

      //Create clients, initialize them, and create accounts
      let client_list =
        list.range(0, num_users - 1)
        |> list.index_map(fn(_x, i) {
          let client_state =
            ClientState(
              "user" <> int.to_string(i),
              "password" <> int.to_string(i),
              process.new_subject(),
              reddit_engine_subject,
            )
          let assert Ok(client_actor) =
            actor.new(client_state)
            |> actor.on_message(client.handle)
            |> actor.start()
          let client_subject = client_actor.data
          actor.send(
            client_subject,
            Initialize(client_subject, reddit_engine_subject),
          )
          actor.send(
            client_subject,
            CreateAccount(
              "user" <> int.to_string(i),
              "password" <> int.to_string(i),
            ),
          )
          #(client_state.username, client_subject)
        })
      let client_dict = dict.from_list(client_list)

      let user_id = int.random(num_users)
      let user_subject =
        result.unwrap(
          dict.get(client_dict, "user" <> int.to_string(user_id)),
          process.new_subject(),
        )

      // Create subreddits
      list.range(0, num_subreddits - 1)
      |> list.each(fn(i) {
        actor.send(
          user_subject,
          CreateSubRedditClient(
            "subreddit" <> int.to_string(i),
            "Description for subreddit" <> int.to_string(i),
          ),
        )
      })

      io.println(
        "Simulating user activities for "
        <> int.to_string(simulation_time)
        <> " seconds...",
      )
      let current_time = timestamp.system_time()
      let simulation_end_time =
        timestamp.add(current_time, duration.seconds(simulation_time))

      simulate_activity(
        simulation_end_time,
        simulation_time,
        num_users,
        num_subreddits,
        client_dict,
        reddit_engine_pid,
      )
      actor.stop()
    }
  }
}

pub fn find_subreddit_by_weight(
  random_value: Int,
  weights: List(Int),
  current_subreddit: Int,
  cumulative_sum: Int,
) -> Int {
  case weights {
    [] -> current_subreddit - 1
    [first, ..rest] -> {
      let new_cumulative = cumulative_sum + first
      case random_value <= new_cumulative {
        True -> current_subreddit
        False ->
          find_subreddit_by_weight(
            random_value,
            rest,
            current_subreddit + 1,
            new_cumulative,
          )
      }
    }
  }
}

pub fn simulate_activity(
  simulation_end_time: timestamp.Timestamp,
  simulation_time: Int,
  num_users: Int,
  num_subreddits: Int,
  client_dict: Dict(String, Subject(ClientMsg)),
  reddit_engine_actor_pid: process.Pid,
) -> Nil {
  let current_time = timestamp.system_time()
  case timestamp.compare(current_time, simulation_end_time) {
    order.Lt -> {
      let activity = int.random(7)
      process.sleep(1)
      case activity {
        0 -> {
          // User joins a subreddit
          let user_id = int.random(num_users)
          let user_subject =
            result.unwrap(
              dict.get(client_dict, "user" <> int.to_string(user_id)),
              process.new_subject(),
            )
          let zipfian_weights =
            list.range(1, num_subreddits)
            |> list.map(fn(i) {
              float.round(int.to_float(num_users) /. int.to_float(i))
            })

          // Calculate cumulative sums for range boundaries
          let total_weight =
            list.fold(zipfian_weights, 0, fn(acc, w) { acc + w })

          // Generate random number between 1 and total_weight
          let random_value = int.random(total_weight) + 1

          // Find which subreddit this random value maps to
          let subreddit_id =
            find_subreddit_by_weight(random_value, zipfian_weights, 0, 0)

          actor.send(
            user_subject,
            JoinSubRedditClient("subreddit" <> int.to_string(subreddit_id)),
          )
        }
        1 -> {
          // User leaves a subreddit
          let user_id = int.random(num_users)
          let user_subject =
            result.unwrap(
              dict.get(client_dict, "user" <> int.to_string(user_id)),
              process.new_subject(),
            )
          let subreddit_id = int.random(num_subreddits)
          io.println(
            "User user "
            <> int.to_string(user_id)
            <> " leaving a subreddit "
            <> int.to_string(subreddit_id),
          )
          actor.send(
            user_subject,
            LeaveSubRedditClient("subreddit" <> int.to_string(subreddit_id)),
          )
        }
        2 -> {
          // User creates a post
          let user_id = int.random(num_users)
          let user_subject =
            result.unwrap(
              dict.get(client_dict, "user" <> int.to_string(user_id)),
              process.new_subject(),
            )
          //Pick a subreddit id from zipfian distribution
          let zipfian_weights =
            list.range(1, num_subreddits)
            |> list.map(fn(i) {
              float.round(int.to_float(num_users) /. int.to_float(i))
            })

          // Calculate cumulative sums for range boundaries
          let total_weight =
            list.fold(zipfian_weights, 0, fn(acc, w) { acc + w })

          // Generate random number between 1 and total_weight
          let random_value = int.random(total_weight) + 1

          // Find which subreddit this random value maps to
          let subreddit_id =
            find_subreddit_by_weight(random_value, zipfian_weights, 0, 0)
          io.println(
            "User user "
            <> int.to_string(user_id)
            <> " creating a post in subreddit "
            <> int.to_string(subreddit_id),
          )
          actor.send(
            user_subject,
            CreatePostClient(
              "subreddit" <> int.to_string(subreddit_id),
              "This is a post content by user" <> int.to_string(user_id),
            ),
          )
        }
        3 -> {
          // User creates a comment
          let user_id = int.random(num_users)
          let user_subject =
            result.unwrap(
              dict.get(client_dict, "user" <> int.to_string(user_id)),
              process.new_subject(),
            )
          let subreddit_id = int.random(num_subreddits)
          io.println(
            "User user "
            <> int.to_string(user_id)
            <> " creating a comment in subreddit "
            <> int.to_string(subreddit_id),
          )
          actor.send(
            user_subject,
            CreateCommentClient(
              "subreddit" <> int.to_string(subreddit_id),
              "This is a comment content by user" <> int.to_string(user_id),
            ),
          )
        }
        4 -> {
          // User upvotes a post
          let user_id = int.random(num_users)
          let user_subject =
            result.unwrap(
              dict.get(client_dict, "user" <> int.to_string(user_id)),
              process.new_subject(),
            )
          let subreddit_id = int.random(num_subreddits)
          io.println(
            "User user "
            <> int.to_string(user_id)
            <> " upvoting a post in subreddit "
            <> int.to_string(subreddit_id),
          )
          actor.send(
            user_subject,
            UpvotePostClient("subreddit" <> int.to_string(subreddit_id)),
          )
        }
        5 -> {
          //User downvotes a post
          let user_id = int.random(num_users)
          let user_subject =
            result.unwrap(
              dict.get(client_dict, "user" <> int.to_string(user_id)),
              process.new_subject(),
            )
          let subreddit_id = int.random(num_subreddits)
          io.println(
            "User user "
            <> int.to_string(user_id)
            <> " downvoting a post in subreddit "
            <> int.to_string(subreddit_id),
          )
          actor.send(
            user_subject,
            DownvotePostClient("subreddit" <> int.to_string(subreddit_id)),
          )
        }
        6 -> {
          //User sends a direct message
          let sender_id = int.random(num_users)
          let sender_subject =
            result.unwrap(
              dict.get(client_dict, "user" <> int.to_string(sender_id)),
              process.new_subject(),
            )
          let receiver_id = int.random(num_users)
          io.println(
            "User user "
            <> int.to_string(sender_id)
            <> " sending a message to User user "
            <> int.to_string(receiver_id),
          )
          actor.send(
            sender_subject,
            SendMessageClient("user" <> int.to_string(receiver_id), "MESSAGE"),
          )
        }
        7 -> {
          //User gets their feed 
          let user_id = int.random(num_users)
          let user_subject =
            result.unwrap(
              dict.get(client_dict, "user" <> int.to_string(user_id)),
              process.new_subject(),
            )
          io.println(
            "User user " <> int.to_string(user_id) <> " getting their feed.",
          )
          actor.send(user_subject, GetFeedClient)
        }
        8 -> {
          //User gets their direct messages 
          let user_id = int.random(num_users)
          let user_subject =
            result.unwrap(
              dict.get(client_dict, "user" <> int.to_string(user_id)),
              process.new_subject(),
            )
          io.println(
            "User user "
            <> int.to_string(user_id)
            <> " getting their direct messages.",
          )
          actor.send(user_subject, GetDirectMessagesClient)
        }
        _ -> io.println("No activity.")
      }
      // process.sleep(1) //probability

      simulate_activity(
        simulation_end_time,
        simulation_time,
        num_users,
        num_subreddits,
        client_dict,
        reddit_engine_actor_pid,
      )
    }
    _ -> {
      // actor.send(reddit_engine_subject, PrintStats)
      wait(reddit_engine_actor_pid, simulation_time)
    }
  }
}

pub fn wait(process_pid: process.Pid, simulation_time: Int) -> Nil {
  case process.is_alive(process_pid) {
    True -> {
      // Avoid busy-waiting; yield to the scheduler briefly
      process.sleep(1000)
      wait(process_pid, simulation_time)
    }
    False -> {
      io.println("Simulation time: " <> int.to_string(simulation_time))
      io.println("Simulation ended.")
    }
  }
}
