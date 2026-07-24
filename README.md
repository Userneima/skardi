<div align="center">
<p align="center">

<img src="asset/logo.png" alt="Skardi Logo" width="700">

**Skardi is an open-source context layer for AI agents** — it connects an agent to data through source definitions, business semantics, and explicit read/write boundaries that you can inspect and control.

**Context** · source and business meaning &nbsp;·&nbsp; **Control** · default read-only and declared shared tools &nbsp;·&nbsp; **Interfaces** · CLI + REST

<a href="https://skardilabs.github.io/skardi-docs/">Documentation</a> •
<a href="#roadmap">Roadmap</a> •
<a href="https://discord.gg/S5YQQPEV2m">Discord</a>

[License]: https://opensource.org/licenses/Apache-2.0
[License Badge]: https://img.shields.io/badge/License-Apache%202.0-orange.svg
[CI]: https://github.com/SkardiLabs/skardi/actions/workflows/ci.yml
[CI Badge]: https://github.com/SkardiLabs/skardi/actions/workflows/ci.yml/badge.svg
[Codecov]: https://codecov.io/gh/SkardiLabs/skardi
[Codecov Badge]: https://codecov.io/gh/SkardiLabs/skardi/branch/main/graph/badge.svg
[crates.io]: https://crates.io/crates/skardi
[crates.io Badge]: https://img.shields.io/crates/v/skardi?logo=rust
[Docs]: https://docs.rs/skardi
[Docs Badge]: https://docs.rs/skardi/badge.svg
[Discord]: https://discord.gg/S5YQQPEV2m
[Discord Badge]: https://img.shields.io/badge/Discord-Join-5865F2?logo=discord&logoColor=white

[![License Badge]][License]
[![CI Badge]][CI]
[![Codecov Badge]][Codecov]
[![crates.io Badge]][crates.io]
[![Docs Badge]][Docs]
[![Discord Badge]][Discord]

