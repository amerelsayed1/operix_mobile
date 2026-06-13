-- 003_products_extend.sql  (loaded automatically on a fresh volume after 001/002)
-- Extend products to cover the full "create product" form (mirrors the Operix
-- web product model). Idempotent; can be re-applied to an existing volume.
--
-- Field mapping (local column <- web field):
--   unit_price        <- selling_price
--   reorder_level     <- minimum_stock_alert
--   quantity_on_hand  <- stock on hand / opening stock

ALTER TABLE products ADD COLUMN IF NOT EXISTS barcode VARCHAR(80);
ALTER TABLE products ADD COLUMN IF NOT EXISTS unit VARCHAR(40) NOT NULL DEFAULT 'Piece';
ALTER TABLE products ADD COLUMN IF NOT EXISTS cost_price NUMERIC(14, 2) NOT NULL DEFAULT 0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE;

CREATE INDEX IF NOT EXISTS products_active_idx ON products(is_active);
CREATE INDEX IF NOT EXISTS products_category_idx ON products(category);
CREATE INDEX IF NOT EXISTS products_barcode_idx ON products(barcode);
