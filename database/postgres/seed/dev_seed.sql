-- dev_seed.sql — OPTIONAL development/test data.
--
-- NOT in the auto-init directory: production starts empty by design. Run this by
-- hand when you want sample data to exercise POS, Reports, Stock log, etc.:
--
--   docker exec -i operix-mobile-postgres psql -U operix -d operix < database/postgres/seed/dev_seed.sql
--
-- Idempotent: catalogue/parties/accounts use ON CONFLICT; the sales block is
-- guarded so re-running won't duplicate orders. It does NOT seed a login user —
-- create the admin from the app's first-run setup (password hashing lives there).

-- ── Products ────────────────────────────────────────────────────────────────
INSERT INTO products (sku, name, category, quantity_on_hand, reorder_level, unit_price, cost_price, unit, barcode, is_active) VALUES
  ('BEV-001', 'Bottled Water 500ml', 'Beverages', 200, 40, 10, 6,  'Piece', '6221031070011', TRUE),
  ('BEV-002', 'Cola Can 330ml',      'Beverages', 150, 30, 15, 9,  'Piece', '6221031070028', TRUE),
  ('BEV-003', 'Orange Juice 1L',     'Beverages',  60, 15, 35, 22, 'Piece', '6221031070035', TRUE),
  ('SNK-001', 'Potato Chips',        'Snacks',    120, 25, 25, 15, 'Piece', '6221031070042', TRUE),
  ('SNK-002', 'Chocolate Bar',       'Snacks',     90, 20, 20, 12, 'Piece', '6221031070059', TRUE),
  ('SNK-003', 'Salted Peanuts',      'Snacks',     75, 20, 18, 10, 'Piece', '6221031070066', TRUE),
  ('BAK-001', 'White Bread',         'Bakery',     40, 20, 22, 13, 'Piece', '6221031070073', TRUE),
  ('BAK-002', 'Croissant',           'Bakery',     35, 40, 16, 9,  'Piece', '6221031070080', TRUE),
  ('DRY-001', 'Milk 1L',             'Dairy',      50, 20, 30, 20, 'Piece', '6221031070097', TRUE),
  ('DRY-002', 'Yogurt 200g',         'Dairy',      80, 25, 12, 7,  'Piece', '6221031070103', TRUE),
  ('HOU-001', 'Dish Soap 500ml',     'Household',  30, 15, 45, 28, 'Piece', '6221031070110', TRUE),
  ('HOU-002', 'Paper Towels',        'Household',  25, 30, 38, 24, 'Piece', '6221031070127', TRUE)
ON CONFLICT (sku) DO NOTHING;

-- ── Clients & suppliers ─────────────────────────────────────────────────────
INSERT INTO clients (client_code, name, phone, receivable_balance, status) VALUES
  ('CL-001', 'Walk-in Client',      NULL,          0,    'active'),
  ('CL-002', 'Cafe Downtown',       '01000000001', 1250, 'active'),
  ('CL-003', 'Green Grocer',        '01000000002', 0,    'active'),
  ('CL-004', 'Sunrise Restaurant',  '01000000003', 430,  'active')
ON CONFLICT (client_code) DO NOTHING;

INSERT INTO suppliers (supplier_code, company_name, phone, payable_balance, status) VALUES
  ('SUP-001', 'Nile Beverages Co.',   '0220000001', 3200, 'active'),
  ('SUP-002', 'Cairo Snacks Ltd.',    '0220000002', 0,    'active'),
  ('SUP-003', 'Delta Dairy Supply',   '0220000003', 980,  'active')
ON CONFLICT (supplier_code) DO NOTHING;

-- ── Starter chart of accounts ───────────────────────────────────────────────
INSERT INTO gl_accounts (code, name, name_ar, account_type, normal_balance, is_system) VALUES
  ('1000', 'Assets',              'الأصول',            'asset',     'debit',  TRUE),
  ('2000', 'Liabilities',         'الخصوم',            'liability', 'credit', TRUE),
  ('3000', 'Equity',              'حقوق الملكية',       'equity',    'credit', TRUE),
  ('4000', 'Revenue',             'الإيرادات',          'revenue',   'credit', TRUE),
  ('5000', 'Expenses',            'المصروفات',          'expense',   'debit',  TRUE)
