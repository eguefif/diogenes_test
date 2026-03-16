import diogenes.{MeilisearchResults, MeilisearchSingleResult}
import diogenes/document
import diogenes/index
import diogenes/sansio/document as sansio_document
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import log

pub type Movie {
  Movie(id: Int, title: String, year: Int, genres: List(String))
}

// Setup create a movies index
// primary_key is 'id'
pub fn run(client) {
  log.section("Documents")
  setup(client)
  test_add_or_replace_documents(client)
  test_add_or_replace_documents_with_primary_key(client)
  test_list_documents_with_get(client)
  test_list_documents_with_pagination(client)
  test_list_documents_with_fields_filter(client)
  test_list_documents_with_post(client)
  test_get_document(client)
  test_add_or_update_documents(client)
  test_add_or_update_documents_with_skip_creation(client)
  test_delete_documents_by_batch(client)
  // TODO: test_delete_documents_by_filter — requires filterable attributes configured via settings API
  test_delete_document(client)
  test_delete_all_documents(client)
  teardown(client)
}

fn test_add_or_replace_documents(client) {
  log.running("Add or replace documents")
  let movies = [
    Movie(id: 1, title: "Inception", year: 2010, genres: ["Sci-Fi", "Thriller"]),
    Movie(id: 2, title: "The Dark Knight", year: 2008, genres: [
      "Action",
      "Crime",
    ]),
    Movie(id: 3, title: "Interstellar", year: 2014, genres: ["Sci-Fi", "Drama"]),
  ]
  let params =
    sansio_document.AddDocumentsParams(
      primary_key: None,
      csv_delimiter: None,
      custom_metadata: None,
      skip_creation: None,
    )
  let assert Ok(_) =
    document.add_or_replace_documents(client, "movies", movies, params, movie_encoder)
  process.sleep(1000)
  log.pass("Add or replace documents")
}

fn test_add_or_replace_documents_with_primary_key(client) {
  log.running("Add or replace documents with primary key")
  let movies = [
    Movie(id: 4, title: "The Matrix", year: 1999, genres: ["Sci-Fi", "Action"]),
  ]
  let params =
    sansio_document.AddDocumentsParams(
      primary_key: Some("id"),
      csv_delimiter: None,
      custom_metadata: None,
      skip_creation: None,
    )
  let assert Ok(_) =
    document.add_or_replace_documents(client, "movies", movies, params, movie_encoder)
  process.sleep(1000)

  let get_params =
    sansio_document.GetDocumentParams(
      fields: sansio_document.All,
      retrieve_vectors: False,
    )
  let assert Ok(MeilisearchSingleResult(result: movie)) =
    document.get_document(client, "movies", "4", get_params, movie_decoder())
  assert movie.id == 4
  assert movie.title == "The Matrix"

  // Clean up extra document so subsequent tests expect 3 documents
  let assert Ok(_) = document.delete_document(client, "movies", "4")
  process.sleep(1000)
  log.pass("Add or replace documents with primary key")
}

fn test_list_documents_with_post(client) {
  log.running("List documents with post")
  let params = document.default_list_documents_params()
  let assert Ok(MeilisearchResults(results: docs, total:, ..)) =
    document.list_documents_with_post(client, "movies", params, movie_decoder())
  assert list.length(docs) == 3
  assert total == 3
  list.each(docs, fn(doc) {
    let Movie(..) = doc
  })
  log.pass("List documents with post")
}

fn test_get_document(client) {
  log.running("Get document")
  let params =
    sansio_document.GetDocumentParams(
      fields: sansio_document.All,
      retrieve_vectors: False,
    )
  let assert Ok(MeilisearchSingleResult(result: movie)) =
    document.get_document(client, "movies", "1", params, movie_decoder())
  assert movie.id == 1
  assert movie.title == "Inception"
  log.pass("Get document")
}

