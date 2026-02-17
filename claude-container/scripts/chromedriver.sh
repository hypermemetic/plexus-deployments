#!/usr/bin/env bash
# Start ChromeDriver on the host and make it accessible from Docker containers
# via host.docker.internal:9515
#
# Usage:
#   ./scripts/chromedriver.sh          # start chromedriver
#   ./scripts/chromedriver.sh stop     # stop chromedriver
#   ./scripts/chromedriver.sh status   # check if running

set -euo pipefail

PORT="${CHROMEDRIVER_PORT:-9515}"
PIDFILE="${TMPDIR:-/tmp}/chromedriver.pid"
LOGFILE="${TMPDIR:-/tmp}/chromedriver.log"

# ── Helpers ──────────────────────────────────────────────────

log()  { printf '\033[1;34m[chromedriver]\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m[chromedriver]\033[0m %s\n' "$*" >&2; }
ok()   { printf '\033[1;32m[chromedriver]\033[0m %s\n' "$*"; }

ensure_chromedriver() {
    if command -v chromedriver &>/dev/null; then
        log "Found chromedriver: $(chromedriver --version)"
        return 0
    fi

    log "ChromeDriver not found, installing via Homebrew..."
    if ! command -v brew &>/dev/null; then
        err "Homebrew not found. Install chromedriver manually:"
        err "  brew install chromedriver"
        exit 1
    fi

    brew install --cask chromedriver

    # macOS quarantine: remove the quarantine attribute so it can run
    local driver_path
    driver_path="$(which chromedriver 2>/dev/null || echo "/opt/homebrew/bin/chromedriver")"
    if [ -f "$driver_path" ]; then
        log "Removing macOS quarantine attribute..."
        xattr -d com.apple.quarantine "$driver_path" 2>/dev/null || true
    fi

    if ! command -v chromedriver &>/dev/null; then
        err "Installation failed — chromedriver not in PATH"
        exit 1
    fi

    ok "Installed: $(chromedriver --version)"
}

is_running() {
    if [ -f "$PIDFILE" ]; then
        local pid
        pid="$(cat "$PIDFILE")"
        if kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
        # stale pidfile
        rm -f "$PIDFILE"
    fi
    return 1
}

do_start() {
    ensure_chromedriver

    if is_running; then
        ok "Already running (pid $(cat "$PIDFILE")) on port $PORT"
        return 0
    fi

    # Check port isn't taken by something else
    if lsof -iTCP:"$PORT" -sTCP:LISTEN -t &>/dev/null; then
        err "Port $PORT is already in use:"
        lsof -iTCP:"$PORT" -sTCP:LISTEN
        exit 1
    fi

    log "Starting on port $PORT (log: $LOGFILE)"

    chromedriver \
        --port="$PORT" \
        --allowed-ips="" \
        --allowed-origins="*" \
        > "$LOGFILE" 2>&1 &

    echo $! > "$PIDFILE"

    # Wait for it to be ready
    local attempts=0
    while ! curl -sf "http://127.0.0.1:$PORT/status" &>/dev/null; do
        sleep 0.2
        attempts=$((attempts + 1))
        if [ $attempts -ge 25 ]; then
            err "Timed out waiting for chromedriver to start"
            cat "$LOGFILE"
            exit 1
        fi
    done

    ok "Running (pid $(cat "$PIDFILE")) on port $PORT"
    ok "From Docker containers: http://host.docker.internal:$PORT"
}

do_stop() {
    if ! is_running; then
        log "Not running"
        return 0
    fi

    local pid
    pid="$(cat "$PIDFILE")"
    log "Stopping (pid $pid)..."
    kill "$pid" 2>/dev/null || true
    rm -f "$PIDFILE"
    ok "Stopped"
}

do_status() {
    if is_running; then
        ok "Running (pid $(cat "$PIDFILE")) on port $PORT"
        curl -sf "http://127.0.0.1:$PORT/status" | python3 -m json.tool 2>/dev/null || true
    else
        log "Not running"
        return 1
    fi
}

# ── Main ─────────────────────────────────────────────────────

case "${1:-start}" in
    start)  do_start  ;;
    stop)   do_stop   ;;
    status) do_status ;;
    restart)
        do_stop
        do_start
        ;;
    *)
        echo "Usage: $0 {start|stop|status|restart}"
        exit 1
        ;;
esac
