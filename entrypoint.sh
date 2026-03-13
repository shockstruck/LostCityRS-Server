#!/bin/bash
set -euo pipefail

# LostCityRS Server - Non-interactive container entrypoint
# Clones engine + content repos on first run, then starts the server.
#
# Environment variables:
#   REV          - Game revision to run (default: 254)
#   ENGINE_REPO  - Engine repository URL
#   CONTENT_REPO - Content repository URL

REV="${REV:-254}"
ENGINE_REPO="${ENGINE_REPO:-https://github.com/LostCityRS/Engine-TS}"
CONTENT_REPO="${CONTENT_REPO:-https://github.com/LostCityRS/Content}"
DATA_DIR="/data"

log() { echo "[entrypoint] $*"; }

# Clone or update engine
if [ ! -d "${DATA_DIR}/engine" ]; then
  log "Cloning engine (rev: ${REV})..."
  git clone --single-branch -b "${REV}" "${ENGINE_REPO}" "${DATA_DIR}/engine"
else
  log "Engine exists, pulling latest..."
  git -C "${DATA_DIR}/engine" pull || true
fi

# Clone or update content
if [ ! -d "${DATA_DIR}/content" ]; then
  log "Cloning content (rev: ${REV})..."
  git clone --single-branch -b "${REV}" "${CONTENT_REPO}" "${DATA_DIR}/content"
else
  log "Content exists, pulling latest..."
  git -C "${DATA_DIR}/content" pull || true
fi

# Install engine dependencies and run setup on first boot
cd "${DATA_DIR}/engine"
if [ ! -d "node_modules" ]; then
  log "Installing engine dependencies..."
  bun install
fi

if [ ! -f ".env" ]; then
  log "Running engine setup..."
  bun run setup
fi

log "Starting server (rev: ${REV})..."
exec bun start
