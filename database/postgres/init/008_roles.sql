-- 008_roles.sql
-- Tenant roles and their granted permissions for the Settings → Roles &
-- permissions area. Permission keys are `<module>.<action>` strings owned by the
-- application catalog (lib/src/domain/role_models.dart); only the granted subset
-- is stored here.

CREATE TABLE IF NOT EXISTS roles (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(80) NOT NULL UNIQUE,
  description VARCHAR(255) NOT NULL DEFAULT '',
  is_system BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS role_permissions (
  role_id BIGINT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permission_key VARCHAR(120) NOT NULL,
  PRIMARY KEY (role_id, permission_key)
);

CREATE INDEX IF NOT EXISTS role_permissions_role_idx
  ON role_permissions(role_id);

-- Seed the system Administrator role. Its permission set is reconciled to the
-- full catalog by the application on startup.
INSERT INTO roles (name, description, is_system)
VALUES ('Admin', 'Tenant Administrator with full access', TRUE)
ON CONFLICT (name) DO NOTHING;
