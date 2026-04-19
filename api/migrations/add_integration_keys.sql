-- Integration API keys for tenant-scoped automation (systems user principal).
-- Secret is shown once at creation; only bcrypt hash is stored.
--
-- Run against the TENANT database (e.g. cogento_kgtc), not cogento_shared; users table must exist.
-- If pgAdmin shows a Python error like NoneType ... 'shared', use psql or another client — that is a pgAdmin UI bug, not PostgreSQL rejecting this SQL.

CREATE TABLE IF NOT EXISTS integration_keys (
    key_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    secret_hash VARCHAR(255) NOT NULL,
    label VARCHAR(200),
    revoked_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_used_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_integration_keys_user_id ON integration_keys(user_id);
CREATE INDEX IF NOT EXISTS idx_integration_keys_revoked_pending ON integration_keys(key_id)
    WHERE revoked_at IS NULL;

COMMENT ON TABLE integration_keys IS 'Opaque API keys (Bearer cgnt_sk_{uuid}_{secret}); bcrypt hash only; maps to systems user.';
COMMENT ON COLUMN integration_keys.secret_hash IS 'bcrypt digest of the secret suffix only (full bearer exceeds bcrypt 72-byte limit).';
