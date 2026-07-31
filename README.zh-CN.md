<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="asset/controlled-db-debugging-hero-zh-CN-dark.png">
  <img src="asset/controlled-db-debugging-hero-zh-CN.png" alt="Skardi 流程图：已连接的数据源和上下文定义经治理后，成为编程 Agent 可安全使用的只读上下文。" width="100%">
</picture>

<br>

<p align="center">
  <strong>给 Skardi 点星 ❤️ →</strong>&nbsp;
  <a href="https://github.com/SkardiLabs/skardi" title="在 GitHub 上 Star Skardi"><img src="asset/skardi-star2.gif" alt="高亮 Skardi GitHub Star 按钮的动图" width="150" height="54" align="absmiddle"></a>&nbsp;·&nbsp;
  <a href="https://www.skardi.ai/" title="访问 skardi.ai"><img src="asset/readme-website-button.svg" alt="访问 skardi.ai" width="127" height="48" align="absmiddle"></a>&nbsp;·&nbsp;
  <a href="https://skardilabs.github.io/skardi-docs/docs/intro" title="阅读 Skardi 文档"><img src="asset/readme-docs-button.svg" alt="阅读 Skardi 文档" width="89" height="48" align="absmiddle"></a>&nbsp;·&nbsp;
  <a href="https://discord.gg/S5YQQPEV2m" title="加入 Skardi Discord 社区"><img src="asset/readme-discord-button.svg" alt="加入 Skardi Discord 社区" width="115" height="48" align="absmiddle"></a>
</p>

# 让编程 Agent 获得可信的上下文。

**Skardi 将你批准使用的数据转化为供编程 Agent 使用的受治理上下文。** 定义 Agent 可以使用哪些数据源，解释每张表和字段的业务含义，并只暴露它完成任务所需的只读查询或 pipeline——让 Agent 无需获得宽泛的数据库权限，也能基于可信上下文完成工作。

<p align="center">
  <a href="https://github.com/SkardiLabs/skardi/stargazers"><img src="https://img.shields.io/github/stars/SkardiLabs/skardi?style=flat-square&amp;label=stars&amp;color=f4b400" alt="GitHub stars"></a>
  <a href="https://github.com/SkardiLabs/skardi/actions/workflows/ci.yml"><img src="https://github.com/SkardiLabs/skardi/actions/workflows/ci.yml/badge.svg?branch=main" alt="CI status"></a>
  <a href="https://crates.io/crates/skardi"><img src="https://img.shields.io/crates/v/skardi.svg?style=flat-square" alt="skardi crate 版本"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache--2.0-2563eb?style=flat-square" alt="Apache-2.0 许可证"></a>
  <a href="https://discord.gg/S5YQQPEV2m"><img src="https://img.shields.io/badge/Discord-Join-5865F2?style=flat-square&amp;logo=discord&amp;logoColor=white" alt="加入 Skardi Discord"></a>
</p>

<p align="center"><a href="README.md">English</a>&nbsp;·&nbsp;<strong>简体中文</strong></p>

</div>

---

## 快速上手

克隆 Skardi，安装精简版 CLI，然后对仓库已内置的示例数据执行一次只读查询。

### 1. 安装 CLI

在终端中克隆 Skardi，并安装精简版 CLI：

```bash
git clone https://github.com/SkardiLabs/skardi.git
cd skardi
cargo install --locked --path crates/cli --no-default-features
```