ON CONFLICT (code) DO NOTHING;

INSERT INTO gl_accounts (code, name, name_ar, account_type, normal_balance, parent_id, is_system, is_cogs) VALUES
  ('1100', 'Cash',                  'النقدية',           'asset',     'debit',  (SELECT id FROM gl_accounts WHERE code='1000'), TRUE, FALSE),
  ('1200', 'Accounts Receivable',   'الذمم المدينة',      'asset',     'debit',  (SELECT id FROM gl_accounts WHERE code='1000'), TRUE, FALSE),
  ('1300', 'Inventory',             'المخزون',           'asset',     'debit',  (SELECT id FROM gl_accounts WHERE code='1000'), TRUE, FALSE),
  ('1400', 'Input VAT (Recoverable)','ضريبة القيمة المضافة على المشتريات', 'asset', 'debit', (SELECT id FROM gl_accounts WHERE code='1000'), TRUE, FALSE),
  ('2100', 'Accounts Payable',      'الذمم الدائنة',      'liability', 'credit', (SELECT id FROM gl_accounts WHERE code='2000'), TRUE, FALSE),
  ('2200', 'Tax Payable',           'ضرائب مستحقة',       'liability', 'credit', (SELECT id FROM gl_accounts WHERE code='2000'), TRUE, FALSE),
  ('3100', 'Owner Capital',         'رأس المال',          'equity',    'credit', (SELECT id FROM gl_accounts WHERE code='3000'), TRUE, FALSE),
  ('3200', 'Retained Earnings',     'الأرباح المحتجزة',    'equity',    'credit', (SELECT id FROM gl_accounts WHERE code='3000'), TRUE, FALSE),
  ('4100', 'Sales Revenue',         'إيرادات المبيعات',    'revenue',   'credit', (SELECT id FROM gl_accounts WHERE code='4000'), TRUE, FALSE),
  ('5100', 'Cost of Goods Sold',    'تكلفة البضاعة المباعة','expense',  'debit',  (SELECT id FROM gl_accounts WHERE code='5000'), TRUE, TRUE),
  ('5200', 'Operating Expenses',    'مصروفات تشغيلية',     'expense',   'debit',  (SELECT id FROM gl_accounts WHERE code='5000'), TRUE, FALSE),
  ('5300', 'Inventory Adjustment',  'تسويات المخزون',      'expense',   'debit',  (SELECT id FROM gl_accounts WHERE code='5000'), TRUE, FALSE)
ON CONFLICT (code) DO NOTHING;

-- ── Shifts, sales history, stock movements (guarded, runs once) ──────────────
DO $$
DECLARE
  sh1 BIGINT;  -- closed shift (older)
  sh2 BIGINT;  -- open shift (today)
