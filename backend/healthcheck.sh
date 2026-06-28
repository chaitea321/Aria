#!/usr/bin/env bash
# External uptime/health probe for the Aria backend.
#
# Polls /api/health and alerts when the service is down, returns a non-ok
# status, or its rolling error_rate crosses a threshold. Designed to be driven
# by aria-healthcheck.timer (every 5 min) OR by an off-box monitor (a second
# machine, UptimeRobot, healthchecks.io, etc.) — running it OFF the homelab is
# strictly better, since a box that is down can't run its own cron.
#
# Alerting is via a generic webhook (Slack/Discord/ntfy-compatible JSON
# {"text": ...}). Set ARIA_ALERT_WEBHOOK to enable; otherwise it just logs and
# exits non-zero so the timer/journal records the failure.
set -uo pipefail

URL="${ARIA_HEALTH_URL:-http://127.0.0.1:8000/api/health}"
MAX_ERROR_RATE="${ARIA_MAX_ERROR_RATE:-0.25}"
WEBHOOK="${ARIA_ALERT_WEBHOOK:-}"
TIMEOUT="${ARIA_HEALTH_TIMEOUT:-10}"

alert() {
    local msg="$1"
    echo "[healthcheck] ALERT: $msg" >&2
    if [ -n "$WEBHOOK" ]; then
        curl -fsS -m "$TIMEOUT" -X POST -H 'Content-Type: application/json' \
            -d "{\"text\":\"Aria backend: $msg\"}" "$WEBHOOK" >/dev/null \
            || echo "[healthcheck] webhook post failed" >&2
    fi
}

body="$(curl -fsS -m "$TIMEOUT" "$URL" 2>/dev/null)"
if [ $? -ne 0 ] || [ -z "$body" ]; then
    alert "DOWN — /api/health unreachable at $URL"
    exit 1
fi

status="$(printf '%s' "$body" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("status",""))' 2>/dev/null)"
if [ "$status" != "ok" ]; then
    alert "status != ok ($status)"
    exit 1
fi

# Compare error_rate against the threshold using python (no bc dependency).
over="$(printf '%s' "$body" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print('1' if float(d.get('error_rate', 0)) > $MAX_ERROR_RATE else '0')
" 2>/dev/null)"
if [ "$over" = "1" ]; then
    rate="$(printf '%s' "$body" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("error_rate"))')"
    alert "error_rate $rate exceeds $MAX_ERROR_RATE"
    exit 1
fi

echo "[healthcheck] ok ($URL)"
