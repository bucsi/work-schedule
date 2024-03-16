pub type Record {
  Day(date: String, from: Int, to: Int)
}

pub fn from_tuple(tuple: #(String, Int, Int)) -> Record {
  Day(date: tuple.0, from: tuple.1, to: tuple.2)
}
