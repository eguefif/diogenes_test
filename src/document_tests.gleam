import diogenes.{MeilisearchResults}
import diogenes/document
import diogenes/index
import diogenes/sansio/document as sansio_document
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/string

pub type Movie {
  Movie(id: Int, title: String, year: Int, genres: List(String))
}

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

pub fn run(client) {
  setup(client)
  test_add_or_replace_documents(client)
  test_list_documents_with_get(client)
  test_list_documents_with_pagination(client)
  test_list_documents_with_fields_filter(client)
  teardown(client)
}

fn test_add_or_replace_documents(client) {
  io.println("Testing add or replace documents...")
  let movies = [
    Movie(id: 1, title: "Inception", year: 2010, genres: ["Sci-Fi", "Thriller"]),
    Movie(id: 2, title: "The Dark Knight", year: 2008, genres: ["Action", "Crime"]),
    Movie(id: 3, title: "Interstellar", year: 2014, genres: ["Sci-Fi", "Drama"]),
  ]
  let assert Ok(_) =
    document.add_or_replace_documents(client, "movies", movies, movie_encoder)
  process.sleep(1000)
  io.println("Add or replace documents test passed")
}

fn test_list_documents_with_get(client) {
  io.println("Testing list documents with get...")
  let params = document.default_list_documents_params()
  let assert Ok(MeilisearchResults(results: docs, total:, ..)) =
    document.list_documents_with_get(client, "movies", params, movie_decoder())
  assert total == 3
  assert list.length(docs) == 3
  list.each(docs, fn(doc) {
    let assert Movie(..) = doc
  })
  io.println("List documents with get test passed")
}

fn test_list_documents_with_pagination(client) {
  io.println("Testing list documents with pagination...")
  let params =
    sansio_document.ListDocumentsParams(
      offset: 0,
      limit: 2,
      fields: [],
      retrieve_vectors: False,
      ids: [],
      filter: "",
      sort: "",
    )
  let assert Ok(MeilisearchResults(results: first_page, total:, ..)) =
    document.list_documents_with_get(client, "movies", params, movie_decoder())
  assert total == 3
  assert list.length(first_page) == 2

  let params2 =
    sansio_document.ListDocumentsParams(
      offset: 2,
      limit: 2,
      fields: [],
      retrieve_vectors: False,
      ids: [],
      filter: "",
      sort: "",
    )
  let assert Ok(MeilisearchResults(results: second_page, ..)) =
    document.list_documents_with_get(client, "movies", params2, movie_decoder())
  assert list.length(second_page) == 1

  let first_ids = list.map(first_page, fn(m) { m.id })
  let second_ids = list.map(second_page, fn(m) { m.id })
  assert list.all(second_ids, fn(id) { !list.contains(first_ids, id) })
  io.println("List documents with pagination test passed")
}

fn test_list_documents_with_fields_filter(client) {
  io.println("Testing list documents with fields filter...")
  let title_decoder = {
    use title <- decode.field("title", decode.string)
    decode.success(title)
  }
  let params =
    sansio_document.ListDocumentsParams(
      offset: 0,
      limit: 20,
      fields: ["title"],
      retrieve_vectors: False,
      ids: [],
      filter: "",
      sort: "",
    )
  let assert Ok(MeilisearchResults(results: titles, ..)) =
    document.list_documents_with_get(client, "movies", params, title_decoder)
  assert list.length(titles) == 3
  assert list.all(titles, fn(t) { string.length(t) > 0 })
  io.println("List documents with fields filter test passed")
}
