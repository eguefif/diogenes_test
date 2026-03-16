# diogenes_tests

Integration test project for [diogenes](https://github.com/eguefif/diogenes), a Gleam client library for [Meilisearch](https://www.meilisearch.com/).

## Requirements

A running Meilisearch instance at `http://127.0.0.1:7700` with master key `123456789123456789`.

You can start one with the provided Docker Compose file:

```sh
docker compose up -d
```

## Running the tests

```sh
gleam run
```

## Test coverage

### Health

| Feature | Covered |
|---|---|
| Get health | yes |

### Indexes

| Feature | Covered |
|---|---|
| List indexes | yes |
| List indexes with pagination (offset/limit) | yes |
| Get one index | yes |
| Create index with primary key | yes |
| Update primary key | yes |
| Update uid | yes |
| Update both uid and primary key | yes |
| Delete index | yes |
| Swap indexes | yes |
| Swap indexes with rename | yes |
| List index fields | yes |

### Documents

| Feature | Covered |
|---|---|
| Add or replace documents | yes |
| Add or replace documents (explicit primary key) | yes |
| Add or update documents | yes |
| Add or update documents (skip creation) | yes |
| Get document | yes |
| List documents with GET | yes |
| List documents with GET (pagination) | yes |
| List documents with GET (fields filter) | yes |
| List documents with POST | yes |
| Delete documents by batch | yes |
| Delete documents by filter | no (requires settings API) |
| Delete document | yes |
| Delete all documents | yes |

## Development

```sh
gleam run   # Run the tests against a live Meilisearch instance
```
