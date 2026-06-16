-- 006_sales_returns.sql
-- Sales returns / refunds against a POS order. Mirrors the cloud sales_returns
-- core (single-tenant). Returning items restocks them (see stock_movements with
-- type='sales_return') and records the refund. Idempotent.

CREATE TABLE IF NOT EXISTS sales_returns (
  id BIGSERIAL PRIMARY KEY,
  return_number VARCHAR(80) NOT NULL UNIQUE,
  pos_order_id BIGINT REFERENCES pos_orders(id) ON DELETE SET NULL,
  cashier_id BIGINT,
  cashier_name VARCHAR(160),
  reason TEXT,
  refund_method VARCHAR(20) NOT NULL DEFAULT 'cash',  -- cash | credit
  total_amount NUMERIC(14, 2) NOT NULL DEFAULT 0,
  status VARCHAR(20) NOT NULL DEFAULT 'completed',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sales_return_items (
  id BIGSERIAL PRIMARY KEY,
  sales_return_id BIGINT NOT NULL REFERENCES sales_returns(id) ON DELETE CASCADE,
  product_id BIGINT REFERENCES products(id) ON DELETE SET NULL,
  name VARCHAR(180) NOT NULL,
  quantity INTEGER NOT NULL,
  unit_price NUMERIC(14, 2) NOT NULL,
  line_total NUMERIC(14, 2) NOT NULL
);

CREATE INDEX IF NOT EXISTS sales_returns_order_idx ON sales_returns(pos_order_id);
CREATE INDEX IF NOT EXISTS sales_returns_created_idx ON sales_returns(created_at);
CREATE INDEX IF NOT EXISTS sales_return_items_return_idx ON sales_return_items(sales_return_id);

CREATE SEQUENCE IF NOT EXISTS sales_return_seq START 1;
