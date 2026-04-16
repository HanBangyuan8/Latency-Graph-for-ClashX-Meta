# Changelog

## v1.2.1 - 2026-04-16

Patch release.

- Added version-specific hand-written nonlinear motion profiles for macOS 10.15/11, macOS 12, macOS 13/14, and macOS 15+.
- Tuned animation behavior separately for Apple Silicon and Intel Macs.
- Added custom startup motion for modern and legacy runtime paths.
- Added custom page switching motion without introducing new hover animations.
- Added custom pressed-state motion for sidebar page selection and legacy controls.
- Standardized component entrance timing within each page so cards, sections, and records enter at the same speed.
- Reduced chart page-switch entrance strength for a calmer transition.
- Reduced page transition travel distance to avoid overly strong chart movement.
- Removed shaded area and dense bar rendering from the Overview combined latency chart so only meaningful multi-node trend lines remain.
- Kept single-node charts unchanged so their existing filled visual style remains available.
- Verified release build with `swift build -c release`.

## v1.2.0 - 2026-04-16

Major compatibility and runtime optimization release.

- Restored the macOS 13+ native SwiftUI `WindowGroup` + `NavigationSplitView` lifecycle used by v1.0.0 through v1.1.1.
- Fixed the titlebar/sidebar regression caused by the previous AppKit-hosted compatibility window on newer macOS versions.
- Kept macOS 12 on the compatibility window path instead of forcing it through newer UI assumptions.
- Kept macOS 10.15 and macOS 11 on the legacy fixed-sidebar path; sidebar closing is intentionally unavailable there.
- Added explicit runtime feature planning so each macOS generation activates only the necessary lifecycle, sidebar, transition, probing, and persistence behavior.
- Added separate runtime profiles for macOS 10.15/11, macOS 12, macOS 13/14, and macOS 15+.
- Added separate runtime tuning for Apple Silicon and Intel Macs.
- Added a dedicated probe batch executor for bounded multi-node concurrency.
- Added bounded per-node sample concurrency so sample count no longer blindly multiplies runtime pressure.
- Kept multi-sample latency selection based on the minimum successful sample.
- Batched probe record appends so a multi-node probe writes UI state once per batch instead of once per node.
- Added debounced SQLite persistence to reduce high-frequency disk writes during monitoring.
- Added runtime-specific history retention windows to limit memory and database pressure on older systems.
- Added a record retention policy source module.
- Added a runtime feature plan source module.
- Added a probe batch executor source module.
- Split launcher logic into its own source file.
- Increased source file separation to make future compatibility work safer.
- Updated bundle version metadata to v1.2.0.
- Updated project documentation to state that runtime compatibility begins at macOS 10.15, while the complete intended feature set is supported on macOS 15+.
- Documented that macOS 14 and earlier are compatibility targets only; version-specific bugs or imperfect UI there are expected rather than fully supported.

## v1.1.1 - 2026-04-15

Patch release.

- Refined Settings page styling to avoid the previous heavy blur/material look.
- Moved Settings section titles outside their cards for a layout closer to the main pages.
- Restored Control button colors to native system bordered and bordered-prominent styles.
- Kept Control buttons equal-width based on the longest localized control label.
- Added lightweight hover feedback for Control buttons without changing their native colors.
- Added staggered group entry animations to regular Overview and node pages.
- Added a stronger directional chart reveal animation for page switches.
- Reduced animation cost by removing heavier hover shadow, scale, and brightness effects from panels.
- Reduced dense chart overdraw by skipping per-point bar marks when a chart has many rendered points.
- Improved Recent Records table resizing so it can shrink with smaller windows and updates height without animation.

## v1.1.0 - 2026-04-14

Major release.

- Added chart downsampling for long time ranges so 24h, 7d, 1m, and 3m views render fewer points while preserving trend shape, local highs/lows, first/last bucket samples, and failure markers.
- Tightened node page rendering budgets so single-node pages actually downsample dense history instead of passing nearly all points through.
- Relaxed Overview chart budgets so combined multi-node charts keep more per-node detail and do not flatten trends too aggressively.
- Disabled expensive implicit chart data animations during record refreshes to reduce stutter while monitoring is running.
- Added a GitHub Release update checker that reads the latest public release from `HanBangyuan8/Latency-Graph-for-ClashX-Meta`.
- Added automatic daily update checks using a stored last-check timestamp.
- Added a manual “Check for Updates” control in the sidebar.
- Added update status text and an “Open Download Page” action when a newer release is available.
- Added semantic version comparison for GitHub release tags such as `v1.1.0`.
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
- Moved settings into separate cards instead of one large global shadow panel.
- Split settings into “Connection & Auth”, “Monitored Nodes”, and “Probe Settings” sections.
- Fixed the language selector so language names are always shown in their own native forms: `English`, `简体中文`, and `繁體中文`.
- Added missing localization keys for update checking, settings section names, Overview, Language, Controller URL, and Secret.
- Kept English, Simplified Chinese, and Traditional Chinese UI modes aligned for the new controls and labels.
- Split chart downsampling into a dedicated `ChartDownsampler` module with separate budgets for node pages, Overview, menu bar sparkline, and default chart consumers.
- Added a dedicated `MotionSystem` module for reusable low-cost animation tokens and interaction modifiers.
- Split several responsibilities into new source files: chart downsampling, motion/animation helpers, GitHub release update checking, and persistence worker logic.
- Added a `ProbePersistenceWorker` actor so SQLite saves run serially off the main UI flow.
- Marked probe records as `Sendable` for safer async persistence snapshots.
- Kept multi-sample probing behavior from v1.0.2: multiple samples per point record the minimum successful latency sample instead of an average.

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
