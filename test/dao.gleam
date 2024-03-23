import work_schedule/internal/dao
import work_schedule/internal/schedule
import test_utils.{
  create_table, insert_data, query_data, query_dynamic_data, setup_test_db,
}
import gleeunit/should
import gleam/result
import gleam/list

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

pub fn get__no_record_exists__returns_empty_list__test() {
  use conn <- setup_test_db()
  create_table(conn)

  let assert Ok(result) = dao.get(conn, "")

  result
  |> should.equal([])
}

pub fn get__records_exists__returns_them__test() {
  let expected = [#("2021-01-01", 8, 16), #("2021-01-02", 8, 16)]
  use conn <- setup_test_db()
  create_table(conn)
  list.each(expected, fn(item) { insert_data(conn, item.0, item.1, item.2) })

  let assert Ok(result) = dao.get(conn, "2021-01%")

  result
  |> should.equal(list.map(expected, schedule.from_tuple))
}

pub fn get_between__records_exists__returns_them__test() {
  let expected = [#("2021-01-01", 8, 16), #("2021-01-02", 8, 16)]
  let not_expected = [#("2021-02-02", 8, 16), #("2021-02-03", 8, 16)]
  use conn <- setup_test_db()
  create_table(conn)
  list.each(list.append(expected, not_expected), fn(item) {
    insert_data(conn, item.0, item.1, item.2)
  })

  let assert Ok(result) = dao.get_between(conn, "2021-01-01", "2021-02-01")

  result
  |> should.equal(list.map(expected, schedule.from_tuple))
}
