import diogenes.{new_client}
import gleam/option
import individual_settings_tests
import management_tests

//import settings_tests
//import document_tests
//import index_tests

pub fn main() {
  let client =
    new_client("http://127.0.0.1:7700", option.Some("123456789123456789"))

  management_tests.run(client)
  //index_tests.run(client)
  //document_tests.run(client)
  //settings_tests.run(client)
  individual_settings_tests.run(client)
}
