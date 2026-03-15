import diogenes.{MeilisearchResults, MeilisearchSingleResult, new_client}
import diogenes/health
import diogenes/index
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/string

pub fn main() {
  let client =
    new_client("http://127.0.0.1:7700", option.Some("123456789123456789"))

  io.println("Testing health...")
  let assert Ok(_) = health.get_health(client)
  io.println("...Health works")

  cleanup(client)
  test_list_index(client)
  test_create_index(client)
  test_get_index(client)
  test_delete_all_indexes(client)
  cleanup(client)
  test_list_index_pagination(client)
  io.println("All test passes")
}

fn cleanup(client) {
  io.println("Cleaning up indexes...")
  let assert Ok(MeilisearchResults(results:, ..)) =
    index.list_index(client, None, None)
  list.each(results, fn(idx) {
    let assert Ok(_) = index.delete_index(client, idx.uid)
  })
  process.sleep(1000)
  io.println("Cleanup done")
}

fn test_list_index(client) {
  case index.list_index(client, None, None) {
    Ok(response) -> io.println("Ok: " <> string.inspect(response))
    Error(error) -> io.println("Error: " <> string.inspect(error))
  }
}

fn test_create_index(client) {
  io.println("Testing create index...")
  case index.create_index(client, "movies", Some("title")) {
    Ok(response) -> io.println("Ok: " <> string.inspect(response))
    Error(error) -> io.println("Error: " <> string.inspect(error))
  }
  process.sleep(1000)
}

fn test_get_index(client) {
  io.println("Testing get index...")
  let assert Ok(MeilisearchSingleResult(result: idx)) =
    index.get_index(client, "movies")
  assert idx.uid == "movies"
  assert idx.primary_key == Some("title")
  io.println("Get index test passed")
}

fn test_list_index_pagination(client) {
  io.println("Testing list index with pagination...")

  // Create 10 indexes
  int.range(from: 0, to: 10, with: Nil, run: fn(_, i) {
    let uid = "pagination_index_" <> int.to_string(i)
    io.println("Creating index: " <> string.inspect(uid))
    let assert Ok(_) = index.create_index(client, uid, None)
    Nil
  })

  process.sleep(1000)

  // List first 5 indexes (offset=0, limit=5)
  io.println("Listing with offset=0, limit=5...")
  let assert Ok(MeilisearchResults(results: first_page, total:, ..)) =
    index.list_index(client, Some(0), Some(5))
  io.println("Total indexes: " <> int.to_string(total))
  assert list.length(first_page) == 5
  assert total == 10

  // List next 5 indexes (offset=5, limit=5)
  io.println("Listing with offset=5, limit=5...")
  let assert Ok(MeilisearchResults(results: second_page, limit:, offset:, ..)) =
    index.list_index(client, Some(5), Some(5))
  assert list.length(second_page) == 5
  assert offset == 5
  assert limit == 5

  // Check no overlap between pages
  let first_uids = list.map(first_page, fn(idx) { idx.uid })
  let second_uids = list.map(second_page, fn(idx) { idx.uid })
  assert list.all(second_uids, fn(uid) { !list.contains(first_uids, uid) })

  // Delete the 10 indexes
  int.range(from: 0, to: 10, with: Nil, run: fn(_, i) {
    let uid = "pagination_index_" <> int.to_string(i)
    let assert Ok(_) = index.delete_index(client, uid)
    Nil
  })

  io.println("Pagination test passed")
}

fn test_delete_all_indexes(client) {
  io.println("Testing delete all indexes...")
  case index.list_index(client, None, None) {
    Error(error) ->
      io.println("Error listing indexes: " <> string.inspect(error))
    Ok(MeilisearchResults(results:, ..)) -> {
      list.each(results, fn(idx) {
        case index.delete_index(client, idx.uid) {
          Ok(_) -> io.println("Deleted index: " <> idx.uid)
          Error(error) ->
            io.println(
              "Error deleting " <> idx.uid <> ": " <> string.inspect(error),
            )
        }
      })
    }
    Ok(_) -> io.println("Unexpected response format")
  }
}
