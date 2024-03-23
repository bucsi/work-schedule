import gleam/erlang/process
import mist
import wisp
import sqlight
import work_schedule/router
import work_schedule/web
import work_schedule/internal/dao

pub const data_directory = "tmp/data"

pub fn main() {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  use conn <- sqlight.with_connection("file:work_schedule.sqlite")

  // A context is constructed to hold the database connection.
  let context = web.Context(dao.new(conn))

  // The handle_request function is partially applied with the context to make
  // the request handler function that only takes a request.
  let handler = router.handle_request(_, context)

  let assert Ok(_) =
    handler
    |> wisp.mist_handler(secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  process.sleep_forever()
}
