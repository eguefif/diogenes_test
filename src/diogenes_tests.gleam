import diogenes.{new_client}
import diogenes/health
import diogenes/index
import gleam/io
import gleam/option.{None}
import gleam/string

pub fn main() {
  let client =
    new_client("http://127.0.0.1:7700", option.Some("123456789123456789"))

  io.println("Testing health...")
  let assert Ok(_) = health.get_health(client)
  io.println("...Health works")

  test_list_index(client)
}

fn test_list_index(client) {
  case index.list_index(client, None, None) {
    Ok(response) -> io.println("Ok: " <> string.inspect(response))
    Error(error) -> io.println("Error: " <> string.inspect(error))
  }
}
