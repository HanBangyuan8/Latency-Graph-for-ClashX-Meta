# Latency Graph for ClashX Meta

![macOS](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![GitHub release](https://img.shields.io/github/v/release/HanBangyuan8/Latency-Graph-for-ClashX-Meta)
![GitHub Downloads](https://img.shields.io/github/downloads/HanBangyuan8/Latency-Graph-for-ClashX-Meta/total)
![GitHub Repo stars](https://img.shields.io/github/stars/HanBangyuan8/Latency-Graph-for-ClashX-Meta?style=social)

A native macOS menu bar app for monitoring ClashX Meta / Clash Meta proxy latency.

## Features

- Multi-node latency monitoring with per-node pages
- Overview page with 24h stats and combined latency chart
- Configurable probe interval, timeout, target URL, and sample count
- Menu bar panel with latest latency and recent trend
- Local SQLite history database
- English, Simplified Chinese, and Traditional Chinese UI

## Screenshots

<img src="081657eb-d98f-4e92-bd0f-71a2d50eab4b.png" alt="Overview" width="900">

<img src="3fb6f419-a19b-4449-8a48-2203bd34af70.png" alt="Node detail" width="900">

## Requirements

- macOS 13+
- Xcode 15+ or Swift 5.9+
- ClashX Meta / Clash Meta with `external-controller` enabled

## Build

```bash
swift build
```

## Run

```bash
swift run
```

## Package

```bash
./scripts/package-app.sh
open "dist/Latency Graph for ClashX Meta.app"
```

## Data Location

Probe history is stored locally at:

```text
~/Library/Application Support/Latency Graph for ClashX Meta/probes.sqlite
```

Legacy `probes.json` data is imported automatically on first launch after upgrading to the SQLite version.

## Release

Download the latest signed ad-hoc macOS app archive from [GitHub Releases](https://github.com/HanBangyuan8/Latency-Graph-for-ClashX-Meta/releases).

Release notes are maintained in `CHANGELOG.md`.

## License

Copyright © 2026 Han. All rights reserved.

## Stargazers

[![Stargazers over time](https://starchart.cc/HanBangyuan8/Latency-Graph-for-ClashX-Meta.svg?variant=adaptive)](https://starchart.cc/HanBangyuan8/Latency-Graph-for-ClashX-Meta)