fn test_add_or_update_documents(client) {
  log.running("Add or update documents")
  let params =
    sansio_document.GetDocumentParams(
      fields: sansio_document.All,
      retrieve_vectors: False,
    )

  let assert Ok(MeilisearchSingleResult(result: before)) =
    document.get_document(client, "movies", "1", params, movie_decoder())

  let updated = [Movie(id: 1, title: "Inception", year: 1999, genres: ["Sci-Fi"])]
  let update_params =
    sansio_document.AddDocumentsParams(
      primary_key: None,
      csv_delimiter: None,
      custom_metadata: None,
      skip_creation: None,
    )
  let assert Ok(_) =
    document.add_or_update_documents(
      client,
      "movies",
      updated,
      update_params,
      movie_encoder,
    )
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result: after)) =
    document.get_document(client, "movies", "1", params, movie_decoder())

  assert before.year != after.year
  assert after.year == 1999
  assert before.title == after.title
  log.pass("Add or update documents")
}

fn test_add_or_update_documents_with_skip_creation(client) {
  log.running("Add or update documents with skip creation")
  let get_params =
    sansio_document.GetDocumentParams(
      fields: sansio_document.All,
      retrieve_vectors: False,
    )

  // Pass both an existing document update (id: 1) and a new document (id: 99)
  // with skip_creation: True — existing should be updated, new should NOT be created
  let mixed = [
    Movie(id: 1, title: "Inception", year: 2001, genres: ["Sci-Fi"]),
    Movie(id: 99, title: "Ghost", year: 2000, genres: ["Drama"]),
  ]
  let params =
    sansio_document.AddDocumentsParams(
      primary_key: None,
      csv_delimiter: None,
      custom_metadata: None,
      skip_creation: Some(True),
    )
  let assert Ok(_) =
    document.add_or_update_documents(client, "movies", mixed, params, movie_encoder)
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result: updated)) =
    document.get_document(client, "movies", "1", get_params, movie_decoder())
  assert updated.year == 2001

  let list_params = document.default_list_documents_params()
  let assert Ok(MeilisearchResults(results: docs, total:, ..)) =
    document.list_documents_with_get(client, "movies", list_params, movie_decoder())
  assert total == 3
  assert list.all(docs, fn(doc) { doc.id != 99 })
  log.pass("Add or update documents with skip creation")
}

fn test_delete_documents_by_batch(client) {
  log.running("Delete documents by batch")
  let assert Ok(_) =
    document.delete_documents_by_batch(client, "movies", ["2", "3"])
  process.sleep(1000)

  let params = document.default_list_documents_params()
  let assert Ok(MeilisearchResults(results: docs, total:, ..)) =
    document.list_documents_with_get(client, "movies", params, movie_decoder())
  assert total == 1
  assert list.all(docs, fn(doc) { doc.id == 1 })

  // Re-add deleted movies for subsequent tests
  let movies = [
    Movie(id: 2, title: "The Dark Knight", year: 2008, genres: ["Action", "Crime"]),
    Movie(id: 3, title: "Interstellar", year: 2014, genres: ["Sci-Fi", "Drama"]),
  ]
  let add_params =
    sansio_document.AddDocumentsParams(
      primary_key: None,
      csv_delimiter: None,
      custom_metadata: None,
      skip_creation: None,
    )
  let assert Ok(_) =
    document.add_or_replace_documents(
      client,
      "movies",
      movies,
      add_params,
      movie_encoder,
    )
  process.sleep(1000)
  log.pass("Delete documents by batch")
}

fn test_delete_document(client) {
  log.running("Delete one document")
  let assert Ok(_) = document.delete_document(client, "movies", "2")
  process.sleep(1000)

  let params = document.default_list_documents_params()
  let assert Ok(MeilisearchResults(results: docs, total:, ..)) =
    document.list_documents_with_get(client, "movies", params, movie_decoder())
  assert total == 2
  assert list.length(docs) == 2
  assert list.all(docs, fn(doc) { doc.id != 2 })
  log.pass("Delete one document")
}

