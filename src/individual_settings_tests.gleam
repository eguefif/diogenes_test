import diogenes.{MeilisearchSingleResult}
import gleam/dict
import diogenes/index
import diogenes/sansio/settings as sansio_settings
import diogenes/settings
import gleam/erlang/process
import gleam/list
import gleam/option.{Some}
import gleam/string
import log

pub fn run(client) {
  log.section("Individual Settings")
  setup(client)
  //test_chat(client)
  //test_dictionary(client)
  //test_displayed_attributes(client)
  //test_filterable_attributes(client)
  //test_searchable_attributes(client)
  //test_sortable_attributes(client)
  //test_non_separator_tokens(client)
  //test_separator_tokens(client)
  //test_stop_words(client)
  //test_ranking_rules(client)
  //test_search_cutoff_ms(client)
  //test_facet_search(client)
  //test_distinct_attribute(client)
  test_synonyms(client)
  teardown(client)
}

fn test_chat(client) {
  test_update_chat(client)
  test_reset_chat(client)
}

fn test_update_chat(client) {
  log.running("Update chat settings")
  let chat =
    sansio_settings.Chat(
      description: "A movie database index",
      document_template: "Movie: {{doc.title}} ({{doc.year}})",
      document_template_max_bytes: 4096,
      search_parameters: sansio_settings.ChatSearchParameters(
        hybrid: sansio_settings.ChatEmbedder(
          embedder: "default",
          semantic_ratio: 1.0,
        ),
        limit: 5,
        sort: [],
        distinct: "",
        matching_strategy: sansio_settings.Last,
        attributes_to_search_on: [],
        ranking_score_threshold: option.None,
      ),
    )
  let assert Ok(_) =
    settings.update_chat(client, "individual_settings_test", chat)
  process.sleep(1000)

  log.running("Verify updated chat settings")
  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.get_chat(client, "individual_settings_test")
  assert result.description == "A movie database index"
  assert result.document_template == "Movie: {{doc.title}} ({{doc.year}})"
  assert result.document_template_max_bytes == 4096
  assert result.search_parameters.limit == 5
  assert result.search_parameters.hybrid.embedder == "default"
  assert result.search_parameters.hybrid.semantic_ratio == 1.0
  assert result.search_parameters.matching_strategy == sansio_settings.Last
  log.pass("Update chat settings")
}

fn test_reset_chat(client) {
  log.running("Reset chat settings")
  let assert Ok(_) = settings.reset_chat(client, "individual_settings_test")
  process.sleep(1000)
  log.pass("Reset chat settings")
}

fn test_dictionary(client) {
  test_update_dictionary(client)
  test_reset_dictionary(client)
}

fn test_update_dictionary(client) {
  log.running("Update dictionary")
  let assert Ok(_) =
    settings.update_dictionary(client, "individual_settings_test", [
      "shipit", "yolo", "brb",
    ])
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.get_dictionary(client, "individual_settings_test")
  assert list.sort(result, string.compare)
    == list.sort(["shipit", "yolo", "brb"], string.compare)
  log.pass("Update dictionary")
}

fn test_reset_dictionary(client) {
  log.running("Reset dictionary")
  let assert Ok(_) =
    settings.reset_dictionary(client, "individual_settings_test")
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.get_dictionary(client, "individual_settings_test")
  assert result == []
  log.pass("Reset dictionary")
}

fn test_displayed_attributes(client) {
  test_update_displayed_attributes(client)
  test_reset_displayed_attributes(client)
}

fn test_update_displayed_attributes(client) {
  log.running("Update displayed attributes")
  let assert Ok(_) =
    settings.update_displayed_attributes(client, "individual_settings_test", [
      "title", "overview", "year",
    ])
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.get_displayed_attributes(client, "individual_settings_test")
  assert list.sort(result, string.compare)
    == list.sort(["title", "overview", "year"], string.compare)
  log.pass("Update displayed attributes")
}

fn test_reset_displayed_attributes(client) {
  log.running("Reset displayed attributes")
  let assert Ok(_) =
    settings.reset_displayed_attributes(client, "individual_settings_test")
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.get_displayed_attributes(client, "individual_settings_test")
  assert result == ["*"]
  log.pass("Reset displayed attributes")
}

fn test_filterable_attributes(client) {
  test_update_filterable_attributes(client)
  test_reset_filterable_attributes(client)
}

fn test_update_filterable_attributes(client) {
  log.running("Update filterable attributes")
  let assert Ok(_) =
    settings.update_filterable_attributes(client, "individual_settings_test", [
      "genre", "year",
    ])
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.get_filterable_attributes(client, "individual_settings_test")
  assert list.sort(result, string.compare)
    == list.sort(["genre", "year"], string.compare)
  log.pass("Update filterable attributes")
}

