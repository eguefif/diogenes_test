import diogenes.{new_client}
import diogenes/health
import document_tests
import gleam/option
import log

//import index_tests

pub fn main() {
  let client =
    new_client("http://127.0.0.1:7700", option.Some("123456789123456789"))

  log.section("Health")
  log.running("Get health")
  let assert Ok(_) = health.get_health(client)
  log.pass("Get health")

  //index_tests.run(client)
  document_tests.run(client)
}
