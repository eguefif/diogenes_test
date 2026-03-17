import diogenes.{MeilisearchSingleResult}
import diogenes/index
import diogenes/sansio/settings as sansio_settings
import diogenes/settings
import gleam/dict
import gleam/erlang/process
import gleam/list
import gleam/option.{Some}
import log

pub fn run(client) {
  log.section("Settings")
  setup(client)
  test_list_settings_defaults(client)
  test_update_all_settings(client)
  test_update_proximity_precision_by_attribute(client)
  test_update_typo_tolerance_disabled(client)
  test_update_prefix_search_disabled(client)
  test_update_localized_attributes(client)
  teardown(client)
}

fn test_list_settings_defaults(client) {
  log.running("List settings defaults")
  let assert Ok(MeilisearchSingleResult(result: defaults)) =
    settings.list_all_settings(client, "settings_test")

  // Meilisearch defaults
  assert defaults.displayed_attributes == ["*"]
  assert defaults.searchable_attributes == ["*"]
  assert defaults.filterable_attributes == []
  assert defaults.sortable_attributes == []
  assert defaults.stop_words == []
  assert defaults.non_separator_tokens == []
  assert defaults.separator_tokens == []
  assert defaults.dictionary == []
  assert defaults.distinct_attribute == ""
  assert defaults.proximity_precision == sansio_settings.ByWord
  assert defaults.typo_tolerance.enabled == True
  assert defaults.typo_tolerance.min_word_size_for_typo.one_typo == 5
  assert defaults.typo_tolerance.min_word_size_for_typo.two_typos == 9
  assert defaults.typo_tolerance.disable_on_words == []
  assert defaults.typo_tolerance.disable_on_attributes == []
  assert defaults.faceting.max_values_per_facet == 100
  assert defaults.pagination.max_total_hits == 1000
  assert defaults.facet_search == True
  assert defaults.prefix_search == sansio_settings.IndexTime
  log.pass("List settings defaults")
}

