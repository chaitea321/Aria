# Aria Backend

FastAPI + yt-dlp service that resolves/streams YouTube audio for the Aria iOS
app. This directory is the **single source of truth** for the backend — it is
version-controlled here and deployed to the homelab by copying `app.py`.

## Run locally

```bash
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
python -m uvicorn app:app --host 0.0.0.0 --port 8000
```

## Test

```bash
cd backend
python -m pytest tests/ -q
```

CI (`.github/workflows/ci.yml`) runs `py_compile` + this suite on every push/PR.

## Deploy to the homelab

The backend is **not** packaged — deploy is a file copy plus a service restart:

```bash
scp ~/MusicAppIOS/Aria_Music_Browser/backend/app.py \
    eugene@100.76.103.1:~/MusicAppIOS/backend/app.py
ssh eugene@100.76.103.1 "sudo systemctl restart aria-backend"
```

> Source of truth moved into the repo (`Aria_Music_Browser/backend/`). The old
> untracked `~/MusicAppIOS/backend/` copy is superseded — deploy from here.

## Endpoints

| Endpoint            | Purpose                                              |
|---------------------|------------------------------------------------------|
| `GET /api/search`   | YouTube search (flat, 60s cache)                     |
| `GET /api/resolve`  | Direct stream URL, no download (progressive play)    |
| `GET /api/play`     | Download + cache, returns `/api/stream/...` path     |
| `GET /api/stream/{file}` | Serve a cached file (Range-enabled)             |
| `GET /api/radio`    | YouTube Mix (RD<seed>) related tracks                |
| `DELETE /api/cache` | Wipe the cache (auth-gated)                          |
| `GET /api/health`   | Status, versions, cache stats, error rate            |
| `GET /api/metrics`  | Per-endpoint p50/p95 latency, failure-by-reason       |

## Observability (LLMOps)

- **Structured logging** — every request logs `rid=… ip=… METHOD path -> status (ms)`.
  `X-Request-ID` is echoed on every response for end-to-end tracing.
- **`/api/metrics`** — p50/p95 latency per endpoint, request counts, and
  failure-by-reason counters (HTTP status + `download_error` / `invalid_media`).
- **`/api/health`** — reports `yt_dlp_version`, `node` path/availability,
  `uptime_seconds`, and rolling `error_rate` so a monitor can alert on
  *degraded* (not just *down*).

## Scheduled jobs (systemd timers)

Install on the homelab (copy the unit files into `/etc/systemd/system/`):

```bash
# yt-dlp self-update (daily)
sudo cp aria-yt-dlp-update.service aria-yt-dlp-update.timer /etc/systemd/system/
sudo systemctl enable --now aria-yt-dlp-update.timer

# health probe + alerting (every 5 min)
sudo cp aria-healthcheck.service aria-healthcheck.timer /etc/systemd/system/
sudo systemctl enable --now aria-healthcheck.timer
```

- `update-yt-dlp.sh` upgrades yt-dlp in the venv and restarts the service only
  when the version changed. Needs a sudoers NOPASSWD rule for the restart
  (see the comment in `aria-yt-dlp-update.service`).
- `healthcheck.sh` posts to `ARIA_ALERT_WEBHOOK` (Slack/Discord/ntfy) on
  failure. **Prefer running it off-box** (a down host can't probe itself) —
  point an external monitor at `https://<backend>/api/health`.

## Key env vars

| Var | Default | Meaning |
|-----|---------|---------|
| `MAX_CACHE_GB` | 2 | Cache size cap before LRU eviction |
| `MIN_FREE_DISK_BYTES` | 2× max file | Disk headroom; below it `/api/play` → 507 |
| `MIN_VALID_FILE_BYTES` | 16384 | Downloads smaller than this are rejected |
| `DOWNLOAD_CONCURRENCY` / `SEARCH_CONCURRENCY` | 2 / 4 | Semaphore sizes |
| `RATE_LIMIT_PLAY_PER_MIN` / `RATE_LIMIT_SEARCH_PER_MIN` | 60 / 30 | Per-IP limits |
| `ARIA_API_KEY` | _(unset)_ | If set, required on play/search/resolve/radio/cache |
| `NODE_PATH` | autodetect | node binary for yt-dlp JS; falls back to `which node` |
| `LOG_LEVEL` | INFO | Python logging level |
