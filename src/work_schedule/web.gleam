import wisp.{type Request, type Response}
import sqlight
import gleam/json.{type Json}
import gleam/string

pub type Context {
  Context(db: sqlight.Connection)
}

pub fn middleware(
  req: Request,
  handle_request: fn(Request) -> Response,
) -> Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)

  handle_request(req)
}

pub type HttpStatus {
  Ok
  BadRequest
}

pub fn http_status_code(status: HttpStatus) -> Int {
  case status {
    Ok -> 200
    BadRequest -> 400
  }
}

pub fn respond_with_success(body: Json) -> Response {
  wrapped_response(True, body, Ok)
}

pub fn respond_with_error(message: String, error: error) -> Response {
  let error_string = string.inspect(error)
  wisp.log_error(message <> ": " <> error_string)
  let response =
    json.object([
      #("error", json.string(error_string)),
      #("message", json.string(message)),
    ])
  wrapped_response(False, response, BadRequest)
}

pub fn respond_with_internal_error(error: error) -> Response {
  wisp.log_error(string.inspect(error))
  wisp.internal_server_error()
}

fn wrapped_response(success: Bool, body: Json, code: HttpStatus) -> Response {
  json.object([#("success", json.bool(success)), #("data", body)])
  |> json.to_string_builder()
  |> wisp.json_response(http_status_code(code))
}
