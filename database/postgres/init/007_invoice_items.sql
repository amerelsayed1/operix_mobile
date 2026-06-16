-- 007_invoice_items.sql
-- Connect formal invoices to the product catalogue. Until now sales_invoices and
-- supplier_invoices only carried a header total with no line detail, so an
-- invoice could not reference the inventory items it was for. These line-item
-- tables close that gap (mirroring pos_order_items / sales_return_items) and also
-- link POS orders to a client account. Idempotent: safe to re-apply.

-- Sales invoice lines -------------------------------------------------------
CREATE TABLE IF NOT EXISTS sales_invoice_items (
  id BIGSERIAL PRIMARY KEY,
  sales_invoice_id BIGINT NOT NULL REFERENCES sales_invoices(id) ON DELETE CASCADE,
  product_id BIGINT REFERENCES products(id) ON DELETE SET NULL,
  name VARCHAR(180) NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  unit_price NUMERIC(14, 2) NOT NULL DEFAULT 0,
  line_total NUMERIC(14, 2) NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS sales_invoice_items_invoice_idx ON sales_invoice_items(sales_invoice_id);
CREATE INDEX IF NOT EXISTS sales_invoice_items_product_idx ON sales_invoice_items(product_id);

-- Supplier (purchase) invoice lines -----------------------------------------
CREATE TABLE IF NOT EXISTS supplier_invoice_items (
  id BIGSERIAL PRIMARY KEY,
  supplier_invoice_id BIGINT NOT NULL REFERENCES supplier_invoices(id) ON DELETE CASCADE,
  product_id BIGINT REFERENCES products(id) ON DELETE SET NULL,
  name VARCHAR(180) NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  unit_price NUMERIC(14, 2) NOT NULL DEFAULT 0,
  line_total NUMERIC(14, 2) NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS supplier_invoice_items_invoice_idx ON supplier_invoice_items(supplier_invoice_id);
CREATE INDEX IF NOT EXISTS supplier_invoice_items_product_idx ON supplier_invoice_items(product_id);

-- Link POS orders to a client account (was free-text customer_name only) -----
ALTER TABLE pos_orders ADD COLUMN IF NOT EXISTS client_id BIGINT REFERENCES clients(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS pos_orders_client_idx ON pos_orders(client_id);

-- Invoice header subtotal / tax so the lines tie out to the total -----------
ALTER TABLE sales_invoices ADD COLUMN IF NOT EXISTS subtotal NUMERIC(14, 2) NOT NULL DEFAULT 0;
ALTER TABLE sales_invoices ADD COLUMN IF NOT EXISTS tax_amount NUMERIC(14, 2) NOT NULL DEFAULT 0;
ALTER TABLE supplier_invoices ADD COLUMN IF NOT EXISTS subtotal NUMERIC(14, 2) NOT NULL DEFAULT 0;
ALTER TABLE supplier_invoices ADD COLUMN IF NOT EXISTS tax_amount NUMERIC(14, 2) NOT NULL DEFAULT 0;

-- Human-friendly invoice numbers for seeded / app-created documents.
CREATE SEQUENCE IF NOT EXISTS sales_invoice_seq START 1;
CREATE SEQUENCE IF NOT EXISTS supplier_invoice_seq START 1;
