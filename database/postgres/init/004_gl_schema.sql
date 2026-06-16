-- 004_gl_schema.sql
-- General Ledger schema — a faithful mirror of the Operix cloud accounting core
-- (gl_accounts, journal_entries, journal_entry_lines) so the offline books tie
-- out identically and can sync to the cloud later.
--
-- Differences from the cloud, by design:
--   * No tenant_id — each offline install is a single business.
--   * Money columns are NUMERIC(15,2) (header) / NUMERIC(14,2) (lines), matching
--     the cloud's decimal(15,2) / decimal(14,2).
-- Idempotent: safe to re-apply to an existing volume.

-- Chart of accounts ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS gl_accounts (
  id BIGSERIAL PRIMARY KEY,
  code VARCHAR(20) NOT NULL UNIQUE,
  name VARCHAR(180) NOT NULL,
  name_ar VARCHAR(180),
  account_type VARCHAR(20) NOT NULL
    CHECK (account_type IN ('asset','liability','equity','revenue','expense')),
  normal_balance VARCHAR(6) NOT NULL
    CHECK (normal_balance IN ('debit','credit')),
  parent_id BIGINT REFERENCES gl_accounts(id) ON DELETE SET NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  is_system BOOLEAN NOT NULL DEFAULT FALSE,
  is_cogs BOOLEAN NOT NULL DEFAULT FALSE,
  allows_manual_posting BOOLEAN NOT NULL DEFAULT TRUE,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS gl_accounts_type_idx ON gl_accounts(account_type);
CREATE INDEX IF NOT EXISTS gl_accounts_parent_idx ON gl_accounts(parent_id);

-- Journal entries -----------------------------------------------------------
-- Replace the 001 placeholder (entry_number/total_debit/total_credit) with the
-- cloud-faithful structure. No real GL data exists yet at this stage.
DROP TABLE IF EXISTS journal_entries CASCADE;
CREATE TABLE journal_entries (
  id BIGSERIAL PRIMARY KEY,
  reference_no VARCHAR(50) NOT NULL UNIQUE,
  source_type VARCHAR(100),               -- e.g. 'sales_invoice', 'opening_balance'
  source_id BIGINT,                        -- PK of the source document
  entry_type VARCHAR(50),                  -- e.g. 'invoice_posting', 'invoice_cogs'
  description TEXT,
  transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
  posted_at TIMESTAMPTZ,
  status VARCHAR(10) NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft','posted','reversed')),
  currency_code VARCHAR(10),               -- NULL = functional currency
  exchange_rate NUMERIC(15,6),
  created_by BIGINT,                        -- users(id); no FK to avoid load-order coupling
  reversed_entry_id BIGINT REFERENCES journal_entries(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Idempotency for document postings: one POSTED entry per (source, entry_type),
-- while still allowing a REVERSED row plus a fresh POSTED row (re-posting after a
-- reversal). Mirrors the cloud's (tenant, source_type, source_id, entry_type,
-- status) unique constraint, minus tenant.
CREATE UNIQUE INDEX journal_entries_source_uidx
  ON journal_entries(source_type, source_id, entry_type, status)
  WHERE source_type IS NOT NULL;
CREATE INDEX journal_entries_date_idx ON journal_entries(transaction_date);
CREATE INDEX journal_entries_status_idx ON journal_entries(status);
CREATE INDEX journal_entries_source_idx ON journal_entries(source_type, source_id);

-- Journal entry lines -------------------------------------------------------
-- Explicit debit/credit lines; amounts are always positive (never negative).
CREATE TABLE IF NOT EXISTS journal_entry_lines (
  id BIGSERIAL PRIMARY KEY,
  journal_entry_id BIGINT NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE,
  gl_account_id BIGINT NOT NULL REFERENCES gl_accounts(id),
  line_type VARCHAR(6) NOT NULL CHECK (line_type IN ('debit','credit')),
  amount NUMERIC(14,2) NOT NULL CHECK (amount >= 0),
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS jel_account_idx ON journal_entry_lines(gl_account_id);
CREATE INDEX IF NOT EXISTS jel_entry_idx ON journal_entry_lines(journal_entry_id, line_type);

-- Human-readable reference numbers: JE-000001, JE-000002, …
CREATE SEQUENCE IF NOT EXISTS journal_entry_seq START 1;