fn test_delete_all_documents(client) {
  log.running("Delete all documents")
  let assert Ok(_) = document.delete_all_documents(client, "movies")
  process.sleep(1000)

  let params = document.default_list_documents_params()
  let assert Ok(MeilisearchResults(results: docs, total:, ..)) =
    document.list_documents_with_get(client, "movies", params, movie_decoder())
  assert total == 0
  assert docs == []
  log.pass("Delete all documents")
}

fn test_list_documents_with_get(client) {
  log.running("List documents")
  let params = document.default_list_documents_params()
  let assert Ok(MeilisearchResults(results: docs, total:, ..)) =
    document.list_documents_with_get(client, "movies", params, movie_decoder())
  assert total == 3
  assert list.length(docs) == 3
  list.each(docs, fn(doc) {
    let Movie(..) = doc
  })
  log.pass("List documents")
}

fn test_list_documents_with_pagination(client) {
  log.running("List documents with pagination")
  let params =
    sansio_document.ListDocumentsParams(
      offset: 0,
      limit: 2,
      fields: sansio_document.All,
      retrieve_vectors: False,
      ids: None,
      filter: "",
      sort: [],
    )
  let assert Ok(MeilisearchResults(results: first_page, total:, ..)) =
    document.list_documents_with_get(client, "movies", params, movie_decoder())
  assert total == 3
  assert list.length(first_page) == 2

  let params2 =
    sansio_document.ListDocumentsParams(
      offset: 2,
      limit: 2,
      fields: sansio_document.All,
      retrieve_vectors: False,
      ids: None,
      filter: "",
      sort: [],
    )
  let assert Ok(MeilisearchResults(results: second_page, ..)) =
    document.list_documents_with_get(client, "movies", params2, movie_decoder())
  assert list.length(second_page) == 1

  let first_ids = list.map(first_page, fn(m) { m.id })
  let second_ids = list.map(second_page, fn(m) { m.id })
  assert list.all(second_ids, fn(id) { !list.contains(first_ids, id) })
  log.pass("List documents with pagination")
}

fn test_list_documents_with_fields_filter(client) {
  log.running("List documents with fields filter")
  let title_decoder = {
    use title <- decode.field("title", decode.string)
    use year <- decode.field("year", decode.int)
    decode.success(#(title, year))
  }
  let params =
    sansio_document.ListDocumentsParams(
      offset: 0,
      limit: 20,
      fields: sansio_document.Ids(["title", "year"]),
      retrieve_vectors: False,
      ids: None,
      filter: "",
      sort: [],
    )
  let assert Ok(MeilisearchResults(results: titles, ..)) =
    document.list_documents_with_get(client, "movies", params, title_decoder)
  log.running("result: " <> string.inspect(titles))
  assert list.length(titles) == 3
  assert list.all(titles, fn(row) { string.length(row.0) > 0 && row.1 > 0 })
  log.pass("List documents with fields filter")
}

// SETUP and ENCODER ------------------------------------------
pub fn movie_encoder(movie: Movie) -> json.Json {
  json.object([
    #("id", json.int(movie.id)),
    #("title", json.string(movie.title)),
    #("year", json.int(movie.year)),
    #("genres", json.array(movie.genres, json.string)),
  ])
}

pub fn movie_decoder() -> decode.Decoder(Movie) {
  use id <- decode.field("id", decode.int)
  use title <- decode.field("title", decode.string)
  use year <- decode.field("year", decode.int)
  use genres <- decode.field("genres", decode.list(decode.string))
  decode.success(Movie(id:, title:, year:, genres:))
}

fn setup(client) {
  let assert Ok(_) = index.create_index(client, "movies", Some("id"))
  process.sleep(1000)
}

fn teardown(client) {
  let assert Ok(_) = index.delete_index(client, "movies")
  process.sleep(1000)
}
