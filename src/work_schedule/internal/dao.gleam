import work_schedule/internal/schedule
import gleam/dynamic
import gleam/result
import sqlight

pub type Err {
  DBError(sqlight.Error)
  NoResult
}

pub type Dao {
  Dao(
    get_between: fn(String, String) -> Result(List(schedule.Record), Err),
    save: fn(String, Int, Int) -> Result(schedule.Record, sqlight.Error),
    get_all: fn() -> Result(List(schedule.Record), sqlight.Error),
  )
}

pub fn new(db: sqlight.Connection) -> Dao {
  Dao(
    fn(from, to) { get_between(db, from, to) },
    fn(date, start, end) { save(db, date, start, end) },
    fn() { get(db, "%") },
  )
}

pub fn get(
  conn: sqlight.Connection,
  like_date: String,
) -> Result(List(schedule.Record), sqlight.Error) {
  let sql =
    "select *
    from work_schedules
    where date like ?;
  "

  sqlight.query(
    sql,
    on: conn,
    with: [sqlight.text(like_date)],
    expecting: get_row_decoder(),
  )
  |> result.map(schedule.from_list_of_tuple)
}

pub fn get_between(
  conn: sqlight.Connection,
  after_date: String,
  before_date: String,
) -> Result(List(schedule.Record), Err) {
  let sql =
    "select *
    from work_schedules
    where ? <= date and date <= ?;
  "
  sqlight.query(
    sql,
    on: conn,
    with: [sqlight.text(after_date), sqlight.text(before_date)],
    expecting: get_row_decoder(),
  )
  |> result.map(schedule.from_list_of_tuple)
  |> result.map_error(fn(e) { DBError(e) })
}

pub fn save(
  conn: sqlight.Connection,
  date: String,
  from: Int,
  to: Int,
) -> Result(schedule.Record, sqlight.Error) {
  case get_one_row(conn, date) {
    Ok(_) -> update(conn, date, from, to)
    Error(NoResult) -> insert(conn, date, from, to)
    Error(DBError(e)) -> Error(e)
  }
}

fn update(conn, date, from, to) {
  let sql =
    "update work_schedules set start_hour = ?, end_hour = ? where date = ?;"
  sqlight.query(
    sql,
    on: conn,
    with: [sqlight.int(from), sqlight.int(to), sqlight.text(date)],
    expecting: dynamic.dynamic,
  )
  |> result.replace(schedule.Day(date, from, to))
}

fn insert(
  conn: sqlight.Connection,
  date: String,
  from: Int,
  to: Int,
) -> Result(schedule.Record, sqlight.Error) {
  let sql =
    "insert into work_schedules (date, start_hour, end_hour) values (?, ?, ?);"
  sqlight.query(
    sql,
    on: conn,
    with: [sqlight.text(date), sqlight.int(from), sqlight.int(to)],
    expecting: dynamic.dynamic,
  )
  |> result.replace(schedule.Day(date, from, to))
}

pub fn get_row_decoder() {
  dynamic.tuple3(dynamic.string, dynamic.int, dynamic.int)
}

fn get_one_row(
  conn: sqlight.Connection,
  key: String,
) -> Result(schedule.Record, Err) {
  let sql =
    "select *
    from work_schedules
    where date = ?;
  "
  let query_result =
    sqlight.query(
      sql,
      on: conn,
      with: [sqlight.text(key)],
      expecting: get_row_decoder(),
    )

  case query_result {
    Ok([]) -> Error(NoResult)
    Error(e) -> Error(DBError(e))
    Ok(result) -> {
      let assert [res] = result
      Ok(schedule.from_tuple(res))
    }
  }
}
