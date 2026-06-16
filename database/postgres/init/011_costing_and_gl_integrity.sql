-- 011_costing_and_gl_integrity.sql
-- Finance-review remediation (sales & purchase invoice correctness):
--   1. Capture the exact unit cost relieved on each sale line (pos + invoice) and
--      each return line, so COGS and return reversals are posted at the real cost
--      basis instead of being re-derived from the product's *current* cost.
--   2. Add a recoverable Input VAT account (1400) so purchase input tax no longer
--      shares the 2200 "Tax Payable" output-VAT account.
--   3. Enforce double-entry balance at the database level: a deferred constraint
--      trigger rejects any POSTED journal entry whose debits != credits at commit.
-- Idempotent: safe to re-apply to an existing volume.

-- 1. Per-line captured cost --------------------------------------------------
ALTER TABLE pos_order_items     ADD COLUMN IF NOT EXISTS unit_cost NUMERIC(14, 2) NOT NULL DEFAULT 0;
ALTER TABLE sales_invoice_items ADD COLUMN IF NOT EXISTS unit_cost NUMERIC(14, 2) NOT NULL DEFAULT 0;
ALTER TABLE sales_return_items  ADD COLUMN IF NOT EXISTS unit_cost NUMERIC(14, 2) NOT NULL DEFAULT 0;

-- 2. Input VAT (recoverable) — separate from output VAT (2200) ----------------
INSERT INTO gl_accounts (code, name, name_ar, account_type, normal_balance, parent_id, is_system, is_cogs)
VALUES ('1400', 'Input VAT (Recoverable)', 'ضريبة القيمة المضافة على المشتريات', 'asset', 'debit',
        (SELECT id FROM gl_accounts WHERE code='1000'), TRUE, FALSE)
ON CONFLICT (code) DO NOTHING;

-- 3. Database-level balance enforcement --------------------------------------
-- Runs at COMMIT (deferred) so the per-line inserts of a single entry are allowed
-- to be transiently unbalanced; only the committed result is checked.
CREATE OR REPLACE FUNCTION assert_journal_entry_balanced() RETURNS TRIGGER AS $$
DECLARE
  v_entry  BIGINT := COALESCE(NEW.journal_entry_id, OLD.journal_entry_id);
  v_status TEXT;
  v_debit  NUMERIC(18, 2);
  v_credit NUMERIC(18, 2);
BEGIN
  -- The entry may have been deleted (cascade) by commit time — nothing to check.
  SELECT status INTO v_status FROM journal_entries WHERE id = v_entry;
  IF v_status IS NULL OR v_status <> 'posted' THEN
    RETURN NULL;
  END IF;

  SELECT
    COALESCE(SUM(amount) FILTER (WHERE line_type = 'debit'),  0),
    COALESCE(SUM(amount) FILTER (WHERE line_type = 'credit'), 0)
  INTO v_debit, v_credit
  FROM journal_entry_lines
  WHERE journal_entry_id = v_entry;

  IF v_debit <> v_credit THEN
    RAISE EXCEPTION 'Journal entry % is unbalanced: debits=% credits=%',
      v_entry, v_debit, v_credit;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS journal_entry_lines_balanced ON journal_entry_lines;
CREATE CONSTRAINT TRIGGER journal_entry_lines_balanced
  AFTER INSERT OR UPDATE OR DELETE ON journal_entry_lines
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW EXECUTE FUNCTION assert_journal_entry_balanced();
