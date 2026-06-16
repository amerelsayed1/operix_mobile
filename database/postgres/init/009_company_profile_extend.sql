-- 009_company_profile_extend.sql
-- Extends the single-row company_profile with the contact / registration fields
-- surfaced in Settings → Company information. All additive and idempotent so it
-- can run against an existing database.

ALTER TABLE company_profile ADD COLUMN IF NOT EXISTS email VARCHAR(160);
ALTER TABLE company_profile ADD COLUMN IF NOT EXISTS phone VARCHAR(60);
ALTER TABLE company_profile
  ADD COLUMN IF NOT EXISTS phone_country_code VARCHAR(8) NOT NULL DEFAULT '+20';
ALTER TABLE company_profile
  ADD COLUMN IF NOT EXISTS commercial_registration VARCHAR(80);
ALTER TABLE company_profile ADD COLUMN IF NOT EXISTS city VARCHAR(120);
ALTER TABLE company_profile ADD COLUMN IF NOT EXISTS region VARCHAR(120);
ALTER TABLE company_profile ADD COLUMN IF NOT EXISTS country VARCHAR(80);
ALTER TABLE company_profile ADD COLUMN IF NOT EXISTS postal_code VARCHAR(40);
ALTER TABLE company_profile ADD COLUMN IF NOT EXISTS address TEXT;
