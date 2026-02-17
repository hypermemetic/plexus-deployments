#!/usr/bin/env bash
# start-chromedriver.sh — Ensure ChromeDriver is installed, then start it
# so that Docker containers can reach it via host.docker.internal:9515
set -euo pipefail

PORT="${CHROMEDRIVER_PORT:-9515}"

# ── Ensure Chrome is installed ──────────────────────────────────────
ensure_chrome() {
  if [[ "$(uname)" == "Darwin" ]]; then
    if [ -d "/Applications/Google Chrome.app" ]; then
      echo "[ok] Google Chrome found"
    else
      echo "[!] Google Chrome not found — installing via brew..."
      brew install --cask google-chrome
    fi
  else
    if command -v google-chrome &>/dev/null || command -v google-chrome-stable &>/dev/null; then
      echo "[ok] Google Chrome found"
    else
      echo "[!] Google Chrome not found — install it manually for your distro"
      exit 1
    fi
  fi
}

# ── Ensure ChromeDriver is installed ────────────────────────────────
ensure_chromedriver() {
  if command -v chromedriver &>/dev/null; then
    echo "[ok] chromedriver $(chromedriver --version 2>/dev/null | head -1)"
  else
    echo "[!] chromedriver not found — installing..."
    if [[ "$(uname)" == "Darwin" ]]; then
      brew install chromedriver
    else
      echo "[!] Install chromedriver manually for your distro"
      exit 1
    fi
  fi
}

# ── Kill any existing chromedriver on the port ──────────────────────
kill_existing() {
  local pid
  pid=$(lsof -ti :"$PORT" 2>/dev/null || true)
  if [ -n "$pid" ]; then
    echo "[!] Killing existing process on port $PORT (pid $pid)"
    kill "$pid" 2>/dev/null || true
    sleep 0.5
  fi
}

# ── Main ────────────────────────────────────────────────────────────
ensure_chrome
ensure_chromedriver
kill_existing

echo "Starting chromedriver on port $PORT (accessible from Docker via host.docker.internal:$PORT)"
exec chromedriver \
  --port="$PORT" \
  --allowed-ips="" \
  --allowed-origins="*"
