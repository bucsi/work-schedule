import work_schedule/web.{type Context}
import work_schedule/internal/dao.{type Err as DaoError}
import work_schedule/internal/schedule
import gleam/json
import gleam/list
import gleam/result.{try}
import wisp.{type Request, type Response}

type Err {
  MissingQueryString(String)
  DaoError(DaoError)
}

fn query_param(params, key) -> Result(String, Err) {
  use item <- try(
    params
    |> list.filter(fn(item) { item.0 == key })
    |> list.first
    |> result.replace_error(MissingQueryString(key)),
  )

  Ok(item.1)
}

pub fn list(req: Request, ctx: Context) -> Response {
  let query_params = wisp.get_query(req)

  let result = {
    use from_date <- try(query_param(query_params, "from"))
    use to_date <- try(query_param(query_params, "to"))

    case dao.get_between(ctx.db, from_date, to_date) {
      Ok(schedules) -> {
        Ok(json.array(schedules, schedule.to_json))
      }
      Error(err) -> Error(DaoError(err))
    }
  }

  case result {
    Ok(json) -> web.respond_with_success(json)
    Error(DaoError(err)) -> web.respond_with_internal_error(err)
    Error(err) -> web.respond_with_error("Client error", err)
  }
}
