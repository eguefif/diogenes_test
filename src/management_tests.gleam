import diogenes/management
import log

pub fn run(client) {
  log.section("Management")
  test_health(client)
}

fn test_health(client) {
  log.running("Get health")
  let assert Ok(_) = management.get_health(client)
  log.pass("Get health")
}