BEGIN
  IF EXISTS (SELECT 1 FROM pos_orders WHERE receipt_number LIKE 'SEED-%') THEN
    RAISE NOTICE 'Seed sales already present; skipping the sales block.';
    RETURN;
  END IF;

  INSERT INTO pos_shifts (shift_number, cashier_name, opening_float, expected_cash, counted_cash, cash_difference, status, opened_at, closed_at)
  VALUES ('SEED-SH-01', 'Seed Cashier', 500, 1290, 1290, 0, 'closed', NOW() - interval '2 days', NOW() - interval '2 days' + interval '8 hours')
  RETURNING id INTO sh1;

  INSERT INTO pos_shifts (shift_number, cashier_name, opening_float, status, opened_at)
  VALUES ('SEED-SH-02', 'Seed Cashier', 500, 'open', NOW() - interval '4 hours')
  RETURNING id INTO sh2;

  -- Opening-stock log entries (illustrative; quantities are set directly above).
  INSERT INTO stock_movements (product_id, type, quantity, note, created_at)
  SELECT id, 'opening_stock', quantity_on_hand, 'Seed opening stock', NOW() - interval '5 days'
  FROM products;

  -- A couple of manual adjustments for the stock log.
  INSERT INTO stock_movements (product_id, type, quantity, reason, note, created_at) VALUES
    ((SELECT id FROM products WHERE sku='BAK-001'), 'adjustment', -3, 'Damage', 'Spoiled loaves', NOW() - interval '1 day'),
    ((SELECT id FROM products WHERE sku='DRY-002'), 'adjustment', -2, 'Loss',   'Expired units',  NOW() - interval '1 day');

  -- Helper to insert an order + its lines/payment/movements.
  -- (Inlined per order; receipt numbers are looked up by subselect.)

  -- Order 1 — 2 days ago, cash
  INSERT INTO pos_orders (receipt_number, shift_id, cashier_name, subtotal, total_amount, paid_amount, payment_status, status, created_at)
  VALUES ('SEED-0001', sh1, 'Seed Cashier', 70, 70, 70, 'paid', 'completed', NOW() - interval '2 days');
  INSERT INTO pos_order_items (pos_order_id, product_id, name, quantity, unit_price) VALUES
    ((SELECT id FROM pos_orders WHERE receipt_number='SEED-0001'), (SELECT id FROM products WHERE sku='BEV-001'), 'Bottled Water 500ml', 2, 10),
    ((SELECT id FROM pos_orders WHERE receipt_number='SEED-0001'), (SELECT id FROM products WHERE sku='SNK-001'), 'Potato Chips', 2, 25);
  INSERT INTO pos_order_payments (pos_order_id, method, amount) VALUES
    ((SELECT id FROM pos_orders WHERE receipt_number='SEED-0001'), 'cash', 70);
  INSERT INTO stock_movements (product_id, type, quantity, reference_type, reference_id, created_at) VALUES
    ((SELECT id FROM products WHERE sku='BEV-001'), 'pos_sale', -2, 'pos_order', (SELECT id FROM pos_orders WHERE receipt_number='SEED-0001'), NOW() - interval '2 days'),
    ((SELECT id FROM products WHERE sku='SNK-001'), 'pos_sale', -2, 'pos_order', (SELECT id FROM pos_orders WHERE receipt_number='SEED-0001'), NOW() - interval '2 days');

  -- Order 2 — 2 days ago, card
  INSERT INTO pos_orders (receipt_number, shift_id, cashier_name, subtotal, total_amount, paid_amount, payment_status, status, created_at)
  VALUES ('SEED-0002', sh1, 'Seed Cashier', 65, 65, 65, 'paid', 'completed', NOW() - interval '2 days' + interval '1 hour');
  INSERT INTO pos_order_items (pos_order_id, product_id, name, quantity, unit_price) VALUES
    ((SELECT id FROM pos_orders WHERE receipt_number='SEED-0002'), (SELECT id FROM products WHERE sku='BEV-003'), 'Orange Juice 1L', 1, 35),
    ((SELECT id FROM pos_orders WHERE receipt_number='SEED-0002'), (SELECT id FROM products WHERE sku='DRY-001'), 'Milk 1L', 1, 30);
  INSERT INTO pos_order_payments (pos_order_id, method, amount) VALUES
    ((SELECT id FROM pos_orders WHERE receipt_number='SEED-0002'), 'card', 65);
  INSERT INTO stock_movements (product_id, type, quantity, reference_type, reference_id, created_at) VALUES
    ((SELECT id FROM products WHERE sku='BEV-003'), 'pos_sale', -1, 'pos_order', (SELECT id FROM pos_orders WHERE receipt_number='SEED-0002'), NOW() - interval '2 days'),
    ((SELECT id FROM products WHERE sku='DRY-001'), 'pos_sale', -1, 'pos_order', (SELECT id FROM pos_orders WHERE receipt_number='SEED-0002'), NOW() - interval '2 days');

  -- Order 3 — yesterday, cash
  INSERT INTO pos_orders (receipt_number, shift_id, cashier_name, subtotal, total_amount, paid_amount, payment_status, status, created_at)
  VALUES ('SEED-0003', sh1, 'Seed Cashier', 85, 85, 85, 'paid', 'completed', NOW() - interval '1 day');
  INSERT INTO pos_order_items (pos_order_id, product_id, name, quantity, unit_price) VALUES
    ((SELECT id FROM pos_orders WHERE receipt_number='SEED-0003'), (SELECT id FROM products WHERE sku='BEV-002'), 'Cola Can 330ml', 3, 15),
    ((SELECT id FROM pos_orders WHERE receipt_number='SEED-0003'), (SELECT id FROM products WHERE sku='SNK-002'), 'Chocolate Bar', 2, 20);
  INSERT INTO pos_order_payments (pos_order_id, method, amount) VALUES
    ((SELECT id FROM pos_orders WHERE receipt_number='SEED-0003'), 'cash', 85);
  INSERT INTO stock_movements (product_id, type, quantity, reference_type, reference_id, created_at) VALUES
    ((SELECT id FROM products WHERE sku='BEV-002'), 'pos_sale', -3, 'pos_order', (SELECT id FROM pos_orders WHERE receipt_number='SEED-0003'), NOW() - interval '1 day'),
    ((SELECT id FROM products WHERE sku='SNK-002'), 'pos_sale', -2, 'pos_order', (SELECT id FROM pos_orders WHERE receipt_number='SEED-0003'), NOW() - interval '1 day');

  -- Order 4 — yesterday, card
  INSERT INTO pos_orders (receipt_number, shift_id, cashier_name, subtotal, total_amount, paid_amount, payment_status, status, created_at)
  VALUES ('SEED-0004', sh1, 'Seed Cashier', 54, 54, 54, 'paid', 'completed', NOW() - interval '1 day' + interval '2 hours');
  INSERT INTO pos_order_items (pos_order_id, product_id, name, quantity, unit_price) VALUES
    ((SELECT id FROM pos_orders WHERE receipt_number='SEED-0004'), (SELECT id FROM products WHERE sku='BAK-001'), 'White Bread', 1, 22),
    ((SELECT id FROM pos_orders WHERE receipt_number='SEED-0004'), (SELECT id FROM products WHERE sku='BAK-002'), 'Croissant', 2, 16);
  INSERT INTO pos_order_payments (pos_order_id, method, amount) VALUES
    ((SELECT id FROM pos_orders WHERE receipt_number='SEED-0004'), 'card', 54);
  INSERT INTO stock_movements (product_id, type, quantity, reference_type, reference_id, created_at) VALUES
    ((SELECT id FROM products WHERE sku='BAK-001'), 'pos_sale', -1, 'pos_order', (SELECT id FROM pos_orders WHERE receipt_number='SEED-0004'), NOW() - interval '1 day'),
    ((SELECT id FROM products WHERE sku='BAK-002'), 'pos_sale', -2, 'pos_order', (SELECT id FROM pos_orders WHERE receipt_number='SEED-0004'), NOW() - interval '1 day');

  -- Order 5 — today, cash
  INSERT INTO pos_orders (receipt_number, shift_id, cashier_name, subtotal, total_amount, paid_amount, payment_status, status, created_at)
  VALUES ('SEED-0005', sh2, 'Seed Cashier', 85, 85, 85, 'paid', 'completed', NOW() - interval '3 hours');
  INSERT INTO pos_order_items (pos_order_id, product_id, name, quantity, unit_price) VALUES
    ((SELECT id FROM pos_orders WHERE receipt_number='SEED-0005'), (SELECT id FROM products WHERE sku='BEV-001'), 'Bottled Water 500ml', 4, 10),
    ((SELECT id FROM pos_orders WHERE receipt_number='SEED-0005'), (SELECT id FROM products WHERE sku='HOU-001'), 'Dish Soap 500ml', 1, 45);
  INSERT INTO pos_order_payments (pos_order_id, method, amount) VALUES
    ((SELECT id FROM pos_orders WHERE receipt_number='SEED-0005'), 'cash', 85);
  INSERT INTO stock_movements (product_id, type, quantity, reference_type, reference_id, created_at) VALUES
    ((SELECT id FROM products WHERE sku='BEV-001'), 'pos_sale', -4, 'pos_order', (SELECT id FROM pos_orders WHERE receipt_number='SEED-0005'), NOW() - interval '3 hours'),
    ((SELECT id FROM products WHERE sku='HOU-001'), 'pos_sale', -1, 'pos_order', (SELECT id FROM pos_orders WHERE receipt_number='SEED-0005'), NOW() - interval '3 hours');

  -- Order 6 — today, custom (Instapay)
  INSERT INTO pos_orders (receipt_number, shift_id, cashier_name, customer_name, subtotal, total_amount, paid_amount, payment_status, status, created_at)
  VALUES ('SEED-0006', sh2, 'Seed Cashier', 'Cafe Downtown', 80, 80, 80, 'paid', 'completed', NOW() - interval '1 hour');
  INSERT INTO pos_order_items (pos_order_id, product_id, name, quantity, unit_price) VALUES
    ((SELECT id FROM pos_orders WHERE receipt_number='SEED-0006'), (SELECT id FROM products WHERE sku='DRY-002'), 'Yogurt 200g', 2, 12),
    ((SELECT id FROM pos_orders WHERE receipt_number='SEED-0006'), (SELECT id FROM products WHERE sku='SNK-003'), 'Salted Peanuts', 1, 18),
    ((SELECT id FROM pos_orders WHERE receipt_number='SEED-0006'), (SELECT id FROM products WHERE sku='HOU-002'), 'Paper Towels', 1, 38);
  INSERT INTO pos_order_payments (pos_order_id, method, method_label, amount) VALUES
    ((SELECT id FROM pos_orders WHERE receipt_number='SEED-0006'), 'custom', 'Instapay', 80);
  INSERT INTO stock_movements (product_id, type, quantity, reference_type, reference_id, created_at) VALUES
    ((SELECT id FROM products WHERE sku='DRY-002'), 'pos_sale', -2, 'pos_order', (SELECT id FROM pos_orders WHERE receipt_number='SEED-0006'), NOW() - interval '1 hour'),
    ((SELECT id FROM products WHERE sku='SNK-003'), 'pos_sale', -1, 'pos_order', (SELECT id FROM pos_orders WHERE receipt_number='SEED-0006'), NOW() - interval '1 hour'),
    ((SELECT id FROM products WHERE sku='HOU-002'), 'pos_sale', -1, 'pos_order', (SELECT id FROM pos_orders WHERE receipt_number='SEED-0006'), NOW() - interval '1 hour');

  RAISE NOTICE 'Seeded 2 shifts, 6 orders, payments and stock movements.';
