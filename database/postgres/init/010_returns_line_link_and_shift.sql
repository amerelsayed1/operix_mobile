-- 010_returns_line_link_and_shift.sql
-- Two correctness fixes for sales returns:
--   1. Link each return item to the exact pos_order_item it came from, so
--      returnable quantity is tracked per order line instead of bucketed by
--      (product_id, name). Two lines that share a product/name no longer share
--      a returnable pool (which previously allowed over-returning).
--   2. Stamp the shift the refund was processed in, so a cash refund is
--      subtracted from the drawer it physically left when that shift closes.
-- Idempotent.

ALTER TABLE sales_returns
  ADD COLUMN IF NOT EXISTS shift_id BIGINT REFERENCES pos_shifts(id) ON DELETE SET NULL;

ALTER TABLE sales_return_items
  ADD COLUMN IF NOT EXISTS pos_order_item_id BIGINT REFERENCES pos_order_items(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS sales_returns_shift_idx ON sales_returns(shift_id);
CREATE INDEX IF NOT EXISTS sales_return_items_order_item_idx
  ON sales_return_items(pos_order_item_id);
