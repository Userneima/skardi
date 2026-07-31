<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="asset/controlled-db-debugging-hero-dark.png">
  <img src="asset/controlled-db-debugging-hero.png" alt="Skardi diagram: connected sources and context definitions become governed context for a read-only coding agent." width="100%">
</picture>

<br>

<p align="center">
  <strong>Star Skardi ❤️ →</strong>&nbsp;
  <a href="https://github.com/SkardiLabs/skardi" title="Star Skardi on GitHub"><img src="asset/skardi-star2.gif" alt="Star Skardi on GitHub" width="141" height="50" align="absmiddle"></a>&nbsp;·&nbsp;
  <a href="https://www.skardi.ai/" title="Visit skardi.ai"><img src="asset/readme-website-button.svg" alt="Visit skardi.ai" width="127" height="48" align="absmiddle"></a>&nbsp;·&nbsp;
  <a href="https://skardilabs.github.io/skardi-docs/docs/intro" title="Read the Skardi documentation"><img src="asset/readme-docs-button.svg" alt="Read the Skardi documentation" width="89" height="48" align="absmiddle"></a>&nbsp;·&nbsp;
  <a href="https://discord.gg/S5YQQPEV2m" title="Join the Skardi Discord community"><img src="asset/readme-discord-button.svg" alt="Join the Skardi Discord community" width="115" height="48" align="absmiddle"></a>
</p>

# Give coding agents the right data — safely.

**Skardi is an open-source governed data access layer for AI agents.**
Describe the data an agent may use, explain what it means, and expose only the queries you want it to run.

<p align="center">
  <a href="https://github.com/SkardiLabs/skardi/stargazers"><img src="https://img.shields.io/github/stars/SkardiLabs/skardi?style=flat-square&amp;label=stars&amp;color=f4b400" alt="GitHub stars"></a>
  <a href="https://github.com/SkardiLabs/skardi/actions/workflows/ci.yml"><img src="https://github.com/SkardiLabs/skardi/actions/workflows/ci.yml/badge.svg?branch=main" alt="CI status"></a>
  <a href="https://crates.io/crates/skardi"><img src="https://img.shields.io/crates/v/skardi.svg?style=flat-square" alt="skardi crate version"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache--2.0-2563eb?style=flat-square" alt="Apache-2.0 license"></a>
  <a href="https://discord.gg/S5YQQPEV2m"><img src="https://img.shields.io/badge/Discord-Join-5865F2?style=flat-square&amp;logo=discord&amp;logoColor=white" alt="Join Skardi on Discord"></a>
</p>

<p align="center"><strong>English</strong>&nbsp;·&nbsp;<a href="README.zh-CN.md">简体中文</a></p>

</div>

---

## Start with your goal

Skardi can start as a local command-line tool, an agent workflow, or a shared HTTP service. Choose the task you need to complete; you do not need every component to get started.

### Install the CLI

From a terminal, clone Skardi and install the minimal CLI:

```bash
git clone https://github.com/SkardiLabs/skardi.git
cd skardi
cargo install --locked --path crates/cli --no-default-features
```

