#!/usr/bin/env bash
# Scheduled yt-dlp self-update for the Aria backend.
#
# YouTube breaks extraction often; yt-dlp ships fixes almost daily. This script
# upgrades yt-dlp inside the backend venv and restarts the service ONLY if the
# version actually changed (so we don't bounce playback for a no-op). Wire it to
# aria-yt-dlp-update.timer (daily). Logs to stdout -> journald.
set -euo pipefail

VENV="${ARIA_VENV:-/home/chait/MusicAppIOS/backend/.venv}"
SERVICE="${ARIA_SERVICE:-aria-backend}"
PIP="$VENV/bin/pip"
PY="$VENV/bin/python"

before="$($PY -c 'import yt_dlp; print(yt_dlp.version.__version__)' 2>/dev/null || echo none)"
echo "[update-yt-dlp] current yt-dlp: $before"

"$PIP" install --upgrade --quiet yt-dlp

after="$($PY -c 'import yt_dlp; print(yt_dlp.version.__version__)')"
echo "[update-yt-dlp] after upgrade: $after"

if [ "$before" != "$after" ]; then
    echo "[update-yt-dlp] version changed $before -> $after; restarting $SERVICE"
    sudo systemctl restart "$SERVICE"
else
    echo "[update-yt-dlp] no change; not restarting"
fi
