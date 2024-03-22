import work_schedule/web.{type Context}
import work_schedule/internal/dao
import gleam/dynamic.{type Dynamic}
import gleam/http.{Get, Post}
import gleam/json
import gleam/string
import gleam/result.{try}
import wisp.{type Request, type Response}

pub fn get_all_data(req: Request, ctx: Context) -> Response {
  // Dispatch to the appropriate handler based on the HTTP method.
  case req.method {
    Get -> list(ctx)
    _ -> wisp.method_not_allowed([Get])
  }
}

fn handle_error_gracefully(
  message: String,
  error: error,
  return_instead: a,
) -> a {
  wisp.log_error(message <> string.inspect(error))
  return_instead
}

fn list(ctx: Context) -> Response {
  let rows = case dao.get(ctx.db, "%") {
    Ok(rows) -> rows
    Error(err) ->
      handle_error_gracefully("`controller.list` DB error: ", err, [])
  }

  let json =
    json.array(rows, fn(row) {
      json.object([
        #("date", json.string(row.date)),
        #("from", json.int(row.from)),
        #("to", json.int(row.to)),
      ])
    })
    |> json.to_string_builder()

  wisp.json_response(json, 200)
}
