#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DEMO_DIR="$REPO_ROOT/demo/controlled_db_debugging"
CTX="$DEMO_DIR/ctx.yaml"
SEMANTICS="$DEMO_DIR/semantics.yaml"
SAFE_PIPELINE="$DEMO_DIR/pipelines/diagnose_failed_payments.yaml"
PORT="${SKARDI_DEMO_PORT:-18080}"
SERVER_URL="http://127.0.0.1:$PORT"
LOG_FILE="$DEMO_DIR/server.log"
SERVER_PID=""

# The CLI is a thin HTTP client: it holds no engine, so every check below runs
# against a server this script owns. Steps that must fail (unsafe pipelines)
# are checked at server startup, before anything is served.
skardi_cli() {
  cargo run -q -p skardi-cli --bin skardi -- --server "$SERVER_URL" "$@"
}

cleanup() {
  if [[ -n "$SERVER_PID" ]] && kill -0 "$SERVER_PID" 2>/dev/null; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

expect_startup_rejection() {
  local pipeline="$1"
  local expected_text="$2"
  local output

  if output="$(cargo run -q -p skardi-server --bin skardi-server -- \
    --ctx "$CTX" \
    --pipeline "$pipeline" \
    --semantics "$SEMANTICS" \
    --port "$PORT" 2>&1)"; then
    echo "Expected server startup to reject $pipeline, but it succeeded." >&2
    exit 1
  fi

  if ! grep -Fq "$expected_text" <<<"$output"; then
    echo "Server rejected $pipeline, but not for the expected reason:" >&2
    printf '%s\n' "$output" >&2
    exit 1
  fi

  echo "Verified rejection: $(basename "$pipeline")"
}

cd "$REPO_ROOT"
bash "$DEMO_DIR/setup.sh"

echo "== 1. Unsafe operations are rejected before serving =="
expect_startup_rejection "$DEMO_DIR/pipelines/attempt_refund.yaml" "configured with 'read_only' access mode"
expect_startup_rejection "$DEMO_DIR/pipelines/attempt_drop_table.yaml" "DDL operation not allowed"

echo "== 2. Start the server on the safe pipeline =="
cargo run -q -p skardi-server --bin skardi-server -- \
  --ctx "$CTX" \
  --pipeline "$SAFE_PIPELINE" \
  --semantics "$SEMANTICS" \
  --port "$PORT" >"$LOG_FILE" 2>&1 &
SERVER_PID=$!

for _ in $(seq 1 60); do
  if curl --fail --silent "$SERVER_URL/health" >/dev/null; then
    break
  fi
  sleep 0.5
done

if ! curl --fail --silent "$SERVER_URL/health" >/dev/null; then
  echo "Server did not become reachable at $SERVER_URL within 30s." >&2
  cat "$LOG_FILE" >&2
  exit 1
fi

echo "== 3. Agent-visible semantic context =="
# This is what a coding agent sees before it queries anything: the reviewed
# table and column meanings, fetched through the CLI from the running server.
skardi_cli schema >"$DEMO_DIR/catalog.json"

if ! grep -Fq 'Payment attempts from the checkout service' "$DEMO_DIR/catalog.json"; then
  echo "Server did not return the expected semantic catalog." >&2
  cat "$DEMO_DIR/catalog.json" >&2
  cat "$LOG_FILE" >&2
  exit 1
fi
cat "$DEMO_DIR/catalog.json"

echo "== 4. Run the safe diagnostic pipeline =="
skardi_cli run diagnose-failed-payments \
  -d '{"since":"2026-07-16T00:00:00Z"}' >"$DEMO_DIR/diagnosis.json"

if ! grep -Fq 'Acme Robotics' "$DEMO_DIR/diagnosis.json" || ! grep -Fq 'issuer_declined_after_3ds' "$DEMO_DIR/diagnosis.json"; then
  echo "Diagnostic pipeline did not return the expected staging result." >&2
  cat "$DEMO_DIR/diagnosis.json" >&2
  exit 1
fi
cat "$DEMO_DIR/diagnosis.json"

echo "Verified safe diagnostic result: Acme Robotics failed after 3DS."