fn test_update_all_settings(client) {
  log.running("Update all settings")
  let updated =
    sansio_settings.Settings(
      displayed_attributes: ["id", "title", "year", "genres", "overview"],
      searchable_attributes: ["title", "overview"],
      filterable_attributes: ["genres", "year"],
      sortable_attributes: ["year", "title"],
      foreign_keys: [
        sansio_settings.ForeignKey(
          foreign_index_uid: "directors",
          field_name: "director_id",
        ),
      ],
      ranking_rules: [
        sansio_settings.Words,
        sansio_settings.Typo,
        sansio_settings.Proximity,
        sansio_settings.AttributeRank,
        sansio_settings.Sort,
        sansio_settings.Exactness,
      ],
      stop_words: ["the", "a", "an", "of", "in"],
      non_separator_tokens: ["@", "#"],
      separator_tokens: ["/", "\\"],
      dictionary: ["shipit", "yolo", "brb"],
      synonyms: dict.from_list([
        #("car", ["automobile", "vehicle"]),
        #("movie", ["film", "picture", "flick"]),
      ]),
      distinct_attribute: "id",
      proximity_precision: sansio_settings.ByWord,
      typo_tolerance: sansio_settings.TypoTolerance(
        enabled: True,
        min_word_size_for_typo: sansio_settings.MinWordSizeForTypo(
          one_typo: 6,
          two_typos: 10,
        ),
        disable_on_words: ["shogun", "iphone"],
        disable_on_attributes: ["title"],
      ),
      faceting: sansio_settings.Faceting(
        max_values_per_facet: 200,
        sort_facet_values_by: dict.from_list([
          #("*", sansio_settings.Alpha),
          #("genres", sansio_settings.Count),
        ]),
      ),
      pagination: sansio_settings.Pagination(max_total_hits: 5000),
      embedders: sansio_settings.Embedder(
        source: sansio_settings.OpenAi,
        model: "",
        revision: option.None,
        pooling: sansio_settings.UseModel,
        api_key: "",
        dimensions: 0,
        binary_quantisized: False,
        document_template: "",
        document_template_max_bytes: 0,
        url: "",
        indexing_fragments: dict.new(),
        search_fragments: dict.new(),
        request: dict.new(),
        response: dict.new(),
        headers: dict.new(),
        search_embedder: option.None,
        indexing_embedder: option.None,
        distribution: sansio_settings.Distribution(
          current_mean: 0.0,
          current_sigma: 0.0,
        ),
        chat: sansio_settings.Chat(
          description: "",
          document_template: "",
          document_template_max_bytes: 0,
          search_parameters: sansio_settings.ChatSearchParameters(
            hybrid: sansio_settings.ChatEmbedder(embedder: "", semantic_ratio: 0.0),
            limit: 0,
            sort: [],
            distinct: "",
            matching_strategy: sansio_settings.Last,
            attributes_to_search_on: [],
            ranking_score_threshold: option.None,
          ),
        ),
      ),
      search_cutoff_ms: option.Some(1500),
      localized_attribute: [
        sansio_settings.LocalizedAttribute(
          locales: [sansio_settings.En, sansio_settings.Fr, sansio_settings.De],
          attribute_patterns: ["title", "overview"],
        ),
        sansio_settings.LocalizedAttribute(
          locales: [sansio_settings.Ja, sansio_settings.Zh, sansio_settings.Ko],
          attribute_patterns: ["title_*"],
        ),
      ],
      facet_search: True,
      prefix_search: sansio_settings.IndexTime,
    )
  let assert Ok(_) =
    settings.update_all_settings(client, "settings_test", updated)
  process.sleep(1000)
  log.pass("Update all settings")

  log.running("Verify updated settings")
  let assert Ok(MeilisearchSingleResult(result: result)) =
    settings.list_all_settings(client, "settings_test")

  assert result.displayed_attributes
    == ["id", "title", "year", "genres", "overview"]
  assert result.searchable_attributes == ["title", "overview"]
  assert result.filterable_attributes == ["genres", "year"]
  assert result.sortable_attributes == ["year", "title"]
  assert result.stop_words == ["the", "a", "an", "of", "in"]
  assert result.non_separator_tokens == ["@", "#"]
  assert result.separator_tokens == ["/", "\\"]
  assert result.dictionary == ["shipit", "yolo", "brb"]
  assert result.distinct_attribute == "id"
  assert result.proximity_precision == sansio_settings.ByWord
  assert result.typo_tolerance.enabled == True
  assert result.typo_tolerance.min_word_size_for_typo.one_typo == 6
  assert result.typo_tolerance.min_word_size_for_typo.two_typos == 10
  assert result.typo_tolerance.disable_on_words == ["shogun", "iphone"]
  assert result.typo_tolerance.disable_on_attributes == ["title"]
  assert result.faceting.max_values_per_facet == 200
  assert result.pagination.max_total_hits == 5000
  assert result.search_cutoff_ms == option.Some(1500)
  assert result.facet_search == True
  assert result.prefix_search == sansio_settings.IndexTime

  let genres_sort = dict.get(result.faceting.sort_facet_values_by, "genres")
  assert genres_sort == Ok(sansio_settings.Count)

  assert list.length(result.localized_attribute) == 2

  let car_synonyms = dict.get(result.synonyms, "car")
  assert car_synonyms == Ok(["automobile", "vehicle"])

  log.pass("Verify updated settings")
}

fn test_update_proximity_precision_by_attribute(client) {
  log.running("Update proximity precision to ByAttribute")
  let base = base_settings()
  let updated =
    sansio_settings.Settings(
      ..base,
      proximity_precision: sansio_settings.ByAttribute,
    )
  let assert Ok(_) =
    settings.update_all_settings(client, "settings_test", updated)
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.list_all_settings(client, "settings_test")
  assert result.proximity_precision == sansio_settings.ByAttribute
  log.pass("Update proximity precision to ByAttribute")
}

fn test_update_typo_tolerance_disabled(client) {
  log.running("Update typo tolerance disabled")
  let base = base_settings()
  let updated =
    sansio_settings.Settings(
      ..base,
      typo_tolerance: sansio_settings.TypoTolerance(
        enabled: False,
        min_word_size_for_typo: sansio_settings.MinWordSizeForTypo(
          one_typo: 5,
          two_typos: 9,
        ),
        disable_on_words: [],
        disable_on_attributes: [],
      ),
    )
  let assert Ok(_) =
    settings.update_all_settings(client, "settings_test", updated)
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.list_all_settings(client, "settings_test")
  assert result.typo_tolerance.enabled == False
  log.pass("Update typo tolerance disabled")
}

fn test_update_prefix_search_disabled(client) {
  log.running("Update prefix search disabled")
  let base = base_settings()
  let updated =
    sansio_settings.Settings(
      ..base,
      prefix_search: sansio_settings.PrefixSearchDisabled,
    )
  let assert Ok(_) =
    settings.update_all_settings(client, "settings_test", updated)
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.list_all_settings(client, "settings_test")
  assert result.prefix_search == sansio_settings.PrefixSearchDisabled
  log.pass("Update prefix search disabled")
}

