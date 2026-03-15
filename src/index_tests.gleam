import diogenes.{MeilisearchResults, MeilisearchSingleResult}
import diogenes/index
import diogenes/sansio/index as sansio_index
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import log

pub fn run(client) {
  log.section("Indexes")
  cleanup(client)
  test_list_index(client)
  test_create_index(client)
  test_get_index(client)
  test_swap_index(client)
  test_rename_with_swap(client)
  test_update_primary_key(client)
  test_update_uid(client)
  test_update_both(client)
  test_list_index_fields(client)
  test_delete_all_indexes(client)
  cleanup(client)
  test_list_index_pagination(client)
}

pub fn cleanup(client) {
  let assert Ok(MeilisearchResults(results:, ..)) =
    index.list_index(client, None, None)
  list.each(results, fn(idx: sansio_index.Index) {
    let assert sansio_index.Index(..) = idx
    let assert Ok(_) = index.delete_index(client, idx.uid)
  })
  process.sleep(1000)
}

fn test_list_index(client) {
  log.running("List indexes")
  let assert Ok(_) = index.list_index(client, None, None)
  log.pass("List indexes")
}

fn test_create_index(client) {
  log.running("Create index")
  let assert Ok(_) = index.create_index(client, "movies", Some("title"))
  process.sleep(1000)
  log.pass("Create index")
}

fn test_swap_index(client) {
  log.running("Swap indexes")
  let assert Ok(_) = index.create_index(client, "books", Some("author"))
  process.sleep(1000)

  let swap =
    sansio_index.IndexPairSwap(
      index_a: "movies",
      index_b: "books",
      rename: False,
    )
  let assert Ok(_) = index.swap_index(client, [swap])
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result: sansio_index.Index(
    uid: uid_movies,
    primary_key: pk_movies,
    ..,
  ))) = index.get_index(client, "movies")
  assert uid_movies == "movies"
  assert pk_movies == Some("author")

  let assert Ok(MeilisearchSingleResult(result: sansio_index.Index(
    uid: uid_books,
    primary_key: pk_books,
    ..,
  ))) = index.get_index(client, "books")
  assert uid_books == "books"
  assert pk_books == Some("title")

  log.pass("Swap indexes")
}

fn test_rename_with_swap(client) {
  log.running("Rename with swap")
  let assert Ok(_) = index.create_index(client, "swap_rename_a", Some("id_a"))
  let assert Ok(_) = index.create_index(client, "swap_rename_b", Some("id_b"))
  process.sleep(1000)

  let swap =
    sansio_index.IndexPairSwap(
      index_a: "swap_rename_a",
      index_b: "swap_rename_b",
      rename: True,
    )
  let assert Ok(_) = index.swap_index(client, [swap])
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result: sansio_index.Index(
    uid: uid_a,
    ..,
  ))) = index.get_index(client, "swap_rename_b")
  assert uid_a == "swap_rename_b"

  let assert Ok(MeilisearchSingleResult(result: sansio_index.Index(
    uid: uid_b,
    ..,
  ))) = index.get_index(client, "swap_rename_a")
  assert uid_b == "swap_rename_a"

  log.pass("Rename with swap")
}

fn test_get_index(client) {
  log.running("Get index")
  let assert Ok(MeilisearchSingleResult(result: sansio_index.Index(
    uid:,
    primary_key:,
    ..,
  ))) = index.get_index(client, "movies")
  assert uid == "movies"
  assert primary_key == Some("title")
  log.pass("Get index")
}

fn test_update_primary_key(client) {
  log.running("Update index primary key")
  let assert Ok(_) = index.create_index(client, "update_pk_test", Some("title"))
  process.sleep(1000)

  let assert Ok(_) =
    index.update_index(client, "update_pk_test", None, Some("id"))
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result: sansio_index.Index(
    uid:,
    primary_key:,
    ..,
  ))) = index.get_index(client, "update_pk_test")
  assert uid == "update_pk_test"
  assert primary_key == Some("id")
  log.pass("Update index primary key")
}

fn test_update_uid(client) {
  log.running("Update index uid")
  let assert Ok(_) =
    index.create_index(client, "update_uid_test", Some("title"))
  process.sleep(1000)

  let assert Ok(_) =
    index.update_index(
      client,
      "update_uid_test",
      Some("update_uid_renamed"),
      None,
    )
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result: sansio_index.Index(
    uid:,
    primary_key:,
    ..,
  ))) = index.get_index(client, "update_uid_renamed")
  assert uid == "update_uid_renamed"
  assert primary_key == Some("title")
  log.pass("Update index uid")
}

fn test_update_both(client) {
  log.running("Update index uid and primary key")
  let assert Ok(_) =
    index.create_index(client, "update_both_test", Some("title"))
  process.sleep(1000)

  let assert Ok(_) =
    index.update_index(
      client,
      "update_both_test",
      Some("update_both_renamed"),
      Some("id"),
    )
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result: sansio_index.Index(
    uid:,
    primary_key:,
    ..,
  ))) = index.get_index(client, "update_both_renamed")
  assert uid == "update_both_renamed"
  assert primary_key == Some("id")
  log.pass("Update index uid and primary key")
}

fn test_list_index_pagination(client) {
  log.running("List indexes with pagination")

  int.range(from: 0, to: 10, with: Nil, run: fn(_, i) {
    let uid = "pagination_index_" <> int.to_string(i)
    let assert Ok(_) = index.create_index(client, uid, None)
    Nil
  })
  process.sleep(1000)

  let assert Ok(MeilisearchResults(results: first_page, total:, ..)) =
    index.list_index(client, Some(0), Some(5))
  assert list.length(first_page) == 5
  assert total == 10

  let assert Ok(MeilisearchResults(results: second_page, limit:, offset:, ..)) =
    index.list_index(client, Some(5), Some(5))
  assert list.length(second_page) == 5
  assert offset == 5
  assert limit == 5

  let first_uids =
    list.map(first_page, fn(idx) {
      let assert sansio_index.Index(..) = idx
      idx.uid
    })
  let second_uids =
    list.map(second_page, fn(idx) {
      let assert sansio_index.Index(..) = idx
      idx.uid
    })
  assert list.all(second_uids, fn(uid) { !list.contains(first_uids, uid) })

  int.range(from: 0, to: 10, with: Nil, run: fn(_, i) {
    let uid = "pagination_index_" <> int.to_string(i)
    let assert Ok(_) = index.delete_index(client, uid)
    Nil
  })

  log.pass("List indexes with pagination")
}

fn test_list_index_fields(client) {
  log.running("List index fields")
  let filter =
    sansio_index.IndexListFieldsRequest(
      offset: 0,
      limit: 20,
      filter: sansio_index.IndexListFilters(
        attribute_patterns: [],
        displayed: True,
        searchable: True,
        sortable: True,
        distinct: True,
        filterable: True,
      ),
    )
  let assert Ok(MeilisearchResults(results: fields, ..)) =
    index.list_index_fields(client, "movies", filter)
  list.each(fields, fn(field) {
    let sansio_index.IndexField(..) = field
  })
  log.pass("List index fields")
}

fn test_delete_all_indexes(client) {
  log.running("Delete all indexes")
  let assert Ok(MeilisearchResults(results:, ..)) =
    index.list_index(client, None, None)
  list.each(results, fn(idx) {
    let assert sansio_index.Index(..) = idx
    let assert Ok(_) = index.delete_index(client, idx.uid)
  })
  log.pass("Delete all indexes")
}
