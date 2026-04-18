-- Add 'systems' role for non-interactive integration users (e.g. Edgible → Cogento API).
-- Run against each tenant database (e.g. cogento_kgtc).
--
-- Role definitions (tenant users):
--   superadmin - Full admin; tenant must have at least one superadmin
--   admin      - Full admin within tenant
--   user       - Logged-in user without Stripe customer record
--   customer   - User with a Stripe customer record
--   systems    - Service/integration account; limited Stripe customer API (see stripe_customers router)

ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;

ALTER TABLE users ADD CONSTRAINT users_role_check
    CHECK (role IN ('superadmin', 'admin', 'user', 'customer', 'systems'));

COMMENT ON COLUMN users.role IS 'User role: superadmin/admin (full admin; tenant must have at least one superadmin), user (logged-in, no Stripe record), customer (has Stripe customer record), systems (integration; limited Stripe customer API)';
