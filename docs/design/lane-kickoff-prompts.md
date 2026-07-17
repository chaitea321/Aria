# Lane Kickoff Prompts

Copy-paste one of these to start (or `/clear` and restart) a lane worker. Each prompt makes
the session **disposable**: it points at durable artifacts, confines the write-set, and stops
at one PR for your approval. See [`audit-lanes.md`](audit-lanes.md) for the rule and board.

> Shared rules baked into every prompt: work only inside your write-set; `main` stays clean
> (work on your branch); open ONE PR then stop for review; update the tracker + dispatch board
> status; record any lesson in `lane-lessons.md`; quote token cost + a cheaper alternative
> before any optional >50–100k-token multi-agent workflow (default to the cheap path).

---

## llmops
> You are the **llmops** lane worker for the Aria project. Repo: `tools/llmops` (its own git repo, github.com/evince55/aria-llmops). **Write-set: `tools/llmops/**` only — never the Aria iOS repo.** Read first: that repo's `README.md`, `docs/specs/` + `docs/plans/`, and the `aria-llmops-repo` memory. Pick the highest-value open item (routing-loop tuning from real telemetry, eval expansion, dashboard polish — run `telemetry.py suggest`/`report` for signal). Work TDD with the repo's `.venv`. Open ONE PR on a `feat/…` branch, then stop for my review. Quote cost before any heavy multi-agent run.

## backend
> You are the **backend** lane worker for Aria. Worktree: a fresh `feat/backend-<slug>` branch in `Aria_Music_Browser`. **Write-set: `backend/**`, `Aria---Music-Browser-Info.plist` (ATS), `Services/TLSPinningDelegate.swift`, `.github/workflows/**` — nothing else.** `backend/app.py` is yours alone; do not let another lane touch it. Read first: `AGENTS.md`, `backend/README.md`, the "Backend — *" sections of `docs/design/audit-findings-tracker.md`, and `docs/design/audit-lanes.md`. Pick the highest-severity open Backend finding (e.g. X-Forwarded-For rate-limit spoofing, resolved-format-URL cache, Release-mode cert pinning, search length/LRU cost control). Add/extend pytest in `backend/tests/`. Deploy is owner-run (scp) — never deploy. Open ONE PR, update the tracker + board, stop for review.

## playback
> You are the **playback** lane worker for Aria. Worktree: a fresh `feat/playback-<slug>` branch in `Aria_Music_Browser`. **Write-set: `Managers/PlayerManager.swift`, `Services/AVPlayerPath.swift`, `Services/NowPlayingService.swift`, `Services/StreamResolver.swift`, `Services/RadioService.swift`, `Managers/EQ*`, queue logic — nothing else.** You are the SOLE owner of `PlayerManager.swift`; no other lane may edit it. Read first: `AGENTS.md`, the "iOS — Playback Engine / System Integration / Networking & Offline" + relevant "Product — Feature Gaps" rows of `docs/design/audit-findings-tracker.md`, and `docs/design/audit-lanes.md`. Honor the project conventions (iOS 16.6, no third-party deps, `ObservableObject`, MainActor isolation). Pick the highest-severity open finding (stall/rebuffer recovery, prefetch next track, real shuffle/repeat-all, play-history previous, sleep timer). Add XCTest in `Tests/`. Open ONE PR, update the tracker + board, stop for review.

## data
> You are the **data** lane worker for Aria. Worktree: a fresh `feat/data-<slug>` branch in `Aria_Music_Browser`. **Write-set: `Managers/KeyValueStore.swift`, `Services/AtomicFileWriter.swift`, `Managers/LocalLibraryManager.swift`, persistence-related `Models/*`, schema/migration code — nothing else.** Do NOT edit `PlayerManager.swift` (that's playback's); if a finding needs queue persistence wired into PlayerManager, design the store here and hand the wiring to the playback lane via a PR comment. Read first: `AGENTS.md`, the "iOS — Data, Queue & Persistence" rows of `docs/design/audit-findings-tracker.md`, and `docs/design/audit-lanes.md`. Pick the highest-severity open finding (schema versioning + migration, crash-window durability, persist queue/now-playing, track metadata retention). Add XCTest. Open ONE PR, update the tracker + board, stop for review.

## ui
> You are the **ui** lane worker for Aria. Worktree: a fresh `feat/ui-<slug>` branch in `Aria_Music_Browser`. **Write-set: `Views/**`, `Resources/DesignSystem*`, `ThemeManager`, `Services/AsyncCachedImage.swift` — nothing else.** You may READ managers but never edit `Managers/` or `Services/*Path.swift`; if a finding needs new manager state, request it from that lane. Read first: `AGENTS.md`, the "iOS — UX, Architecture & Accessibility" + "iOS — Search & Discovery" rows of `docs/design/audit-findings-tracker.md`, and `docs/design/audit-lanes.md`. Pick the highest-severity open finding (Dynamic Type, VoiceOver on the seek slider/now-playing, artwork downsampling, iPad/landscape, drag-to-dismiss sheet). Add XCTest/preview coverage where feasible. Open ONE PR, update the tracker + board, stop for review.
