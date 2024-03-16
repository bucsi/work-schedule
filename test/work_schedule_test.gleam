import work_schedule/internal/dao
import gleeunit
import gleeunit/should
import gleam/result
import gleam/dynamic.{dynamic}
import gleam/list
import sqlight

fn setup_test_db(f: fn(sqlight.Connection) -> _) -> Nil {
  use conn <- sqlight.with_connection(":memory:")
  f(conn)

  Nil
}

fn create_table(conn: sqlight.Connection) -> Nil {
  let sql =
    "CREATE TABLE work_schedules (
    date TEXT PRIMARY KEY CHECK (date LIKE '____-__-__'),
    start_hour INT DEFAULT 0 CHECK (start_hour BETWEEN 0 AND 24),
    end_hour INT DEFAULT 0 CHECK (end_hour BETWEEN 0 AND 24)
    );
  "

  let assert Ok(_) = sqlight.exec(sql, conn)
  Nil
}

fn insert_data(conn, date: String, start_hour: Int, end_hour: Int) -> Nil {
  let sql =
    "INSERT INTO work_schedules (date, start_hour, end_hour) VALUES (?, ?, ?)"

  query_dynamic_data(
    sql,
    [sqlight.text(date), sqlight.int(start_hour), sqlight.int(end_hour)],
    conn,
  )

  Nil
}

fn query_dynamic_data(
  sql: String,
  data: List(sqlight.Value),
  conn: sqlight.Connection,
) {
  let assert Ok(result) = sqlight.query(sql, conn, data, dynamic)
  result
}

fn query_data(sql: String, data: List(sqlight.Value), conn: sqlight.Connection) {
  let assert Ok(result) =
    sqlight.query(
      sql,
      conn,
      data,
      dynamic.tuple3(dynamic.string, dynamic.int, dynamic.int),
    )
  result
}

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn database_setup_and_decoder_test() {
  let expected = #("2021-01-01", 8, 16)
  use conn <- setup_test_db()
  create_table(conn)
  insert_data(conn, expected.0, expected.1, expected.2)

  query_dynamic_data("SELECT * FROM work_schedules", [], conn)
  |> list.map(dao.get_row_decoder())
  |> result.values
  |> list.each(fn(item) {
    item
    |> should.equal(expected)
  })
}

pub fn save__no_record_exists__inserts_new_record__test() {
  let expected = #("2021-01-01", 8, 16)
  use conn <- setup_test_db()
  create_table(conn)

  let assert Ok(_) = dao.save(conn, expected.0, expected.1, expected.2)

  query_data("SELECT * FROM work_schedules", [], conn)
  |> list.each(should.equal(_, expected))
}

pub fn save__record_exists__updates_existing_record__test() {
  let expected = #("2021-01-01", 8, 16)
  let initial = #(expected.0, 0, 0)
  use conn <- setup_test_db()
  create_table(conn)
  insert_data(conn, initial.0, initial.1, initial.2)

  let assert Ok(_) = dao.save(conn, expected.0, expected.1, expected.2)

  query_data("SELECT * FROM work_schedules", [], conn)
  |> list.each(should.equal(_, expected))
}
