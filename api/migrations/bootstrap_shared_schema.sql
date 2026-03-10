-- Bootstrap Schema for Shared Database (cogento_shared) – self-hosted
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS tenants (
    tenant_id VARCHAR(100) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    domain VARCHAR(255),
    status VARCHAR(50) DEFAULT 'active',
    is_default BOOLEAN DEFAULT FALSE,
    config JSONB NOT NULL DEFAULT '{}'::jsonb,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    stripe_secret_key_encrypted VARCHAR(500),
    stripe_publishable_key VARCHAR(255),
    stripe_environment VARCHAR(50) DEFAULT 'test',
    stripe_key_encryption_method VARCHAR(50) DEFAULT 'aes-256-gcm',
    database_name VARCHAR(255),
    superadmin_email VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_by VARCHAR(255)
);

CREATE INDEX IF NOT EXISTS idx_tenants_status ON tenants(status);
CREATE INDEX IF NOT EXISTS idx_tenants_domain ON tenants(domain) WHERE domain IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tenants_config_gin ON tenants USING GIN(config);
CREATE INDEX IF NOT EXISTS idx_tenants_metadata_gin ON tenants USING GIN(metadata);
CREATE INDEX IF NOT EXISTS idx_tenants_stripe_environment ON tenants(stripe_environment);
CREATE INDEX IF NOT EXISTS idx_tenants_is_default ON tenants(is_default) WHERE is_default = TRUE;
CREATE INDEX IF NOT EXISTS idx_tenants_database_name ON tenants(database_name);

CREATE TABLE IF NOT EXISTS users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'superuser',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by VARCHAR(255),
    last_login_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

CREATE TABLE IF NOT EXISTS login_tokens (
    token_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    code VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    token_type VARCHAR(20) NOT NULL DEFAULT 'otp' CHECK (token_type IN ('otp', 'remember_me')),
    used_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_login_tokens_user_id ON login_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_login_tokens_email_code ON login_tokens(email, code) WHERE used_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_login_tokens_token_type ON login_tokens(token_type) WHERE token_type = 'remember_me';
CREATE INDEX IF NOT EXISTS idx_login_tokens_remember_me_lookup ON login_tokens(user_id, token_type, expires_at)
    WHERE token_type = 'remember_me' AND used_at IS NULL;