fn test_update_localized_attributes(client) {
  log.running("Update localized attributes with many locales")
  let base = base_settings()
  let updated =
    sansio_settings.Settings(..base, localized_attribute: [
      sansio_settings.LocalizedAttribute(
        locales: [
          sansio_settings.En,
          sansio_settings.Fr,
          sansio_settings.De,
          sansio_settings.Es,
          sansio_settings.It,
          sansio_settings.Pt,
        ],
        attribute_patterns: ["title", "overview", "description"],
      ),
      sansio_settings.LocalizedAttribute(
        locales: [
          sansio_settings.Ja,
          sansio_settings.Zh,
          sansio_settings.Ko,
          sansio_settings.Ar,
          sansio_settings.Ru,
        ],
        attribute_patterns: ["title_*", "overview_*"],
      ),
      sansio_settings.LocalizedAttribute(
        locales: [sansio_settings.Hi, sansio_settings.Bn, sansio_settings.Ur],
        attribute_patterns: ["content"],
      ),
    ])
  let assert Ok(_) =
    settings.update_all_settings(client, "settings_test", updated)
  process.sleep(1000)

  let assert Ok(MeilisearchSingleResult(result:)) =
    settings.list_all_settings(client, "settings_test")
  assert list.length(result.localized_attribute) == 3
  log.pass("Update localized attributes with many locales")
}

// Returns a minimal valid Settings for use as a base in focused tests.
fn base_settings() -> sansio_settings.Settings {
  sansio_settings.Settings(
    displayed_attributes: ["*"],
    searchable_attributes: ["*"],
    filterable_attributes: [],
    sortable_attributes: [],
    foreign_keys: [],
    ranking_rules: [
      sansio_settings.Words,
      sansio_settings.Typo,
      sansio_settings.Proximity,
      sansio_settings.AttributeRank,
      sansio_settings.Sort,
      sansio_settings.Exactness,
    ],
    stop_words: [],
    non_separator_tokens: [],
    separator_tokens: [],
    dictionary: [],
    synonyms: dict.new(),
    distinct_attribute: "",
    proximity_precision: sansio_settings.ByWord,
    typo_tolerance: sansio_settings.TypoTolerance(
      enabled: True,
      min_word_size_for_typo: sansio_settings.MinWordSizeForTypo(
        one_typo: 5,
        two_typos: 9,
      ),
      disable_on_words: [],
      disable_on_attributes: [],
    ),
    faceting: sansio_settings.Faceting(
      max_values_per_facet: 100,
      sort_facet_values_by: dict.from_list([#("*", sansio_settings.Alpha)]),
    ),
    pagination: sansio_settings.Pagination(max_total_hits: 1000),
    embedders: sansio_settings.Embedder(
      source: sansio_settings.OpenAi,
      model: "",
      revision: option.None,
      pooling: sansio_settings.UseModel,
      api_key: "",
      dimensions: 0,
      binary_quantisized: False,
      document_template: "",
      document_template_max_bytes: 0,
      url: "",
      indexing_fragments: dict.new(),
      search_fragments: dict.new(),
      request: dict.new(),
      response: dict.new(),
      headers: dict.new(),
      search_embedder: option.None,
      indexing_embedder: option.None,
      distribution: sansio_settings.Distribution(
        current_mean: 0.0,
        current_sigma: 0.0,
      ),
      chat: sansio_settings.Chat(
        description: "",
        document_template: "",
        document_template_max_bytes: 0,
        search_parameters: sansio_settings.ChatSearchParameters(
          hybrid: sansio_settings.ChatEmbedder(embedder: "", semantic_ratio: 0.0),
          limit: 0,
          sort: [],
          distinct: "",
          matching_strategy: sansio_settings.Last,
          attributes_to_search_on: [],
          ranking_score_threshold: option.None,
        ),
      ),
    ),
    search_cutoff_ms: option.None,
    localized_attribute: [],
    facet_search: True,
    prefix_search: sansio_settings.IndexTime,
  )
}

fn setup(client) {
  let assert Ok(_) = index.create_index(client, "settings_test", Some("id"))
  process.sleep(1000)
}

fn teardown(client) {
  let assert Ok(_) = index.delete_index(client, "settings_test")
  process.sleep(1000)
}
