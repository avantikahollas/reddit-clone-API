import argv
import engine.{RedditEngineState}
import gleam/dict
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/otp/actor
import message.{Start}
import mist
import router
import simulator.{SimulatorState}
import wisp
import wisp/wisp_mist

pub fn main() -> Nil {
  wisp.configure_logger()

  case argv.load().arguments {
    [num_users_str, num_subreddits_str, simulation_time_str] -> {
      case
        int.parse(num_users_str),
        int.parse(num_subreddits_str),
        int.parse(simulation_time_str)
      {
        Ok(num_users), Ok(num_subreddits), Ok(simulation_time) -> {
          io.println(
            "Starting simulation with "
            <> int.to_string(num_users)
            <> " users and "
            <> int.to_string(num_subreddits)
            <> " subreddits for "
            <> int.to_string(simulation_time)
            <> " seconds.",
          )
          let simulator_state =
            SimulatorState(
              num_users,
              num_subreddits,
              simulation_time,
              process.new_subject(),
            )

          let assert Ok(simulator_actor) =
            actor.new(simulator_state)
            |> actor.on_message(simulator.handle)
            |> actor.start()
          let simulator_subject = simulator_actor.data

          let reddit_engine_state =
            RedditEngineState(
              dict.new(),
              dict.new(),
              0,
              0,
              0,
              0,
              0,
              process.new_subject(),
              simulator_subject,
            )

          let engine_name = process.new_name("RedditEngine")
          let assert Ok(reddit_engine_actor) =
            actor.new(reddit_engine_state)
            |> actor.on_message(engine.handle)
            |> actor.named(engine_name)
            |> actor.start()

          let reddit_engine_subject = reddit_engine_actor.data
          let secret_key_base = wisp.random_string(64)
          let assert Ok(_) =
            wisp_mist.handler(
              fn(req) { router.handle_request(req, reddit_engine_subject) },
              secret_key_base,
            )
            |> mist.new
            |> mist.port(8000)
            |> mist.start

          actor.send(
            simulator_subject,
            Start(
              num_users,
              num_subreddits,
              simulation_time,
              simulator_subject,
              reddit_engine_subject,
              reddit_engine_actor.pid,
            ),
          )
          wait(simulator_actor.pid)
        }
        _, _, _ ->
          io.println(
            "Error: both arguments must be integers. Usage: program <num_users> <num_subreddits>, <simulation_time>",
          )
      }
    }
    _ ->
      io.println(
        "Usage: program <num_users> <num_subreddits>, <simulation_time>",
      )
  }
}

pub fn wait(process_pid: process.Pid) -> Nil {
  case process.is_alive(process_pid) {
    True -> {
      // Avoid busy-waiting; yield to the scheduler briefly
      process.sleep(1000)
      wait(process_pid)
    }
    False -> {
      io.println("Exiting program.")
    }
  }
}