fn test_reset_filterable_attributes(client) {
  log.running("Reset filterable attributes")
  let assert Ok(_) =
    settings.reset_filterable_attributes(client, "individual_settings_test")
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.get_filterable_attributes(client, "individual_settings_test")
  assert result == []
  log.pass("Reset filterable attributes")
}

fn test_searchable_attributes(client) {
  test_update_searchable_attributes(client)
  test_reset_searchable_attributes(client)
}

fn test_update_searchable_attributes(client) {
  log.running("Update searchable attributes")
  let assert Ok(_) =
    settings.update_searchable_attributes(client, "individual_settings_test", [
      "title", "overview",
    ])
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.get_searchable_attributes(client, "individual_settings_test")
  assert result == ["title", "overview"]
  log.pass("Update searchable attributes")
}

fn test_reset_searchable_attributes(client) {
  log.running("Reset searchable attributes")
  let assert Ok(_) =
    settings.reset_searchable_attributes(client, "individual_settings_test")
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.get_searchable_attributes(client, "individual_settings_test")
  assert result == ["*"]
  log.pass("Reset searchable attributes")
}

fn test_sortable_attributes(client) {
  test_update_sortable_attributes(client)
  test_reset_sortable_attributes(client)
}

fn test_update_sortable_attributes(client) {
  log.running("Update sortable attributes")
  let assert Ok(_) =
    settings.update_sortable_attributes(client, "individual_settings_test", [
      "year", "title",
    ])
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.get_sortable_attributes(client, "individual_settings_test")
  assert list.sort(result, string.compare)
    == list.sort(["year", "title"], string.compare)
  log.pass("Update sortable attributes")
}

fn test_reset_sortable_attributes(client) {
  log.running("Reset sortable attributes")
  let assert Ok(_) =
    settings.reset_sortable_attributes(client, "individual_settings_test")
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.get_sortable_attributes(client, "individual_settings_test")
  assert result == []
  log.pass("Reset sortable attributes")
}

fn test_non_separator_tokens(client) {
  test_update_non_separator_tokens(client)
  test_reset_non_separator_tokens(client)
}

fn test_update_non_separator_tokens(client) {
  log.running("Update non separator tokens")
  let assert Ok(_) =
    settings.update_non_separator_tokens(client, "individual_settings_test", [
      "@", "#",
    ])
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.get_non_separator_tokens(client, "individual_settings_test")
  assert list.sort(result, string.compare)
    == list.sort(["@", "#"], string.compare)
  log.pass("Update non separator tokens")
}

fn test_reset_non_separator_tokens(client) {
  log.running("Reset non separator tokens")
  let assert Ok(_) =
    settings.reset_non_separator_tokens(client, "individual_settings_test")
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.get_non_separator_tokens(client, "individual_settings_test")
  assert result == []
  log.pass("Reset non separator tokens")
}

fn test_separator_tokens(client) {
  test_update_separator_tokens(client)
  test_reset_separator_tokens(client)
}

fn test_update_separator_tokens(client) {
  log.running("Update separator tokens")
  let assert Ok(_) =
    settings.update_separator_tokens(client, "individual_settings_test", [
      "|", "/",
    ])
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.get_separator_tokens(client, "individual_settings_test")
  assert list.sort(result, string.compare)
    == list.sort(["|", "/"], string.compare)
  log.pass("Update separator tokens")
}

fn test_reset_separator_tokens(client) {
  log.running("Reset separator tokens")
  let assert Ok(_) =
    settings.reset_separator_tokens(client, "individual_settings_test")
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.get_separator_tokens(client, "individual_settings_test")
  assert result == []
  log.pass("Reset separator tokens")
}

fn test_stop_words(client) {
  test_update_stop_words(client)
  test_reset_stop_words(client)
}

fn test_update_stop_words(client) {
  log.running("Update stop words")
  let assert Ok(_) =
    settings.update_stop_words(client, "individual_settings_test", [
      "the", "a", "an",
    ])
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.get_stop_words(client, "individual_settings_test")
  assert list.sort(result, string.compare)
    == list.sort(["the", "a", "an"], string.compare)
  log.pass("Update stop words")
}

fn test_reset_stop_words(client) {
  log.running("Reset stop words")
  let assert Ok(_) =
    settings.reset_stop_words(client, "individual_settings_test")
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.get_stop_words(client, "individual_settings_test")
  assert result == []
  log.pass("Reset stop words")
}

