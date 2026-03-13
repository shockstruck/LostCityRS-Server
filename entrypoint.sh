#!/bin/bash
set -euo pipefail

# LostCityRS Server - Non-interactive container entrypoint
# Clones engine + content repos on first run, then starts the server.
#
# Environment variables:
#   REV                    - Game revision to run (default: 254)
#   ENGINE_REPO            - Engine repository URL
#   CONTENT_REPO           - Content repository URL
#   WEB_PORT               - HTTP/web client port (e.g. 8888)
#   NODE_ID                - World/node ID (project adds +9 offset internally)
#   NODE_PORT              - RS2 game protocol port (default usually 43594)
#   NODE_MEMBERS           - Enable members content ("true" or "false")
#   NODE_XPRATE            - World XP rate (e.g. 1, 5, 10)
#   NODE_PRODUCTION        - Production mode ("true" or "false")
#   NODE_DEBUG             - Debug mode ("true" or "false")
#   EASY_STARTUP           - Enable easy startup flag ("true" or "false")
#   WEBSITE_REGISTRATION   - Auto-register accounts on login attempt ("true" or "false")


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
  if [ ! -f ".env.example" ]; then
    log "ERROR: .env.example not found - cannot auto-configure"
    exit 1
  fi
  cp .env.example .env

  # Append overrides from container env vars (HelmRelease) if set
  [ -n "\( {WEB_PORT:-}" ]             && echo "WEB_PORT= \){WEB_PORT}"             >> .env
  [ -n "\( {NODE_ID:-}" ]              && echo "NODE_ID= \)(( ${NODE_ID} + 9 ))"    >> .env  # respects +9 offset if used in project
  [ -n "\( {NODE_PORT:-}" ]            && echo "NODE_PORT= \){NODE_PORT}"           >> .env
  [ -n "\( {NODE_MEMBERS:-}" ]         && echo "NODE_MEMBERS= \){NODE_MEMBERS}"      >> .env
  [ -n "\( {NODE_XPRATE:-}" ]          && echo "NODE_XPRATE= \){NODE_XPRATE}"       >> .env
  [ -n "\( {NODE_PRODUCTION:-}" ]      && echo "NODE_PRODUCTION= \){NODE_PRODUCTION}" >> .env
  [ -n "\( {NODE_DEBUG:-}" ]           && echo "NODE_DEBUG= \){NODE_DEBUG}"         >> .env
  [ -n "\( {EASY_STARTUP:-}" ]         && echo "EASY_STARTUP= \){EASY_STARTUP}"     >> .env
  [ -n "\( {WEBSITE_REGISTRATION:-}" ] && echo "WEBSITE_REGISTRATION= \){WEBSITE_REGISTRATION}" >> .env

  # Optional: force development-friendly defaults if not overridden
  grep -q "^DB_BACKEND=" .env || echo "DB_BACKEND=sqlite" >> .env

  # Run migration once (safe to rerun)
  log "Running DB migration (if needed)..."
  bun run sqlite:migrate || true
fi

log "Starting server (rev: ${REV})..."
exec bun start