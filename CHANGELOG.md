# Changelog

## v1.1.0 - 2026-04-14

Feature and polish release since v1.0.2.

### Latency probing and chart performance

- Added chart downsampling for long time ranges so 24h, 7d, 1m, and 3m views render fewer points while preserving trend shape, local highs/lows, first/last bucket samples, and failure markers.
- Split chart downsampling into a dedicated `ChartDownsampler` module with separate budgets for node pages, Overview, menu bar sparkline, and default chart consumers.
- Tightened node page rendering budgets so single-node pages actually downsample dense history instead of passing nearly all points through.
- Relaxed Overview chart budgets compared with the first draft so combined multi-node charts keep more per-node detail and do not flatten trends too aggressively.
- Disabled expensive implicit chart data animations during record refreshes to reduce stutter while monitoring is running.
- Kept multi-sample probing behavior from v1.0.2: multiple samples per point now record the minimum successful latency sample instead of an average.

### Update checking

- Added a GitHub Release update checker that reads the latest public release from `HanBangyuan8/Latency-Graph-for-ClashX-Meta`.
- Added automatic daily update checks using a stored last-check timestamp.
- Added a manual “Check for Updates” control in the sidebar.
- Added update status text and an “Open Download Page” action when a newer release is available.
- Added semantic version comparison for GitHub release tags such as `v1.1.0`.

### UI, animation, and interaction

- Added a dedicated `MotionSystem` module for reusable low-cost animation tokens and interaction modifiers.
- Reworked page transition direction so moving to a lower sidebar page enters from below, and moving to a higher sidebar page enters from above.
- Changed page and selection animations from short linear/ease transitions to slower spring-based motion with a more native macOS feel.
- Added Reduce Motion support to the new animation paths.
- Added animated sidebar selection backgrounds with rounded corners, while removing the darker left indicator line.
- Increased sidebar click hit areas without increasing the visible row size.
- Added subtle hover treatment for cards and panels using light stroke/brightness changes instead of heavy effects.
- Reduced statistic-card title and value typography so the five-card top row and Overview rows fit more cleanly.
- Added rounded styling to the Recent Records table container.
- Reworked Recent Records table sizing to use measured available window space rather than a fixed constant height.
- Added real bottom padding behavior based on measured table position rather than a guessed spacer.
- Removed whole-page animation on every new data point to avoid unnecessary UI movement during monitoring.

### Settings layout

- Moved settings into separate cards instead of one large global shadow panel.
- Split settings into “Connection & Auth”, “Monitored Nodes”, and “Probe Settings” sections.
- Kept controller URL, secret, proxy group, manual node selection, probe target, data point interval, timeout, and sample count controls in the settings page.

### Localization

- Fixed the language selector so language names are always shown in their own native forms: `English`, `简体中文`, and `繁體中文`.
- Added missing localization keys for update checking, settings section names, Overview, Language, Controller URL, and Secret.
- Kept English, Simplified Chinese, and Traditional Chinese UI modes aligned for the new controls.

### Internal structure and persistence

- Split several responsibilities into new source files: chart downsampling, motion/animation helpers, GitHub release update checking, and persistence worker logic.
- Added a `ProbePersistenceWorker` actor so SQLite saves run serially off the main UI flow.
- Marked probe records as `Sendable` for safer async persistence snapshots.

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
- Multi-node manual selection with per-node pages.
- Overview page with per-node 24h stats and combined multi-node latency chart.
- Menu bar panel with latest latency and recent trend.
- Configurable controller URL, secret, proxy group, target URL, data point interval, timeout, and probe sample count.
- SQLite-backed local history database with automatic migration from legacy JSON history.
- English, Simplified Chinese, and Traditional Chinese UI modes.
- Configurable accent color palette.