END $$;

-- ── Link POS orders to client accounts ───────────────────────────────────────
-- The earlier POS block stores the customer as free text; attach it to a real
-- client row so POS sales roll up into the customer account.
UPDATE pos_orders po
   SET client_id = c.id
  FROM clients c
 WHERE po.client_id IS NULL
   AND po.customer_name IS NOT NULL
   AND c.name = po.customer_name;

-- ── Sales & purchase invoices (line items + GL postings) ─────────────────────
-- Demonstrates the full relational chain: invoice → invoice_items → products,
-- invoice → client/supplier, and invoice → journal_entries → gl_accounts so the
-- books tie out. Guarded so re-running won't duplicate.
DO $$
DECLARE
  inv  BIGINT;
  je   BIGINT;
BEGIN
  IF EXISTS (SELECT 1 FROM sales_invoices WHERE invoice_number LIKE 'SINV-%') THEN
    RAISE NOTICE 'Seed invoices already present; skipping the invoice block.';
    RETURN;
  END IF;

  -- ===== Sales invoice 1 — Cafe Downtown (on account / A/R) ==================
  INSERT INTO sales_invoices (invoice_number, client_id, status, issue_date, subtotal, tax_amount, total_amount, created_at)
  VALUES ('SINV-0001', (SELECT id FROM clients WHERE client_code='CL-002'), 'posted', CURRENT_DATE - 3, 550, 77, 627, NOW() - interval '3 days')
  RETURNING id INTO inv;
  INSERT INTO sales_invoice_items (sales_invoice_id, product_id, name, quantity, unit_price, line_total) VALUES
    (inv, (SELECT id FROM products WHERE sku='BEV-002'), 'Cola Can 330ml', 20, 15, 300),
    (inv, (SELECT id FROM products WHERE sku='SNK-001'), 'Potato Chips',   10, 25, 250);
  -- Revenue posting: DR A/R 627; CR Sales Revenue 550; CR Tax Payable 77
  INSERT INTO journal_entries (reference_no, source_type, source_id, entry_type, description, transaction_date, posted_at, status)
  VALUES ('JE-' || lpad(nextval('journal_entry_seq')::text, 6, '0'), 'sales_invoice', inv, 'invoice_posting', 'Sales invoice SINV-0001', CURRENT_DATE - 3, NOW() - interval '3 days', 'posted')
  RETURNING id INTO je;
  INSERT INTO journal_entry_lines (journal_entry_id, gl_account_id, line_type, amount) VALUES
    (je, (SELECT id FROM gl_accounts WHERE code='1200'), 'debit',  627),
    (je, (SELECT id FROM gl_accounts WHERE code='4100'), 'credit', 550),
    (je, (SELECT id FROM gl_accounts WHERE code='2200'), 'credit', 77);
  -- COGS posting: DR COGS 330; CR Inventory 330  (9*20 + 15*10)
  INSERT INTO journal_entries (reference_no, source_type, source_id, entry_type, description, transaction_date, posted_at, status)
  VALUES ('JE-' || lpad(nextval('journal_entry_seq')::text, 6, '0'), 'sales_invoice', inv, 'invoice_cogs', 'COGS for SINV-0001', CURRENT_DATE - 3, NOW() - interval '3 days', 'posted')
  RETURNING id INTO je;
  INSERT INTO journal_entry_lines (journal_entry_id, gl_account_id, line_type, amount) VALUES
    (je, (SELECT id FROM gl_accounts WHERE code='5100'), 'debit',  330),
    (je, (SELECT id FROM gl_accounts WHERE code='1300'), 'credit', 330);

  -- ===== Sales invoice 2 — Sunrise Restaurant (on account / A/R) ============
  INSERT INTO sales_invoices (invoice_number, client_id, status, issue_date, subtotal, tax_amount, total_amount, created_at)
  VALUES ('SINV-0002', (SELECT id FROM clients WHERE client_code='CL-004'), 'posted', CURRENT_DATE - 1, 670, 93.80, 763.80, NOW() - interval '1 day')
  RETURNING id INTO inv;
  INSERT INTO sales_invoice_items (sales_invoice_id, product_id, name, quantity, unit_price, line_total) VALUES
    (inv, (SELECT id FROM products WHERE sku='DRY-001'), 'Milk 1L',     15, 30, 450),
    (inv, (SELECT id FROM products WHERE sku='BAK-001'), 'White Bread', 10, 22, 220);
  INSERT INTO journal_entries (reference_no, source_type, source_id, entry_type, description, transaction_date, posted_at, status)
  VALUES ('JE-' || lpad(nextval('journal_entry_seq')::text, 6, '0'), 'sales_invoice', inv, 'invoice_posting', 'Sales invoice SINV-0002', CURRENT_DATE - 1, NOW() - interval '1 day', 'posted')
  RETURNING id INTO je;
  INSERT INTO journal_entry_lines (journal_entry_id, gl_account_id, line_type, amount) VALUES
    (je, (SELECT id FROM gl_accounts WHERE code='1200'), 'debit',  763.80),
    (je, (SELECT id FROM gl_accounts WHERE code='4100'), 'credit', 670),
    (je, (SELECT id FROM gl_accounts WHERE code='2200'), 'credit', 93.80);
  -- COGS: 20*15 + 13*10 = 430
  INSERT INTO journal_entries (reference_no, source_type, source_id, entry_type, description, transaction_date, posted_at, status)
  VALUES ('JE-' || lpad(nextval('journal_entry_seq')::text, 6, '0'), 'sales_invoice', inv, 'invoice_cogs', 'COGS for SINV-0002', CURRENT_DATE - 1, NOW() - interval '1 day', 'posted')
  RETURNING id INTO je;
  INSERT INTO journal_entry_lines (journal_entry_id, gl_account_id, line_type, amount) VALUES
    (je, (SELECT id FROM gl_accounts WHERE code='5100'), 'debit',  430),
    (je, (SELECT id FROM gl_accounts WHERE code='1300'), 'credit', 430);

  -- ===== Sales invoice 3 — Green Grocer (cash) ==============================
  INSERT INTO sales_invoices (invoice_number, client_id, status, issue_date, subtotal, tax_amount, total_amount, created_at)
  VALUES ('SINV-0003', (SELECT id FROM clients WHERE client_code='CL-003'), 'paid', CURRENT_DATE, 660, 92.40, 752.40, NOW() - interval '2 hours')
  RETURNING id INTO inv;
  INSERT INTO sales_invoice_items (sales_invoice_id, product_id, name, quantity, unit_price, line_total) VALUES
    (inv, (SELECT id FROM products WHERE sku='BEV-003'), 'Orange Juice 1L', 12, 35, 420),
    (inv, (SELECT id FROM products WHERE sku='DRY-002'), 'Yogurt 200g',     20, 12, 240);
  INSERT INTO journal_entries (reference_no, source_type, source_id, entry_type, description, transaction_date, posted_at, status)
  VALUES ('JE-' || lpad(nextval('journal_entry_seq')::text, 6, '0'), 'sales_invoice', inv, 'invoice_posting', 'Sales invoice SINV-0003', CURRENT_DATE, NOW() - interval '2 hours', 'posted')
  RETURNING id INTO je;
  INSERT INTO journal_entry_lines (journal_entry_id, gl_account_id, line_type, amount) VALUES
    (je, (SELECT id FROM gl_accounts WHERE code='1100'), 'debit',  752.40),
    (je, (SELECT id FROM gl_accounts WHERE code='4100'), 'credit', 660),
    (je, (SELECT id FROM gl_accounts WHERE code='2200'), 'credit', 92.40);
  -- COGS: 22*12 + 7*20 = 404
  INSERT INTO journal_entries (reference_no, source_type, source_id, entry_type, description, transaction_date, posted_at, status)
  VALUES ('JE-' || lpad(nextval('journal_entry_seq')::text, 6, '0'), 'sales_invoice', inv, 'invoice_cogs', 'COGS for SINV-0003', CURRENT_DATE, NOW() - interval '2 hours', 'posted')
  RETURNING id INTO je;
  INSERT INTO journal_entry_lines (journal_entry_id, gl_account_id, line_type, amount) VALUES
    (je, (SELECT id FROM gl_accounts WHERE code='5100'), 'debit',  404),
    (je, (SELECT id FROM gl_accounts WHERE code='1300'), 'credit', 404);

  -- ===== Purchase invoice 1 — Nile Beverages (on account / A/P) =============
  INSERT INTO supplier_invoices (invoice_number, supplier_id, status, issue_date, subtotal, tax_amount, total_amount, created_at)
  VALUES ('PINV-0001', (SELECT id FROM suppliers WHERE supplier_code='SUP-001'), 'pending', CURRENT_DATE - 5, 2200, 308, 2508, NOW() - interval '5 days')
  RETURNING id INTO inv;
  INSERT INTO supplier_invoice_items (supplier_invoice_id, product_id, name, quantity, unit_price, line_total) VALUES
    (inv, (SELECT id FROM products WHERE sku='BEV-001'), 'Bottled Water 500ml', 100, 6,  600),
    (inv, (SELECT id FROM products WHERE sku='BEV-002'), 'Cola Can 330ml',       80, 9,  720),
    (inv, (SELECT id FROM products WHERE sku='BEV-003'), 'Orange Juice 1L',      40, 22, 880);
  -- DR Inventory 2200; DR Tax Payable 308 (recoverable input VAT); CR A/P 2508
  INSERT INTO journal_entries (reference_no, source_type, source_id, entry_type, description, transaction_date, posted_at, status)
  VALUES ('JE-' || lpad(nextval('journal_entry_seq')::text, 6, '0'), 'supplier_invoice', inv, 'invoice_posting', 'Purchase invoice PINV-0001', CURRENT_DATE - 5, NOW() - interval '5 days', 'posted')
  RETURNING id INTO je;
  INSERT INTO journal_entry_lines (journal_entry_id, gl_account_id, line_type, amount) VALUES
    (je, (SELECT id FROM gl_accounts WHERE code='1300'), 'debit',  2200),
    (je, (SELECT id FROM gl_accounts WHERE code='1400'), 'debit',  308),
    (je, (SELECT id FROM gl_accounts WHERE code='2100'), 'credit', 2508);

  -- ===== Purchase invoice 2 — Cairo Snacks (on account / A/P) ===============
  INSERT INTO supplier_invoices (invoice_number, supplier_id, status, issue_date, subtotal, tax_amount, total_amount, created_at)
  VALUES ('PINV-0002', (SELECT id FROM suppliers WHERE supplier_code='SUP-002'), 'pending', CURRENT_DATE - 4, 1500, 210, 1710, NOW() - interval '4 days')
  RETURNING id INTO inv;
  INSERT INTO supplier_invoice_items (supplier_invoice_id, product_id, name, quantity, unit_price, line_total) VALUES
    (inv, (SELECT id FROM products WHERE sku='SNK-001'), 'Potato Chips',  60, 15, 900),
    (inv, (SELECT id FROM products WHERE sku='SNK-002'), 'Chocolate Bar', 50, 12, 600);
  INSERT INTO journal_entries (reference_no, source_type, source_id, entry_type, description, transaction_date, posted_at, status)
  VALUES ('JE-' || lpad(nextval('journal_entry_seq')::text, 6, '0'), 'supplier_invoice', inv, 'invoice_posting', 'Purchase invoice PINV-0002', CURRENT_DATE - 4, NOW() - interval '4 days', 'posted')
  RETURNING id INTO je;
  INSERT INTO journal_entry_lines (journal_entry_id, gl_account_id, line_type, amount) VALUES
    (je, (SELECT id FROM gl_accounts WHERE code='1300'), 'debit',  1500),
    (je, (SELECT id FROM gl_accounts WHERE code='1400'), 'debit',  210),
    (je, (SELECT id FROM gl_accounts WHERE code='2100'), 'credit', 1710);

  -- ===== Purchase invoice 3 — Delta Dairy (on account / A/P) ================
  INSERT INTO supplier_invoices (invoice_number, supplier_id, status, issue_date, subtotal, tax_amount, total_amount, created_at)
  VALUES ('PINV-0003', (SELECT id FROM suppliers WHERE supplier_code='SUP-003'), 'pending', CURRENT_DATE - 3, 1560, 218.40, 1778.40, NOW() - interval '3 days')
  RETURNING id INTO inv;
  INSERT INTO supplier_invoice_items (supplier_invoice_id, product_id, name, quantity, unit_price, line_total) VALUES
    (inv, (SELECT id FROM products WHERE sku='DRY-001'), 'Milk 1L',     50, 20, 1000),
    (inv, (SELECT id FROM products WHERE sku='DRY-002'), 'Yogurt 200g', 80, 7,  560);
  INSERT INTO journal_entries (reference_no, source_type, source_id, entry_type, description, transaction_date, posted_at, status)
  VALUES ('JE-' || lpad(nextval('journal_entry_seq')::text, 6, '0'), 'supplier_invoice', inv, 'invoice_posting', 'Purchase invoice PINV-0003', CURRENT_DATE - 3, NOW() - interval '3 days', 'posted')
  RETURNING id INTO je;
  INSERT INTO journal_entry_lines (journal_entry_id, gl_account_id, line_type, amount) VALUES
    (je, (SELECT id FROM gl_accounts WHERE code='1300'), 'debit',  1560),
    (je, (SELECT id FROM gl_accounts WHERE code='1400'), 'debit',  218.40),
    (je, (SELECT id FROM gl_accounts WHERE code='2100'), 'credit', 1778.40);

  RAISE NOTICE 'Seeded 3 sales invoices, 3 purchase invoices, line items and GL postings.';
END $$;
