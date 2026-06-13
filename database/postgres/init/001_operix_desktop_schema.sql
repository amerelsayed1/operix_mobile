-- 001_operix_desktop_schema.sql
-- Core local single-business schema. No sample data is seeded: the database
-- starts empty and is populated by the application and the business user.

CREATE TABLE IF NOT EXISTS company_profile (
  id SMALLINT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  business_name VARCHAR(160) NOT NULL,
  branch_name VARCHAR(120),
  logo_path TEXT,
  currency_code CHAR(3) NOT NULL DEFAULT 'EGP',
  locale VARCHAR(12) NOT NULL DEFAULT 'en',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS clients (
  id BIGSERIAL PRIMARY KEY,
  client_code VARCHAR(40) NOT NULL UNIQUE,
  name VARCHAR(180) NOT NULL,
  phone VARCHAR(60),
  receivable_balance NUMERIC(14, 2) NOT NULL DEFAULT 0,
  status VARCHAR(40) NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS suppliers (
  id BIGSERIAL PRIMARY KEY,
  supplier_code VARCHAR(40) NOT NULL UNIQUE,
  company_name VARCHAR(180) NOT NULL,
  phone VARCHAR(60),
  payable_balance NUMERIC(14, 2) NOT NULL DEFAULT 0,
  status VARCHAR(40) NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS products (
  id BIGSERIAL PRIMARY KEY,
  sku VARCHAR(80) NOT NULL UNIQUE,
  name VARCHAR(180) NOT NULL,
  category VARCHAR(120) NOT NULL DEFAULT 'General',
  quantity_on_hand INTEGER NOT NULL DEFAULT 0,
  reorder_level INTEGER NOT NULL DEFAULT 0,
  unit_price NUMERIC(14, 2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS pos_orders (
  id BIGSERIAL PRIMARY KEY,
  receipt_number VARCHAR(80) NOT NULL UNIQUE,
  total_amount NUMERIC(14, 2) NOT NULL DEFAULT 0,
  payment_status VARCHAR(40) NOT NULL DEFAULT 'paid',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS pos_order_items (
  id BIGSERIAL PRIMARY KEY,
  pos_order_id BIGINT NOT NULL REFERENCES pos_orders(id) ON DELETE CASCADE,
  product_id BIGINT REFERENCES products(id) ON DELETE SET NULL,
  name VARCHAR(180) NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  unit_price NUMERIC(14, 2) NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS sales_invoices (
  id BIGSERIAL PRIMARY KEY,
  invoice_number VARCHAR(80) NOT NULL UNIQUE,
  client_id BIGINT REFERENCES clients(id) ON DELETE SET NULL,
  status VARCHAR(40) NOT NULL DEFAULT 'draft',
  issue_date DATE NOT NULL DEFAULT CURRENT_DATE,
  total_amount NUMERIC(14, 2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS supplier_invoices (
  id BIGSERIAL PRIMARY KEY,
  invoice_number VARCHAR(80) NOT NULL UNIQUE,
  supplier_id BIGINT REFERENCES suppliers(id) ON DELETE SET NULL,
  status VARCHAR(40) NOT NULL DEFAULT 'pending',
  issue_date DATE NOT NULL DEFAULT CURRENT_DATE,
  total_amount NUMERIC(14, 2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS journal_entries (
  id BIGSERIAL PRIMARY KEY,
  entry_number VARCHAR(80) NOT NULL UNIQUE,
  status VARCHAR(40) NOT NULL DEFAULT 'draft',
  entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
  total_debit NUMERIC(14, 2) NOT NULL DEFAULT 0,
  total_credit NUMERIC(14, 2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS clients_status_idx ON clients(status);
CREATE INDEX IF NOT EXISTS suppliers_status_idx ON suppliers(status);
CREATE INDEX IF NOT EXISTS products_quantity_idx ON products(quantity_on_hand);
CREATE INDEX IF NOT EXISTS pos_orders_created_idx ON pos_orders(created_at);
CREATE INDEX IF NOT EXISTS sales_invoices_date_idx ON sales_invoices(issue_date);
CREATE INDEX IF NOT EXISTS supplier_invoices_date_idx ON supplier_invoices(issue_date);
CREATE INDEX IF NOT EXISTS journal_entries_date_idx ON journal_entries(entry_date);
