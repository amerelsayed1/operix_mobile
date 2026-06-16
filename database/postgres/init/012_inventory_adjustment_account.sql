-- 012_inventory_adjustment_account.sql
-- Finance-review remediation: manual stock adjustments must hit the GL so the
-- Inventory control account (1300) keeps tying out to the physical subledger.
-- A positive adjustment (found / opening stock) debits Inventory; a negative
-- adjustment (damage / loss / shrinkage) credits Inventory; the contra side is
-- this Inventory Adjustment expense account (a net debit = loss, net credit =
-- gain). Idempotent: safe to re-apply.

INSERT INTO gl_accounts (code, name, name_ar, account_type, normal_balance, parent_id, is_system, is_cogs)
VALUES ('5300', 'Inventory Adjustment', 'تسويات المخزون', 'expense', 'debit',
        (SELECT id FROM gl_accounts WHERE code='5000'), TRUE, FALSE)
ON CONFLICT (code) DO NOTHING;
