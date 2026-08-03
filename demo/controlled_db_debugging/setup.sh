#!/usr/bin/env bash
set -euo pipefail

DEMO_DIR="$(cd "$(dirname "$0")" && pwd)"
DB="$DEMO_DIR/staging.db"

rm -f "$DB"

sqlite3 "$DB" <<'SQL'
CREATE TABLE customers (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    plan TEXT NOT NULL
);

CREATE TABLE payments (
    id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    amount_cents INTEGER NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('captured', 'failed')),
    failure_code TEXT,
    processor_response TEXT,
    created_at TEXT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(id)
);

INSERT INTO customers (id, name, plan) VALUES
    (1, 'Acme Robotics', 'growth'),
    (2, 'Northstar Design', 'starter'),
    (3, 'Cedar Labs', 'growth');

INSERT INTO payments (
    id, customer_id, amount_cents, status, failure_code, processor_response, created_at
) VALUES
    (101, 1, 4900, 'captured', NULL, NULL, '2026-07-15T09:12:00Z'),
    (102, 1, 4900, 'failed', 'card_declined', 'issuer_declined_after_3ds', '2026-07-16T08:35:00Z'),
    (103, 2, 1200, 'failed', 'insufficient_funds', 'issuer_declined', '2026-07-16T09:10:00Z'),
    (104, 3, 4900, 'captured', NULL, NULL, '2026-07-16T10:00:00Z');
SQL

echo "Created staging database: $DB"