[![Deploy on Sealos](https://sealos.io/Deploy-on-Sealos.svg)](https://sealos.io/products/app-store/skardi/) [![Install on Claude Skills](asset/Install-Claude-Skills.svg)](https://github.com/SkardiLabs/skardi-skills)

</p>
</div>

<hr />

## Why Skardi?

Giving an agent a database connection is not enough. It still has to know which source matters, what the tables mean, and which actions are safe to expose. Sending a raw schema or a full data dump into a prompt is noisy; handing an agent a broad database credential is risky.

Skardi gives developers one place to define the data context an agent may use:

- **Relevant facts, not a schema dump.** Register data sources and add plain-language descriptions for tables and columns, so an agent can inspect the business meaning before it queries.
- **Reusable task interfaces.** Turn a common query into a parameterized pipeline that the server exposes as a REST endpoint and the CLI can run from disk.
- **Explicit data boundaries.** Sources are read-only by default. Writes require an explicit `access_mode: read_write`; DDL operations are rejected when pipelines are loaded.

This is useful for coding agents that need to inspect a production-adjacent database, investigate a failed workflow, or retrieve only the facts needed for a task. It is also useful for a local document knowledge base, but that is an OSS onboarding path, not the definition of the product.

---

## What Skardi controls today

Skardi is a CLI and a lightweight HTTP server over the same SQL engine. The CLI can run SQL against a local context file; the server exposes only the pipelines you declare as parameterized REST endpoints.

| You define | Skardi enforces or exposes |
|---|---|
| Data sources in `ctx.yaml` | Only registered sources are available to that context |
| Table and column descriptions in a semantics file | `skardi query --schema` and `GET /data_source` show the descriptions |
| `read_only` or explicit `read_write` per source | Read-only is the default; DML needs an opted-in writable source |
| A parameterized pipeline | The server exposes it as `POST /:name/execute` |

**Current limits matter.** Skardi does not currently provide per-agent or per-user data permissions, system-wide column-level restrictions, a complete audit trail for every action, or rollback / branch workflows. The jobs ledger records asynchronous job runs; it is not full lineage. MCP bindings, Cloud-hosted coordination, and automatic pipeline recommendations are not current OSS interfaces.

> **Beta.** APIs may move. Read the implementation-oriented boundary in [docs/agent_data_plane.md](docs/agent_data_plane.md) before connecting an agent to non-test data.

## Two OSS starting paths

1. **Local knowledge base.** Use [`auto_knowledge_base`](https://github.com/SkardiLabs/skardi-skills/tree/main/auto_knowledge_base) to make local documents searchable from an agent session. This is a fast, local onboarding path.
2. **Controlled database context.** Register a read-only source, add the business meaning of key tables and columns, and declare recurring agent tasks as pipelines. The agent receives only the result of the query it calls, rather than a database dump in its prompt.

The second path is the better fit when a coding agent needs to investigate operational data without being handed broad, long-lived write access.

---

## Quick start: local knowledge base (OSS path)

This optional path turns a folder of documents into a local knowledge base that an agent can query with citations. It is an onboarding path, not a claim that Skardi is an autonomous RAG product.

### 1 — Install the CLI (pick one)

```bash
# Option A · pre-built binary (faster, no Rust needed)
curl -fSL "https://github.com/SkardiLabs/skardi/releases/latest/download/skardi-$(uname -m | sed 's/arm64/aarch64/')-$(uname -s | sed 's/Linux/unknown-linux-gnu/' | sed 's/Darwin/apple-darwin/').tar.gz" | tar xz && sudo mv skardi /usr/local/bin/

# Option B · from source (recommended during beta; needs Rust first)
git clone https://github.com/SkardiLabs/skardi.git && cd skardi && cargo install --locked --path crates/cli
```

You should see `skardi --version` print `0.4.0` or higher.

### 2 — Install the skill in Claude Code (two lines)

```
/plugin marketplace add SkardiLabs/skardi-skills
/plugin install auto-knowledge-base@skardi-skills
```

(Cursor / manual: copy the skill directory into `~/.claude/skills/`.)

### 3 — Ask the agent to scaffold the knowledge base

> "Turn `./docs` into a knowledge base I can search, then find 'how is X implemented'."

The skill can scaffold ingestion: download the model, chunk documents, build the index, and retrieve matched passages with sources. Review the generated configuration and source material before using it beyond a local test.

### Did it really work? (4 checks — "no errors" is not enough)

- [ ] `kb.db` exists and it prints `[6/6] Workspace ready`
- [ ] `rows` ≥ number of documents, `files` = number of documents (every file made it in)
- [ ] Ask something the docs clearly cover — the **first result actually matches** (not a random line)
- [ ] The agent's answer can point to which document it came from

All four pass = the knowledge base really works.

### What you get

- A local path from documents to cited retrieval
- A generated configuration you can inspect and edit
- No server or cloud account required for this path
- Components such as embedders and vector stores remain replaceable

### Troubleshooting (symptom → fix)

| Symptom | Cause | Fix |
|---|---|---|
| Init fails with `AttributeError …'enable_load_extension'` | Using macOS system Python | `brew install python`, re-run with `/opt/homebrew/bin/python3` |
| `skardi: command not found` | Not installed / not on PATH | Re-read "Install the CLI"; confirm `skardi --version` |
| Ingest fails with `Invalid function 'chunk'` | skardi version below 0.4.0 | Upgrade to 0.4.0+ (`chunk()` is a hard dependency) |
| Ingest fails with `UNIQUE constraint failed` | Same batch ingested twice | Normal protection; to rebuild, re-init with `--force` |
| Retrieval returns empty | Empty index / keyword too obscure | Confirm ingest `rows > 0` first; reword closer to the docs' wording, or use pure semantic search |
| Retrieval results irrelevant | Embedding model doesn't match corpus language / domain | Switch model (multilingual e5, code voyage-code), then rebuild the index |

### Controlled database context

For a database task, declare the source and keep it read-only unless a human deliberately enables writes:

```yaml
kind: context
metadata:
  name: support-debugging
spec:
  data_sources:
    - name: orders
      type: postgres
      connection_string: ${POSTGRES_URL}
      options:
        schema: public
        table: orders
      # access_mode defaults to read_only
```

Add business meaning that a developer has reviewed. An agent can help draft this file, but it is not the final authority on what a table or metric means:

```yaml
# semantics.yaml
kind: semantics
metadata:
  name: support-debugging
spec:
  sources:
    - name: orders
      description: "One row per customer order. Cancelled orders are not completed orders."
      columns:
        - name: status
          description: "Lifecycle state of an order."
        - name: created_at
          description: "UTC timestamp when the order was created."
```

For a shared agent task, expose a named, parameterized read pipeline instead of handing the agent a broad database connection:

```yaml
# pipelines/order-status.yaml
kind: pipeline
metadata:
  name: order-status
spec:
  query: |
    SELECT status, COUNT(*) AS orders
    FROM orders
    WHERE created_at >= {from}
      AND created_at < {to}
    GROUP BY status
```

```bash
skardi-server --ctx ctx.yaml --semantics semantics.yaml --pipeline pipelines/ --port 8080

curl -X POST http://localhost:8080/order-status/execute \
  -H 'Content-Type: application/json' \
  -d '{"from":"2026-07-01","to":"2026-08-01"}'
```

The server exposes declared pipelines, not a general SQL endpoint. Pipeline configuration rejects DDL when it is loaded; writes require an explicit `read_write` source setting. Current Skardi does **not** provide per-agent or per-user authorization, system-wide column restrictions, complete audit trails, rollback, or data lineage.

---

## Worked examples

For end-to-end walkthroughs — RAG, recommendations, an agent-native wiki, a simple REST backend — see the [`demo/`](demo/) directory. Each demo ships as a self-contained `ctx.yaml` plus pipelines (and sometimes jobs), so reading the YAML shows the Skardi shape in practice. Full list in [Demo & Examples](#demo--examples) below.

---

## Supported Data Sources

| Type | CRUD | Catalog mode | Description | Docs |
|------|------|--------------|-------------|------|
| PostgreSQL | Full | Yes | Table or catalog registration, pgvector KNN | [docs/postgres/](docs/postgres/) |
| MySQL | Full | Yes | Table or catalog registration | [docs/mysql/](docs/mysql/) |
| SQLite | Full | Yes | Table or catalog registration, sqlite-vec KNN, FTS | [docs/sqlite/](docs/sqlite/) |
| MongoDB | Full | No | Collections with point lookups | [docs/mongo/](docs/mongo/) |
| Redis | Full | No | Hashes mapped to SQL rows | [docs/redis/](docs/redis/) |
| DynamoDB | Full | Yes | Items mapped to SQL rows, table or catalog registration, scan + filter pushdown | [docs/dynamodb/](docs/dynamodb/) |
| SeekDB | Full | Yes | MySQL-wire CRUD, native FULLTEXT FTS, HNSW VECTOR KNN | [docs/seekdb/](docs/seekdb/) |
| Lance | Read (job-write) | No | KNN vector search, BM25 FTS; job destination | [docs/lance/](docs/lance/) |
| CSV | Read | No | Local or remote CSV files | [docs/server.md](docs/server.md) |
| Parquet | Read | No | Local or remote Parquet files | [docs/server.md](docs/server.md) |
| JSON / NDJSON | Read | No | Local or remote JSON files | [docs/cli.md](docs/cli.md) |
| S3 / GCS / Azure | Read | No | CSV, Parquet, Lance from object stores | [docs/S3_USAGE.md](docs/S3_USAGE.md) |
| Apache Iceberg | Read | No | Schema evolution, partition pruning | [docs/iceberg/](docs/iceberg/) |
| InfluxDB 3 | Read | No | Time-series measurements over Arrow Flight SQL | [docs/influxdb/](docs/influxdb/) |
| Documents | Read | No | PDF/Office/ODF/image -> per-page markdown, tables, images (local directories; `documents` feature) | [docs/documents.md](docs/documents.md) |

---

## Additional Features

- **Federated queries** — JOIN across different source types in one SQL query (CSV vs Postgres vs Lance, etc). See [docs/federated-queries.md](docs/federated-queries.md).
- **Table descriptions for agents** — write natural-language descriptions of each table and column in YAML; Skardi serves them on `GET /data_source` so the agent can read what each table is for before it queries. See [docs/semantics.md](docs/semantics.md).
- **Authentication** — session-based via better-auth + SQLite. See [docs/auth/](docs/auth/).
- **ONNX inference** — inline model predictions in SQL via an `onnx_predict` UDF. See [docs/onnx_predict.md](docs/onnx_predict.md).
- **Embedding inference** — call embedding models from inside SQL via the `candle()` UDF (local GGUF / Candle models, or remote OpenAI-style APIs). See [docs/embeddings/](docs/embeddings/).
- **Observability** — OpenTelemetry traces / metrics / logs with a pre-configured Grafana stack. See [docs/observability.md](docs/observability.md).

---

## Architecture

<details>
<summary>Click to expand Skardi's architecture diagram</summary>

<p align="center">
  <img src="asset/architecture.png" alt="Skardi Architecture" width="800">
</p>

</details>

---

## Docker

```bash
# Build
docker build -t skardi .
docker build -t skardi --build-arg FEATURES=rag .   # adds embedding + chunk UDFs

# Or pull pre-built
docker pull ghcr.io/skardilabs/skardi/skardi-server:latest
docker pull ghcr.io/skardilabs/skardi/skardi-server-rag:latest   # embedding + chunk UDFs

# Run
docker run --rm \
  -v /path/to/your/ctx.yaml:/config/ctx.yaml \
  -v /path/to/your/pipelines:/config/pipelines \
  -p 8080:8080 \
  skardi \
  --ctx /config/ctx.yaml \
  --pipeline /config/pipelines \
  --port 8080
```

## Cloud (Sealos)

The fastest cloud path is the [Sealos](https://sealos.io) template in **[skardi-skills](https://github.com/SkardiLabs/skardi-skills)** — our growing library of ready-to-use Skardi setups. One-click launch, no local setup.

## Building from Source

```bash
git clone https://github.com/SkardiLabs/skardi.git
cd skardi

cargo build --release -p skardi-cli
cargo build --release -p skardi-server

# With the full RAG kit (embedding UDFs + chunk UDF)
cargo build --release -p skardi-server --features rag

# Or just the embedding UDFs (ONNX, GGUF, Candle, remote embed) without chunking
cargo build --release -p skardi-server --features embedding
```

---

## Demo & Examples

| Directory | Description |
|-----------|-------------|
| [demo/llm_wiki/](demo/llm_wiki/) | Agent-native wiki (server + CLI flavors) — hybrid search, inline embeddings, agent verbs |
| [demo/simple_backend/](demo/simple_backend/) | REST backend with SQLite and optional auth |
| [demo/rag/](demo/rag/) | Retrieval-augmented generation pipeline |
| [demo/movie_recommendation/](demo/movie_recommendation/) | Movie recommendations with ONNX NCF model |

For data-source-specific demos, see the entries in [Supported Data Sources](#supported-data-sources).

---

## Roadmap

**Roadmap items are not current capabilities.** Future interface experiments include a skills generator that emits Claude Code skill files per pipeline, an MCP binding for non-Claude hosts, and a first-class memory primitive. They are not part of today's install or authorization contract.

We're **building in public**. `[x]` means shipped today, `[ ]` means open for contribution. Open an issue or hop into [Discord](https://discord.gg/S5YQQPEV2m) on anything unchecked.

`1` Federated SQL engine
   - [x] One SQL engine ([DataFusion](https://datafusion.apache.org/), in-process) over CSV, Parquet, JSON, S3 / GCS / Azure, Postgres, MySQL, SQLite, MongoDB, Redis, Iceberg, Lance, SeekDB — all joinable in one query
   - [x] Register either one specific table, or point Skardi at a database (Postgres / MySQL / SQLite) and let it auto-discover all tables — one config line either way
   - [ ] Graph database sources (Neo4j / Kuzu) — to unlock graphRAG patterns alongside vector / full-text retrieval

`2` Retrieval primitives
   - [x] Vector search (KNN) — `pg_knn` (pgvector), `sqlite_knn` (sqlite-vec), Lance KNN, SeekDB HNSW
   - [x] Full-text search (FTS) — `pg_fts`, `sqlite_fts`, Lance BM25 inverted indexes, SeekDB FULLTEXT
   - [x] Hybrid search — combine keyword and semantic search results in one SQL query (RRF merge), no Python re-ranking layer
   - [x] Inline embeddings — `candle()` UDF (local GGUF / Candle models, or remote embedding APIs) called inside SQL, so content + vector stay on the same row atomically
   - [x] ONNX inference — `onnx_predict` UDF for inline model predictions in SQL
   - [x] Chunking UDF — `chunk()` with character / markdown splitters (via [`text-splitter`](https://crates.io/crates/text-splitter)) so ingestion can chunk inline in SQL ([docs](docs/chunk.md)); token / code splitters next
   - [ ] Memory primitive — give your agent a memory store (keyword + semantic recall, TTL/expiration, per-session provenance) defined in one YAML block

`3` Online serving (pipelines)
   - [x] Declarative YAML → parameterized REST endpoint with inferred request / response schema
   - [x] Built-in pipeline dashboard
   - [x] CLI pipeline binding + aliases — `skardi run <pipeline> --param=…` and user-defined verb aliases ([#90](https://github.com/SkardiLabs/skardi/pull/90))
   - [x] CLI federated SQL — `skardi query` against files, object stores, datalake formats, and databases with no server required

`4` Offline jobs
   - [x] Async batch execution with submit / poll / cancel ([#98](https://github.com/SkardiLabs/skardi/pull/98))
   - [x] Lance dataset destinations with atomic commit + crash recovery
   - [x] SQL-DML destinations (Postgres / MySQL / SQLite)
   - [x] SQLite-backed run ledger with submit-time schema diff

`5` Agent-facing bindings
   - [x] REST — every pipeline served as a parameterized HTTP endpoint
   - [x] Shell — every pipeline runnable as a `skardi` command; works in Claude Code, Cursor, and any agent with a Bash tool
   - [ ] Skills generator — `skardi skills generate --ctx <ctx.yaml> --out .claude/skills/` emits a skill Markdown per pipeline for Claude Code / Desktop auto-discovery
   - [ ] MCP binding — same pipeline YAML projected to MCP tools for non-Claude hosts

`6` Context descriptions
   - [x] Plain-English table descriptions — a `kind: semantics` YAML overlay attaching natural-language descriptions to tables / columns (supports both bare source names and fully-qualified `catalog.schema.table` paths); served on `GET /data_source` so agents can discover what each table is for before querying
   - [ ] Agent-callable `describe` verb — CLI / pipeline form on top of the discovery endpoint

`7` Ops
   - [x] Session auth — drop-in user auth via [better-auth](https://www.better-auth.com/) backed by SQLite
   - [x] Observability — OpenTelemetry traces / metrics / logs with a pre-configured Grafana stack
   - [x] Docker + pre-built binaries — Linux x86_64 / ARM64, macOS ARM64

---

## Community

Building an agent on top of Skardi, or want to influence the roadmap above? Join us on [Discord](https://discord.gg/S5YQQPEV2m), file an issue, or open a PR. We read everything.

## License

Apache 2.0 — see [LICENSE](LICENSE).