fn test_ranking_rules(client) {
  test_update_ranking_rules(client)
  test_reset_ranking_rules(client)
}

fn test_update_ranking_rules(client) {
  log.running("Update ranking rules")
  let assert Ok(_) =
    settings.update_ranking_rules(client, "individual_settings_test", [
      sansio_settings.Words,
      sansio_settings.Typo,
      sansio_settings.Exactness,
    ])
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.get_ranking_rules(client, "individual_settings_test")
  assert result
    == [
      sansio_settings.Words,
      sansio_settings.Typo,
      sansio_settings.Exactness,
    ]
  log.pass("Update ranking rules")
}

fn test_reset_ranking_rules(client) {
  log.running("Reset ranking rules")
  let assert Ok(_) =
    settings.reset_ranking_rules(client, "individual_settings_test")
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.get_ranking_rules(client, "individual_settings_test")
  assert result
    == [
      sansio_settings.Words,
      sansio_settings.Typo,
      sansio_settings.Proximity,
      sansio_settings.AttributeRank,
      sansio_settings.Sort,
      sansio_settings.WordPosition,
      sansio_settings.Exactness,
    ]
  log.pass("Reset ranking rules")
}

fn test_search_cutoff_ms(client) {
  test_update_search_cutoff_ms(client)
  test_reset_search_cutoff_ms(client)
}

fn test_update_search_cutoff_ms(client) {
  log.running("Update search cutoff ms")
  let assert Ok(_) =
    settings.update_search_cutoff_ms(client, "individual_settings_test", 150)
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.get_search_cutoff_ms(client, "individual_settings_test")
  assert result == option.Some(150)
  log.pass("Update search cutoff ms")
}

fn test_reset_search_cutoff_ms(client) {
  log.running("Reset search cutoff ms")
  let assert Ok(_) =
    settings.reset_search_cutoff_ms(client, "individual_settings_test")
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.get_search_cutoff_ms(client, "individual_settings_test")
  assert result == option.None
  log.pass("Reset search cutoff ms")
}

fn test_facet_search(client) {
  test_update_facet_search(client)
  test_reset_facet_search(client)
}

fn test_update_facet_search(client) {
  log.running("Update facet search")
  let assert Ok(_) =
    settings.update_facet_search(client, "individual_settings_test", False)
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.get_facet_search(client, "individual_settings_test")
  assert result == False
  log.pass("Update facet search")
}

fn test_reset_facet_search(client) {
  log.running("Reset facet search")
  let assert Ok(_) =
    settings.reset_facet_search(client, "individual_settings_test")
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.get_facet_search(client, "individual_settings_test")
  assert result == True
  log.pass("Reset facet search")
}

fn test_distinct_attribute(client) {
  test_update_distinct_attribute(client)
  test_reset_distinct_attribute(client)
}

fn test_update_distinct_attribute(client) {
  log.running("Update distinct attribute")
  let assert Ok(_) =
    settings.update_distinct_attribute(client, "individual_settings_test", "id")
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.get_distinct_attribute(client, "individual_settings_test")
  assert result == option.Some("id")
  log.pass("Update distinct attribute")
}

fn test_reset_distinct_attribute(client) {
  log.running("Reset distinct attribute")
  let assert Ok(_) =
    settings.reset_distinct_attribute(client, "individual_settings_test")
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.get_distinct_attribute(client, "individual_settings_test")
  assert result == option.None
  log.pass("Reset distinct attribute")
}

fn test_synonyms(client) {
  test_update_synonyms(client)
  test_reset_synonyms(client)
}

fn test_update_synonyms(client) {
  log.running("Update synonyms")
  let assert Ok(_) =
    settings.update_synonyms(client, "individual_settings_test", dict.from_list([
      #("wolverine", ["xmen", "logan"]),
      #("car", ["automobile", "vehicle"]),
    ]))
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.get_synonyms(client, "individual_settings_test")
  assert dict.get(result, "wolverine") == Ok(["xmen", "logan"])
  assert dict.get(result, "car") == Ok(["automobile", "vehicle"])
  log.pass("Update synonyms")
}

fn test_reset_synonyms(client) {
  log.running("Reset synonyms")
  let assert Ok(_) =
    settings.reset_synonyms(client, "individual_settings_test")
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.get_synonyms(client, "individual_settings_test")
  assert result == dict.new()
  log.pass("Reset synonyms")
}

fn setup(client) {
  let assert Ok(_) =
    index.create_index(client, "individual_settings_test", Some("id"))
  process.sleep(1000)
}

fn teardown(client) {
  let assert Ok(_) = index.delete_index(client, "individual_settings_test")
  process.sleep(1000)
}