预构建版本、嵌入功能和其他安装方式见[安装文档](https://skardilabs.github.io/skardi-docs/)。

### 2. 用内置示例验证

克隆仓库时，`data/products.csv` 会一并下载到本地，无需另行准备数据：

```bash
skardi query --sql "SELECT * FROM './data/products.csv' LIMIT 5"
```

你会看到 `data/products.csv` 的前五行。

---

## 按你的目标继续

快速上手只用于验证 CLI。接下来按你想完成的结果选择路径，并把对应提示词直接发给编程 Agent。Agent 会先检查当前工作区，以最小且安全的方式落地，再说明它验证了什么；只有需要更多控制时才查阅链接的文档。

### 01 — 查询本地文件或数据源

适合查看 CSV、Parquet、数据库或对象存储中的数据，且不改动原始数据。

**直接发给你的编程 Agent：**

```text
帮我用 Skardi 查询本地文件或数据源。先检查当前工作区中的候选文件和已有 Skardi 配置；如果目标不明确，先问我需要查询哪个文件或数据源。所有数据源保持只读，凭据通过环境变量保留，不修改数据或 Schema。只创建必要的最小配置，执行一次 schema 检查和一条有用的查询，最后说明创建了哪些文件、运行了什么命令，以及查询结果。
```

需要更多控制时，再看 [CLI 指南](docs/cli.md) 和[数据源指南](docs/)。

### 02 — 用 Agent 处理本地文档

适合将一个文档文件夹变成本地知识库，让 Agent 可以检索并给出可追溯的引用。

**直接发给你的编程 Agent：**

```text
用 Skardi 为当前工作区中的文档建立一个本地、可追溯引用的知识库。先阅读 auto_knowledge_base skill：https://github.com/SkardiLabs/skardi-skills/tree/main/auto_knowledge_base。识别要处理的文档文件夹；如果不明确，继续前先问我。除非文档类型或环境有特殊要求，否则采用 skill 的本地默认方案。知识库工作区必须与我的源文档分开；完成后用一次检索查询验证，并说明工作区位置、运行过的命令和带引用的结果。
```

完整的配置和排错细节见 [`auto_knowledge_base`](https://github.com/SkardiLabs/skardi-skills/tree/main/auto_knowledge_base) skill。

### 03 — 提供小型应用后端

适合把一个已审核的任务变成参数化 REST endpoint，而不是暴露通用 SQL 接口或另写应用胶水代码。

**直接发给你的编程 Agent：**

```text
在当前工作区中，为一个具体应用任务创建最小且安全的 Skardi HTTP 后端。先检查现有数据和配置；如果任务、数据源或需要返回的结果不明确，先问我再生成文件。创建只读的 context 和 semantics 定义，并为该任务添加一份只含 SELECT 的 YAML pipeline。不要暴露通用 SQL endpoint，不写入数据，也不修改 Schema。启动 skardi-server，用一次请求验证 endpoint，最后说明配置文件、endpoint、请求和响应。
```

可运行的参考见 [pipelines](docs/pipelines.md) 和[简单后端 demo](demo/simple_backend/)。

---

## 连接你自己的数据

当你需要具名数据库数据源或共享的 Agent endpoint 时，再将一份小而可审查的数据约定放进代码库。

### 1. 只注册当前任务需要的数据源

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

### 2. 写下开发者已审核的业务含义

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

### 3. 将重复任务收敛成窄接口

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

Server 运行的是具名 pipeline，而不是暴露一个通用 SQL endpoint。除非你明确设置 `access_mode: read_write`，否则数据源均为只读；配置加载时会拒绝 pipeline 中的 DDL。精确的当前行为见[面向 Agent 的 context 边界](docs/agent_data_plane.md)。

---

## 从 Agent 中使用 Skardi

任何带有 shell 工具的编程 Agent 都可以调用 CLI。进行本地排查时，先让它读取已审核的 schema 和 semantics：

```bash
skardi query --ctx ctx.yaml --semantics semantics.yaml --schema --all
```

然后执行范围受控的查询：

```bash
skardi query --ctx ctx.yaml --sql "SELECT status, COUNT(*) FROM orders GROUP BY status"
```

对于共享或重复发生的任务，请使用 pipeline。Server 会将它暴露为 `POST /:name/execute`，参数由其中的 SQL 推导。

---

## 数据源与能力

Skardi 可以跨以下数据查询和 join：

- **数据库：**PostgreSQL、MySQL、SQLite、MongoDB、Redis、DynamoDB、SeekDB 和 InfluxDB 3。
- **文件和湖仓：**CSV、JSON / NDJSON、Parquet、Lance、Apache Iceberg，以及位于 S3、GCS 或 Azure Blob Storage 的文件。
- **文档与检索工作流：**文档解析、全文搜索、向量搜索、混合搜索和 embeddings。

可运行的配置示例见[数据源指南](docs/)。Skardi 的引擎构建于 [Apache DataFusion](https://datafusion.apache.org/)，当任务需要 join 已注册的数据源时，支持 federated SQL。

---

## 示例

- [简单后端](demo/simple_backend/) —— 将一个小型 SQLite 后端暴露为 REST endpoints。
- [Agent 原生 wiki](demo/llm_wiki/) —— 混合检索、内联 embeddings 和面向 Agent 的动词。
- [RAG](demo/rag/) —— 端到端的检索增强生成工作流。
- [电影推荐](demo/movie_recommendation/) —— 在查询 pipeline 中运行 ONNX 模型推理。

---

## 文档

- [CLI guide](docs/cli.md)
- [Server 和 REST API](docs/server.md)
- [Pipeline 格式](docs/pipelines.md)
- [Semantics YAML](docs/semantics.md)
- [面向 Agent 的 context 边界](docs/agent_data_plane.md)
- [Federated queries](docs/federated-queries.md)

---

## 架构

<details>
<summary>查看开源架构</summary>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="asset/architecture-open-source.svg">
    <img src="asset/architecture-open-source.gif" alt="Skardi 开源架构" width="100%">
  </picture>
</p>

</details>

---

## 贡献与社区

Skardi 正在公开构建。欢迎提交 [issue](https://github.com/SkardiLabs/skardi/issues)、在 [Discord](https://discord.gg/S5YQQPEV2m) 发起讨论，或发送 pull request。本地开发命令和贡献规则见 [AGENTS.md](AGENTS.md)。

## 许可证

[Apache 2.0](LICENSE)
