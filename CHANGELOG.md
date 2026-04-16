# Changelog

## v1.2.2 - 2026-04-16

Patch release.

- Added a sidebar Motion setting with Enhanced and Reduced modes.
- Kept Enhanced as the current stronger page-transition motion.
- Restored Reduced as the calmer v1.2.1-style page-transition behavior.
- Persisted the selected motion mode across launches.

## v1.2.1 - 2026-04-16

Patch release.

- Added version-specific nonlinear motion profiles for macOS 10.15/11, 12, 13/14, and 15+.
- Added custom startup, page-switching, and pressed-state animations without adding new hover effects.
- Standardized component entrance timing within pages.
- Reduced chart and page transition strength for calmer switching.
- Simplified the Overview combined chart to show trend lines only.

## v1.2.0 - 2026-04-16

Major compatibility and runtime optimization release.

- Restored the native macOS 13+ SwiftUI window/sidebar behavior.
- Added separate runtime paths for macOS 10.15/11, 12, 13/14, and 15+.
- Added Apple Silicon and Intel runtime tuning.
- Added bounded multi-node probe concurrency and batched probe record updates.
- Added debounced SQLite persistence and runtime-specific history retention.
- Split launcher, runtime planning, probe batching, and retention logic into dedicated source files.
- Updated app metadata and documentation for macOS 10.15+ runtime compatibility.

## v1.1.1 - 2026-04-15

Patch release.

- Refined Settings page layout and removed the heavy blur-style panel.
- Restored native Control button colors while keeping localized equal-width sizing.
- Improved page/card animation cost and dense chart rendering behavior.
- Improved Recent Records resizing for smaller windows.

## v1.1.0 - 2026-04-14

Major release.

- Added chart downsampling for long ranges while preserving trends, outliers, and failure markers.
- Added GitHub Release update checking with daily automatic checks and a manual sidebar action.
- Reworked page transition direction and spring-based motion with Reduce Motion support.
- Improved sidebar selection, click targets, stat-card sizing, and Recent Records styling.
- Moved settings into clearer grouped sections.
- Fixed language selector labels and added missing localization for new controls.
- Split chart, motion, update-checking, and persistence work into dedicated modules.
- Added async SQLite persistence via `ProbePersistenceWorker`.

## v1.0.2 - 2026-04-14

Patch release.

- Changed multi-sample latency probing to record the minimum successful sample.
- Updated sample count UI copy to describe minimum-sample selection.

## v1.0.1 - 2026-04-14

Patch release.

- Fixed English UI locale handling for date and time formatting.
- Fixed language selector labels in English and Traditional Chinese modes.
- Fixed localized display for common cancellation errors.

## v1.0.0 - 2026-04-13

Initial public release.

- Native macOS SwiftUI app for ClashX Meta / Clash Meta latency monitoring.
- Multi-node manual selection with per-node pages and an Overview page.
- Menu bar panel with latest latency and recent trend.
- Configurable Clash controller, probe target, interval, timeout, and sample count.
- SQLite-backed local history database with migration from legacy JSON history.
- English, Simplified Chinese, and Traditional Chinese UI modes.
- Configurable accent color palette.
