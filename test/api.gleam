import work_schedule/router
import work_schedule/web.{type Context, Context}
import birdie
import gleeunit/should
import wisp/testing
import work_schedule/internal/dao
import work_schedule/internal/schedule
import sqlight

fn mock_dao() -> dao.Dao {
  dao.Dao(
    get_between: fn(_a, _b) { Ok([schedule.Day("asdd", 1, 2)]) },
    save: fn(_a, _b, _c) { Ok(schedule.Day("asdd", 1, 2)) },
  )
}

fn mock_bad_dao() -> dao.Dao {
  let err = sqlight.SqlightError(sqlight.GenericError, "testing", 1)
  dao.Dao(
    get_between: fn(_a, _b) { Error(dao.DBError(err)) },
    save: fn(_a, _b, _c) { Error(err) },
  )
}

fn with_context(dao_mock: dao.Dao, testcase: fn(Context) -> t) -> t {
  let context = Context(dao_mock)
  testcase(context)
}

pub fn list__no__from_queryparam__retuns_err__test() {
  use ctx <- with_context(mock_dao())
  let request = testing.get("/list?to=irrelevant", [])
  let response = router.handle_request(request, ctx)

  response.status
  |> should.equal(400)

  response
  |> testing.string_body
  |> birdie.snap(
    "API tests / list / client error / Missing query parameter `from`",
  )
}

pub fn list__no__to_queryparam__retuns_err__test() {
  use ctx <- with_context(mock_dao())
  let request = testing.get("/list?from=irrelevant", [])
  let response = router.handle_request(request, ctx)

  response.status
  |> should.equal(400)

  response
  |> testing.string_body
  |> birdie.snap(
    "API tests / list / client error / Missing query parameter `to`",
  )
}

pub fn list__query_ok__retuns_ddb_result__test() {
  use ctx <- with_context(mock_dao())
  let request = testing.get("/list?from=irrelevant&to=irrelevant", [])
  let response = router.handle_request(request, ctx)

  response.status
  |> should.equal(200)

  response
  |> testing.string_body
  |> birdie.snap("API tests / list / OK")
}

pub fn list__db_error__retuns_internal_server_error__test() {
  use ctx <- with_context(mock_bad_dao())
  let request = testing.get("/list?from=irrelevant&to=irrelevant", [])
  let response = router.handle_request(request, ctx)

  response.status
  |> should.equal(500)

  response
  |> testing.string_body
  |> birdie.snap("API tests / list / internal server error, no response")
}
