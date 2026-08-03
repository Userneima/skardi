# Controlled Database Debugging Demo

This is a small, repeatable Hero Demo candidate for one concrete question:

> Why did Acme Robotics' payment fail after the latest checkout change?

The demo uses fake SQLite data. It shows Skardi giving an agent the table and column meanings it needs, returning only the diagnostic rows for the question, and refusing unsafe operations before the server starts.

## What It Verifies

1. `semantics.yaml` makes table and column meanings visible to the CLI and server catalog.
2. The diagnostic endpoint returns the failed payment and processor response needed to investigate Acme Robotics.
3. An `UPDATE` pipeline is rejected because both registered tables are `read_only`.
4. A `DROP TABLE` pipeline is rejected as DDL.

It does not claim per-agent permissions, audit history, rollback, or lineage for a synchronous write.

## Run The Full Check

From the repository root:

```bash
bash demo/controlled_db_debugging/verify.sh
```

The script creates an ignored `staging.db`, builds the local binaries as needed, checks the semantic catalog, confirms the two unsafe pipelines fail at startup, then starts a safe endpoint and checks its JSON response.

## Three-Minute Walkthrough

```bash
# 1. Create only fake staging data.
bash demo/controlled_db_debugging/setup.sh

# 2. Show what the agent can understand before querying.
cargo run -p skardi-cli --no-default-features -- query \
  --ctx demo/controlled_db_debugging/ctx.yaml \
  --semantics demo/controlled_db_debugging/semantics.yaml \
  --schema --all

# 3. Prove unsafe pipelines are rejected, then run the safe endpoint.
bash demo/controlled_db_debugging/verify.sh
```

The expected diagnosis is that Acme Robotics has a `card_declined` payment with `issuer_declined_after_3ds`. The demo intentionally stops there: it investigates the issue but cannot refund, alter, or drop data.
