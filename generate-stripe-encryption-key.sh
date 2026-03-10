#!/usr/bin/env bash
# Generate a Fernet key for STRIPE_KEY_ENCRYPTION_KEY.
# The key must be in Fernet format (from Python cryptography); a random typed string will not work.
# Run once, add the printed line to .env, and keep it secret.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
[ -f .env ] && set -a && source .env && set +a
IMAGE="ghcr.io/${GHCR_OWNER:-stefano-edgible}/cogento-api:latest"
echo "Pulling image (if needed) and generating key..."
docker run --rm "$IMAGE" python generate_key.py
