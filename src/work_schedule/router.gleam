import work_schedule/web.{type Context}
import work_schedule/people
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req)

  // A new `work_schedule/web/people` module now contains the handlers and other functions
  // relating to the People feature of the application.
  //
  // The router module now only deals with routing, and dispatches to the
  // feature modules for handling requests.
  // 
  case wisp.path_segments(req) {
    ["people"] -> people.all(req, ctx)
    ["people", id] -> people.one(req, ctx, id)
    _ -> wisp.not_found()
  }
}
