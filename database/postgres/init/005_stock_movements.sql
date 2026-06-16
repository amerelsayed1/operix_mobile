-- 005_stock_movements.sql
-- Stock movement audit log + manual adjustments. Mirrors the cloud
-- stock_movements table (single-tenant, no tenant_id). Every change to a
-- product's on-hand quantity is recorded here: POS sales, manual adjustments,
-- corrections, and (later) purchases and returns. Idempotent.

CREATE TABLE IF NOT EXISTS stock_movements (
  id BIGSERIAL PRIMARY KEY,
  product_id BIGINT REFERENCES products(id) ON DELETE SET NULL,
  type VARCHAR(30) NOT NULL,        -- pos_sale | adjustment | correction | purchase | sales_return | supplier_return | opening_stock
  quantity INTEGER NOT NULL,        -- signed: positive = stock in, negative = stock out
  reason VARCHAR(120),              -- adjustments: damage | loss | theft | recount | found | other
  note TEXT,
  reference_type VARCHAR(50),       -- e.g. 'pos_order'
  reference_id BIGINT,              -- PK of the source document
  created_by BIGINT,                -- users(id); no FK to avoid load-order coupling
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS stock_movements_product_idx ON stock_movements(product_id, created_at);
CREATE INDEX IF NOT EXISTS stock_movements_type_idx ON stock_movements(type);
CREATE INDEX IF NOT EXISTS stock_movements_created_idx ON stock_movements(created_at);
