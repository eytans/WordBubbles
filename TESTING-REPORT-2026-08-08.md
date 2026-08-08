# WordBubbles 16-Agent Test Report

Date: 2026-08-08
Tested build: `1.1.0+3` / commit `80a0c9e`
Target release: `1.1.0+4` after the fixes in this report

## Executive summary

Sixteen independent test passes covered gameplay, round progression, both visual modes, responsive layouts, music, text-to-speech, accessibility, pointer input, physics, offline assets, browser compatibility, endurance, and release readiness.

The release candidate had one blocker and several reproducible usability defects. The blocker was a Chromium web startup failure (`RenderBox was not laid out`) in some test sessions. The main gameplay defect was random bubble overlap, which could hide a bubble or place it below the music controls. The patch associated with this report adds explicit web layout constraints, local CanvasKit loading, collision-aware placement and movement, responsive title positioning, a reserved control inset, keyboard activation, speech timeout recovery, and clearer web privacy wording.

## Test assignments and results

| Pass | Area | Result |
| --- | --- | --- |
| 1 | Happy-path gameplay and reset | Pass; full three-set rollover not deterministic in the live session |
| 2 | Round progression and timers | Source pass; deterministic three-set test remains a follow-up |
| 3 | Emoji mode, mappings, hit targets | Found overlap and edge-scale risks |
| 4 | Photo cards and fallbacks | Pass |
| 5 | Mobile portrait at 320x568 and 375x667 | Found title/progress and control overlap |
| 6 | Tablet landscape | No confirmed defect; device rotation not available |
| 7 | Desktop responsive layouts | Found bubbles under music controls at narrower sizes |
| 8 | Background music and volume | Pass; blocked-audio behavior not fully observable |
| 9 | Text-to-speech and rapid taps | Found unbounded speech completion and silent unsupported-browser failure |
| 10 | Accessibility and keyboard navigation | Found missing bubble focus and nested semantics |
| 11 | Pointer/touch input | Bubble taps failed in one live Chromium session; control taps worked |
| 12 | Physics and lifecycle | Reproduced overlap; reload/unmount safety passed |
| 13 | Offline assets and startup | Found external default CanvasKit dependency |
| 14 | Browser compatibility | Found Chromium `RenderBox was not laid out` startup failure |
| 15 | Performance and endurance | No visible degradation in a one-minute pass |
| 16 | Android/CI/Play release audit | Found stale version docs and excessive workflow permissions |

## Defects addressed

| ID | Severity | Finding | Fix |
| --- | --- | --- | --- |
| WEB-01 | Blocker | Some Chromium sessions exposed only “Enable accessibility” and logged `RenderBox was not laid out`. | Removed the nested background layout dependency, made the bubble stack explicitly expand to its constraints, and configured the web loader to use the bundled CanvasKit runtime. |
| GAME-01 | High | Independently randomized bubbles could overlap and obscure a target. | Added rejection-based initial placement plus per-frame separation and a regression test with colliding starting positions. |
| LAYOUT-01 | Medium | The title wrapped into the progress badge at 320x568. | Added compact responsive sizing, a single-line scale-down title, and a lower compact progress position. |
| LAYOUT-02 | Medium | Bottom bubbles could sit under the music or visual controls. | Reserved a bottom control inset and kept the active-scale margin inside the usable bounds. |
| AUDIO-01 | Medium | A TTS implementation that never completes could stall the speech queue and bubble cleanup. | Added an eight-second timeout, best-effort TTS stop, cleanup in `finally`, and a non-blocking user notice when speech is unavailable. |
| A11Y-01 | High | Bubbles were not reachable through keyboard Tab navigation. | Added keyboard-focusable activation with Enter and Space. |
| A11Y-02 | Medium | Emoji/photo children created nested semantic button roles. | Exposed one labeled semantic control per bubble and excluded the visual child semantics. |
| RELEASE-01 | Medium | README and lockfile documentation described obsolete version `1.1.0+2`; `http` was unused. | Bumped the next Play artifact to `1.1.0+4`, removed the unused dependency, and refreshed release documentation. |
| RELEASE-02 | Medium | The release workflow granted repository write permission to all jobs. | Defaulted to read-only and granted `contents: write` only to the release-creation job. |
| PRIV-01 | Medium | The privacy page claimed the web build never connects externally despite the default hosted CanvasKit runtime. | Scoped offline/no-service claims to the packaged Android app and disclosed the web runtime asset behavior. |

## Passed areas with no confirmed defect

- Photo-card selection, bundled photo assets, emoji fallback, and switching back to Emoji mode.
- Music mute, volume slider, icon state, bundled audio path, and source-level lifecycle guards.
- Bubble bounds, reload/unmount guards, timer cancellation, and visible progress updates.
- Android target API 36, release signing verification, no runtime permissions in the main manifest, and local content assets.
- One-minute endurance pass without visible jank, degradation, or console errors.

## Feature backlog and test gaps

These are product improvements or coverage gaps, not release-blocking defects:

1. Add a first-run “How to play” overlay and a visible help/settings entry.
2. Decide whether progress should persist locally between sessions.
3. Decide whether the learning design needs an explicit target word and incorrect-answer feedback; the current design treats every bubble tap as a successful find.
4. Add deterministic fake audio/TTS tests for blocked playback, lifecycle pause/resume, and speech completion.
5. Run physical Android touch, background/foreground, Safari, and Firefox passes.
6. Pin third-party GitHub Actions to reviewed commit SHAs in a separate maintenance change.
7. Add a deterministic three-set widget test covering the image rollover and repeated rounds.

## Verification record

- Local Flutter/Dart was unavailable in the Codex environment, so CI is the authority for `flutter analyze`, widget tests, Android packaging, and the web build.
- Existing unrelated worktree changes were preserved: `.gitignore`, `.projectmem/`, and `CLAUDE.md`.
- Post-fix verification and Play Closed testing upload are recorded in the release closeout below.

## Release closeout

- [ ] GitHub Actions test/analyze green
- [ ] GitHub Pages build green and live Chromium smoke pass shows game controls and bubbles
- [ ] Signed AAB version code 4 generated and verified
- [ ] Google Play Closed testing updated with version code 4
- [ ] Play Console testing-track state and account-policy status rechecked
