import work_schedule/web.{type Context}
import work_schedule/controller
import gleam/http.{Get}
import wisp.{type Request, type Response}

pub fn get_request(
  req: Request,
  ctx: Context,
  f: fn(Request, Context) -> Response,
) -> wisp.Response {
  case req.method {
    Get -> f(req, ctx)
    _ -> wisp.method_not_allowed([Get])
  }
}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req)
  case wisp.path_segments(req) {
    ["list"] -> get_request(req, ctx, controller.list)
    _ -> wisp.not_found()
  }
}
