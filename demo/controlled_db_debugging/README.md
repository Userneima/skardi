# Controlled Database Debugging Demo

This is a small, repeatable Hero Demo candidate for one concrete question:

> Why did Acme Robotics' payment fail after the latest checkout change?

The demo uses fake SQLite data. It shows Skardi giving an agent the table and column meanings it needs, returning only the diagnostic rows for the question, and refusing unsafe operations before the server starts.

## What It Verifies

1. An `UPDATE` pipeline is rejected because both registered tables are `read_only`.
2. A `DROP TABLE` pipeline is rejected as DDL — both rejections happen at server startup, before anything is served.
3. `semantics.yaml` makes table and column meanings visible in the server catalog the agent reads.
4. The diagnostic pipeline returns the failed payment and processor response needed to investigate Acme Robotics.

It does not claim per-agent permissions, audit history, rollback, or lineage for a synchronous write.

## Run The Full Check

From the repository root:

```bash
bash demo/controlled_db_debugging/verify.sh
```

The script creates an ignored `staging.db`, builds the local binaries as needed, confirms the two unsafe pipelines fail at startup, then starts a server on the safe pipeline and checks both the semantic catalog and the diagnostic result through the CLI.

## Three-Minute Walkthrough

`skardi` is a thin HTTP client with no engine of its own, so a `skardi-server` has to be running before the CLI can see anything.

```bash
# 1. Create only fake staging data.
bash demo/controlled_db_debugging/setup.sh

# 2. Start a server on the safe pipeline (leave this running).
cargo run -p skardi-server --bin skardi-server -- \
  --ctx demo/controlled_db_debugging/ctx.yaml \
  --semantics demo/controlled_db_debugging/semantics.yaml \
  --pipeline demo/controlled_db_debugging/pipelines/diagnose_failed_payments.yaml \
  --port 18080

# 3. In a second terminal: show what the agent can understand before querying.
cargo run -p skardi-cli --bin skardi -- --server http://127.0.0.1:18080 schema

# 4. Ask the question through the reviewed pipeline.
cargo run -p skardi-cli --bin skardi -- --server http://127.0.0.1:18080 \
  run diagnose-failed-payments -d '{"since":"2026-07-16T00:00:00Z"}'

# 5. Prove the unsafe pipelines are rejected (and re-check everything above).
bash demo/controlled_db_debugging/verify.sh
```

The expected diagnosis is that Acme Robotics has a `card_declined` payment with `issuer_declined_after_3ds`. The demo intentionally stops there: it investigates the issue but cannot refund, alter, or drop data.
