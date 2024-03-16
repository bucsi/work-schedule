import work_schedule/internal/dao
import gleam/io
import sqlight

pub fn main() {
  use conn <- sqlight.with_connection("file:work_schedule.sqlite")
  io.debug(dao.save(conn, "2024-01-01", 10, 2))
}
