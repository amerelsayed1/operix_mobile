-- 002_pos_schema.sql
-- Point of Sale: local users, cashier shifts, order payments, and richer
-- product catalogue. Idempotent so it can be re-applied to an existing volume
-- (the docker-entrypoint only runs init scripts on a fresh data directory).

-- ---------------------------------------------------------------------------
-- Local users (authentication). Passwords are stored as PBKDF2-HMAC-SHA256
-- hashes produced by the Flutter client (format: pbkdf2_sha256$iters$salt$hash).
-- Default users are seeded by the app on first launch, not here, so that the
-- hashing stays in a single place.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id BIGSERIAL PRIMARY KEY,
  username VARCHAR(60) NOT NULL UNIQUE,
  full_name VARCHAR(160) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(40) NOT NULL DEFAULT 'cashier',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_login_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS users_active_idx ON users(is_active);

-- ---------------------------------------------------------------------------
-- Cashier shifts (open / close with cash reconciliation).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS pos_shifts (
  id BIGSERIAL PRIMARY KEY,
  shift_number VARCHAR(40) NOT NULL UNIQUE,
  cashier_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
  cashier_name VARCHAR(160) NOT NULL,
  opening_float NUMERIC(14, 2) NOT NULL DEFAULT 0,
  expected_cash NUMERIC(14, 2),
  counted_cash NUMERIC(14, 2),
  cash_difference NUMERIC(14, 2),
  status VARCHAR(20) NOT NULL DEFAULT 'open', -- open | closed
  notes TEXT,
  opened_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  closed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS pos_shifts_status_idx ON pos_shifts(status);
CREATE INDEX IF NOT EXISTS pos_shifts_cashier_idx ON pos_shifts(cashier_id);

-- ---------------------------------------------------------------------------
-- Extend pos_orders with cashier / shift / money breakdown columns.
-- ---------------------------------------------------------------------------
ALTER TABLE pos_orders ADD COLUMN IF NOT EXISTS shift_id BIGINT REFERENCES pos_shifts(id) ON DELETE SET NULL;
ALTER TABLE pos_orders ADD COLUMN IF NOT EXISTS cashier_id BIGINT REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE pos_orders ADD COLUMN IF NOT EXISTS cashier_name VARCHAR(160);
ALTER TABLE pos_orders ADD COLUMN IF NOT EXISTS customer_name VARCHAR(180);
ALTER TABLE pos_orders ADD COLUMN IF NOT EXISTS subtotal NUMERIC(14, 2) NOT NULL DEFAULT 0;
ALTER TABLE pos_orders ADD COLUMN IF NOT EXISTS discount_amount NUMERIC(14, 2) NOT NULL DEFAULT 0;
ALTER TABLE pos_orders ADD COLUMN IF NOT EXISTS tax_amount NUMERIC(14, 2) NOT NULL DEFAULT 0;
ALTER TABLE pos_orders ADD COLUMN IF NOT EXISTS paid_amount NUMERIC(14, 2) NOT NULL DEFAULT 0;
ALTER TABLE pos_orders ADD COLUMN IF NOT EXISTS change_amount NUMERIC(14, 2) NOT NULL DEFAULT 0;
ALTER TABLE pos_orders ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'completed'; -- completed | voided

CREATE INDEX IF NOT EXISTS pos_orders_shift_idx ON pos_orders(shift_id);

-- ---------------------------------------------------------------------------
-- Per-order payment lines (supports split payments and custom methods).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS pos_order_payments (
  id BIGSERIAL PRIMARY KEY,
  pos_order_id BIGINT NOT NULL REFERENCES pos_orders(id) ON DELETE CASCADE,
  method VARCHAR(20) NOT NULL,        -- cash | card | custom
  method_label VARCHAR(60),           -- free text for custom methods
  amount NUMERIC(14, 2) NOT NULL DEFAULT 0,
  reference VARCHAR(120),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS pos_order_payments_order_idx ON pos_order_payments(pos_order_id);

-- ---------------------------------------------------------------------------
-- Sequences for human-friendly document numbers.
-- ---------------------------------------------------------------------------
CREATE SEQUENCE IF NOT EXISTS pos_receipt_seq START 10500;
CREATE SEQUENCE IF NOT EXISTS pos_shift_seq START 1001;

-- No data is seeded. The first administrator account is created from the app's
-- first-run setup screen; all business data is entered by the user.
