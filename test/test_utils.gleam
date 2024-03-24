import gleam/dynamic.{dynamic}
import sqlight

pub fn setup_test_db(f: fn(sqlight.Connection) -> Nil) -> Nil {
  sqlight.with_connection(":memory:", f)
}

pub fn create_table(conn: sqlight.Connection) -> Nil {
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

pub fn insert_data(conn, date: String, start_hour: Int, end_hour: Int) -> Nil {
  let sql =
    "INSERT INTO work_schedules (date, start_hour, end_hour) VALUES (?, ?, ?)"

  query_dynamic_data(
    sql,
    [sqlight.text(date), sqlight.int(start_hour), sqlight.int(end_hour)],
    conn,
  )

  Nil
}

pub fn query_dynamic_data(
  sql: String,
  data: List(sqlight.Value),
  conn: sqlight.Connection,
) {
  let assert Ok(result) = sqlight.query(sql, conn, data, dynamic)
  result
}

pub fn query_data(
  sql: String,
  data: List(sqlight.Value),
  conn: sqlight.Connection,
) {
  let assert Ok(result) =
    sqlight.query(
      sql,
      conn,
      data,
      dynamic.tuple3(dynamic.string, dynamic.int, dynamic.int),
    )
  result
}
