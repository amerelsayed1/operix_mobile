-- 013_product_categories_units.sql
-- Managed product Categories and Units (ported from the Operix web tenant app:
-- ProductCategoryController + SettingsController units). Replaces the free-text
-- product.category string and the hardcoded unit list with editable, bilingual
-- (AR/EN) catalogues. Products still store the chosen name string (no FK), so
-- existing rows, POS, and reports keep working unchanged.
-- Idempotent: safe to re-apply to an existing volume.

CREATE TABLE IF NOT EXISTS product_categories (
  id BIGSERIAL PRIMARY KEY,
  name_en VARCHAR(160) NOT NULL DEFAULT '',
  name_ar VARCHAR(160) NOT NULL DEFAULT '',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS units (
  id BIGSERIAL PRIMARY KEY,
  name_en VARCHAR(120) NOT NULL DEFAULT '',
  name_ar VARCHAR(120) NOT NULL DEFAULT '',
  short_code VARCHAR(40),
  description TEXT,
  allow_decimal BOOLEAN NOT NULL DEFAULT FALSE,
  conversion_factor NUMERIC(14, 4) NOT NULL DEFAULT 1,
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- At most one default unit at a time (enforced at the DB, not just the UI).
CREATE UNIQUE INDEX IF NOT EXISTS units_one_default_idx
  ON units (is_default) WHERE is_default = TRUE;

-- Seed the starter units (mirrors the old hardcoded kProductUnits list) so a
-- fresh install has a usable, defaulted unit. Guarded so re-applying is a no-op.
INSERT INTO units (name_en, name_ar, short_code, allow_decimal, is_default)
SELECT v.name_en, v.name_ar, v.short_code, v.allow_decimal, v.is_default
FROM (VALUES
  ('Piece', 'قطعة',   'pcs', FALSE, TRUE),
  ('Box',   'صندوق',  'box', FALSE, FALSE),
  ('Pack',  'علبة',   'pk',  FALSE, FALSE),
  ('Dozen', 'دستة',   'dz',  FALSE, FALSE),
  ('Kg',    'كيلو',   'kg',  TRUE,  FALSE),
  ('Gram',  'جرام',   'g',   TRUE,  FALSE),
  ('Liter', 'لتر',    'L',   TRUE,  FALSE),
  ('Meter', 'متر',    'm',   TRUE,  FALSE)
) AS v(name_en, name_ar, short_code, allow_decimal, is_default)
WHERE NOT EXISTS (SELECT 1 FROM units);
