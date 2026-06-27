# EQ via MTAudioProcessingTap — Design

Status: **design / sanity-check** · Branch: `feat/eq-tap` (off `feat/progressive-radio`) · Date: 2026-06-27

## Why

Almost every EQ bug we've fought — the format-mismatch crash, the OOB PCM copy,
the bit-depth trap, the seek desync, the 10–20s EQ-engage wait, the
toggle-silence, the dual-path switching races — is a *symptom* of one wrong
foundation: **`AVAudioEngine` + `AVAssetReader`, which needs the whole file on
disk.** That tool is for local files, not streaming, so we bolted on a download,
a cache, and a second playback path. The bolt-on is where the bugs live.

The right foundation for *EQ on a live stream* is **`MTAudioProcessingTap`**
(MediaToolbox): tap `AVPlayer`'s audio in real time and run DSP on the buffers
as they stream — no download, no second engine. Available since iOS 6;
comfortably within our iOS 16.6 target.

## Target architecture

**One playback path.** `AVPlayer` plays everything — streamed direct URL
(`/api/resolve`) or local file. EQ is an `MTAudioProcessingTap` on the player
item's `audioMix`, hosting an `AUNBandEQ` audio unit. Toggling EQ = enable/bypass
the unit. Band changes = `AudioUnitSetParameter` (real-time-safe, callable from
the UI thread).

```
AVPlayer ── AVPlayerItem ── audioMix ── MTAudioProcessingTap
                                              │ process callback (RT thread)
                                              ▼
                                   MTAudioProcessingTapGetSourceAudio
                                              │
                                              ▼
                                   AudioUnitRender(AUNBandEQ)  ← 10 bands
                                              │
                                              ▼
                                        output buffers
```

## Mechanics

- **Tap:** `MTAudioProcessingTapCreate` with callbacks (init / finalize /
  prepare / unprepare / process). `prepare` gives the processing format (sample
  rate, channels) — initialize the hosted AU there. `process` calls
  `MTAudioProcessingTapGetSourceAudio` to pull source PCM, renders it through the
  AU in place, outputs.
- **Attach:** `AVMutableAudioMixInputParameters(track:)` with
  `audioTapProcessor = tap`; wrap in an `AVMutableAudioMix`; set
  `playerItem.audioMix`.
- **EQ unit:** host `kAudioUnitSubType_NBandEQ` (Apple). Configure 10 bands at
  our existing `PlayerManager.eqFrequencies`. Per-band gain via
  `AudioUnitSetParameter` — Apple documents this as real-time-safe, so band
  changes can come straight from the main thread; **no manual lock-free handoff
  needed.** Global bypass toggles EQ on/off without re-attaching the mix.
- **Real-time rules:** the `process` callback runs on an audio RT thread — no
  allocations, locks, or ARC churn inside it. State we need there (the AU, the
  format) is set up in `prepare` and read by pointer.

## Phased migration (app stays working throughout)

1. **`AudioEQTap` component** — the tap + hosted `AUNBandEQ`, standalone and
   unit-testable: feed a known buffer, assert the gain is applied. No player
   wiring yet. *(Build it green before touching playback.)*
2. **Wire into `AVPlayerPath`** — attach the `audioMix` and apply current bands
   when EQ is on; bypass when off; update params on band change. `AVPlayer` plays
   the **same** resolved URL whether EQ is on or off. `fetchStreamURL` stops
   branching on `eq.isEnabled` — always the AVPlayer path.
3. **Delete the engine path** — remove `downloadAndPlayEngine`, `startEngine`,
   `createPCMBuffer`, the schedule loop, `prepareEngineSwap`,
   `switchToEnginePlayback`, `switchBackToPlayer`, `seekEngine`, `pollEngineTime`,
   `EQCache`, and the engine/swap state (`isUsingEngine`, `switchingToEngine`,
   `pendingEngineSwitch`, `isStartingEngine`, `engineSwapTask`, `engineSeekOffset`,
   `scheduleGeneration`, …). Roughly half of `PlayerManager` and most of its
   fragility.
4. **Local files** — the same `AVPlayer` + tap plays FLAC/MP3 imports with EQ.
   Verify hi-res (96 kHz) renders correctly through the AU.

## What this fixes / deletes

- **EQ becomes instant** — no download, no `EQCache`, no preparing-download wait.
  Bugs A & C (the 10–20s wait) *disappear*.
- **Seek/pause/duration native** — `AVPlayer` owns them. The seek desync, the 2×
  DASH cap, the switching races stop being our problem.
- **One path** — no engine, no swap, no dual-path flags. The re-resolve and
  duration-cap logic we already built stay (they're AVPlayer-side).
- **Local + streamed unified** — same code plays both with EQ.

## Risks / unknowns to validate during build

- **Tap on a remote item:** the audio track is available once the item loads; set
  `audioMix` at/after readiness. Confirm the direct googlevideo URL exposes a
  single audio track the tap can attach to (it's progressive m4a — expected
  fine).
- **Toggle mid-playback:** prefer AU **bypass** over swapping `audioMix` live
  (smoother; no re-attach hitch). Validate band changes are click-free.
- **`AUNBandEQ` config:** confirm 10 configurable bands at our frequencies via
  `kAUNBandEQProperty_NumberOfBands` + per-band frequency params.
- **RT-thread discipline:** keep the `process` callback allocation/lock free;
  bridge state via pointers set in `prepare`.
- **Format changes across tracks:** AU re-prepared per item (new tap per
  `AVPlayerItem`), so each track's format is handled fresh.

## Conflict surface

- Builds on `feat/progressive-radio` (single AVPlayer path + resolve + radio).
- Supersedes the engine fixes in `feat/eq-crash-fixes` (PR #3) — those fixed the
  engine path we're deleting. Decision needed: merge #3 first (it's strictly
  better than main for the interim), or let the tap work obsolete it.

## Open decision for sign-off

Before implementing: confirm the **hosted `AUNBandEQ`** approach (vs. hand-rolled
Accelerate biquads). AU is less code, matches the current 10-band semantics, and
its params are RT-safe — recommended. Biquads give more control but are more code
and more RT-correctness burden.