Pre-built releases, embeddings, and other installation options are in the [installation docs](https://skardilabs.github.io/skardi-docs/).

### Verify it with an example query

Run a first read-only query against the example CSV in the repository:

```bash
skardi query --sql "SELECT * FROM './data/products.csv' LIMIT 5"
```

You should see the first five rows from `data/products.csv`.

### Use local documents with an agent

The [`auto_knowledge_base`](https://github.com/SkardiLabs/skardi-skills/tree/main/auto_knowledge_base) skill turns a folder of documents into a local, cited retrieval workflow. It is an optional onboarding path for local documents; beneath the workflow, Skardi CLI handles the data locally.

### Serve a small application backend

A YAML pipeline becomes a parameterized REST endpoint without writing application glue. See [pipelines](docs/pipelines.md) and the [simple backend demo](demo/simple_backend/).

### How the pieces fit

- **CLI** runs local configuration and queries against files, databases, and object stores.
- **Server** exposes reviewed YAML pipelines as HTTP endpoints for applications or shared agent tasks.
- **Skills** package optional agent workflows, such as a local knowledge base or server-backed RAG.

CLI and Server are runtime options. Skills are installed only when a task calls for their workflow.

---

## Connect your own data

When you need a named database source or a shared agent endpoint, add a small, reviewable data contract to your codebase.

### 1. Register only the source the task needs

```yaml
# ctx.yaml
kind: context
metadata:
  name: support-debugging
spec:
  data_sources:
    - name: orders
      type: postgres
      connection_string: "postgresql://localhost:5432/support"
      options:
        schema: public
        table: orders
        user_env: PG_USER
        pass_env: PG_PASSWORD
      # access_mode defaults to read_only
```

### 2. Add the business meaning a developer has reviewed

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

### 3. Turn a recurring task into a narrow interface

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
cargo install --locked --path crates/server

skardi-server --ctx ctx.yaml --semantics semantics.yaml --pipeline pipelines/ --port 8080

curl -X POST http://localhost:8080/order-status/execute \
  -H 'Content-Type: application/json' \
  -d '{"from":"2026-07-01","to":"2026-08-01"}'
```

The server runs the named pipeline rather than exposing a general SQL endpoint. A source is read-only unless you explicitly set `access_mode: read_write`; pipeline DDL is rejected while configuration loads. See [context boundaries for agents](docs/agent_data_plane.md) for the precise current behavior.

---

## Use Skardi from an agent

Any coding agent with a shell tool can call the CLI. For a local investigation, first let it read the reviewed schema and semantics:

```bash
skardi query --ctx ctx.yaml --semantics semantics.yaml --schema --all
```

Then it can run a scoped query:

```bash
skardi query --ctx ctx.yaml --sql "SELECT status, COUNT(*) FROM orders GROUP BY status"
```

For a shared or recurring task, use a pipeline instead. The server makes the pipeline available at `POST /:name/execute`, with parameters inferred from its SQL.

---

## Data sources and capabilities

Skardi can query and join data across:

- **Databases:** PostgreSQL, MySQL, SQLite, MongoDB, Redis, DynamoDB, SeekDB, and InfluxDB 3.
- **Files and lakehouses:** CSV, JSON / NDJSON, Parquet, Lance, Apache Iceberg, and files in S3, GCS, or Azure Blob Storage.
- **Document and retrieval workflows:** document parsing, full-text search, vector search, hybrid search, and embeddings.

See the [data-source guides](docs/) for runnable configuration examples. Skardi's engine is built on [Apache DataFusion](https://datafusion.apache.org/) and supports federated SQL when a task needs to join registered sources.

---

## Examples

- [Simple backend](demo/simple_backend/) — expose a small SQLite backend as REST endpoints.
- [Agent-native wiki](demo/llm_wiki/) — hybrid retrieval, inline embeddings, and agent-facing verbs.
- [RAG](demo/rag/) — an end-to-end retrieval-augmented generation workflow.
- [Movie recommendation](demo/movie_recommendation/) — ONNX model inference in a query pipeline.

---

## Documentation

- [CLI guide](docs/cli.md)
- [Server and REST API](docs/server.md)
- [Pipeline format](docs/pipelines.md)
- [Semantics YAML](docs/semantics.md)
- [Context boundaries for agents](docs/agent_data_plane.md)
- [Federated queries](docs/federated-queries.md)

---

## Architecture

<details>
<summary>View the open-source architecture</summary>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="asset/architecture-open-source.svg">
    <img src="asset/architecture-open-source.gif" alt="Skardi open-source architecture" width="100%">
  </picture>
</p>

</details>

---

## Contributing and community

Skardi is being built in public. Open an [issue](https://github.com/SkardiLabs/skardi/issues), start a discussion in [Discord](https://discord.gg/S5YQQPEV2m), or send a pull request. For local development commands and contribution rules, see [AGENTS.md](AGENTS.md).

## License

[Apache 2.0](LICENSE)
