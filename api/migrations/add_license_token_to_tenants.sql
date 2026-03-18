-- Migration: Add license_token column to tenants table (shared DB)
-- Purpose: Store per-tenant license token (trial, free tier, or premium). Trial token is auto-generated on tenant create.
-- Run against cogento_shared database

ALTER TABLE tenants ADD COLUMN IF NOT EXISTS license_token TEXT;

COMMENT ON COLUMN tenants.license_token IS 'License token (JWT): trial (100 members, 30 days), free tier, or premium. Verified with baked-in public keys.';
