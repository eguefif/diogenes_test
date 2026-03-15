import diogenes.{new_client}
import diogenes/health
import gleam/io
import gleam/option
import index_tests

pub fn main() {
  let client =
    new_client("http://127.0.0.1:7700", option.Some("123456789123456789"))

  io.println("Testing health...")
  let assert Ok(_) = health.get_health(client)
  io.println("...Health works")

  index_tests.run(client)
  io.println("All test passes")
}
