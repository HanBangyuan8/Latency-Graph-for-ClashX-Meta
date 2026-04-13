# Latency Graph for ClashX Meta

Latency Graph for ClashX Meta is a native macOS SwiftUI monitor for Clash / Clash.Meta controllers.

## Features

- Connects to a Clash or Clash.Meta `external-controller`
- Tests proxy delay on a configurable interval
- Stores historical probe records in a local SQLite database
- Calculates 24h availability, packet loss, average latency, and peak latency
- Shows a latency chart using Swift Charts, including spike bars for jitter visibility
- Records multiple manually selected nodes, the current node in a group, or every node in a selected proxy group
- Includes a menu bar extra with the latest latency and a compact 4h sparkline

## Requirements

- macOS 13+
- Xcode 15+ or Swift 5.9+
- Clash / Clash.Meta with `external-controller` enabled

Example Clash config:

```yaml
external-controller: 127.0.0.1:9090
secret: your-secret
```

## Run

Open the folder in Xcode and run the `Latency Graph for ClashX Meta` executable target.

Or from Terminal on macOS:

```bash
cd "/Users/han/Documents/HS/插件开发/Latency Graph for ClashX Meta"
swift run
```

## Package as a macOS app

Build a signed local `.app` bundle into `dist/`:

```bash
cd "/Users/han/Documents/HS/插件开发/Latency Graph for ClashX Meta"
./scripts/package-app.sh
open "dist/Latency Graph for ClashX Meta.app"
```

The package script builds a release executable, wraps it in `Latency Graph for ClashX Meta.app`, writes the app `Info.plist`, and applies ad-hoc code signing for local use.

## Local data

Latency Graph for ClashX Meta stores app data in the normal per-user macOS Application Support folder:

```text
~/Library/Application Support/Latency Graph for ClashX Meta/
```

The current history database is:

```text
~/Library/Application Support/Latency Graph for ClashX Meta/probes.sqlite
```

Older builds stored history in `probes.json`. On first launch after the SQLite upgrade, the app automatically imports `probes.json` into `probes.sqlite` if the SQLite database is empty.

## GitHub and release

This repository is prepared for a public GitHub release:

- `.gitignore` excludes local build products, packaged apps, and macOS metadata.
- `LICENSE` keeps the project public but all rights reserved under Han's copyright.
- `CHANGELOG.md` includes the initial `v1.0.0` release notes.
- `RELEASE_CHECKLIST.md` contains the exact commands for creating the first commit, tag, zip artifact, and GitHub release.

If you want others to freely reuse or modify the code later, replace `LICENSE` with an open-source license such as MIT before publishing.

## Use with ClashX Meta

1. Make sure ClashX Meta / Clash.Meta has `external-controller` enabled, usually `127.0.0.1:9090`.
2. If your Clash config has a `secret`, enter the same value in Latency Graph for ClashX Meta settings.
3. Click `刷新代理列表`.
4. In `手动多选节点`, check the nodes you want to monitor together. Each selected node gets its own page in the sidebar.
5. Enable `跟随代理组当前节点` only if you want the chart to track the currently selected node in a group such as `GLOBAL`.
6. Enable `自动监控代理组所有节点` only if you want one sidebar page for every node in the selected proxy group.
7. Set `数据点间隔` in milliseconds to control how often a new sample batch is recorded.
8. Set `测速超时` to control the Clash `/delay` timeout.
9. Set `每点探测次数` to run each datapoint multiple times and record the median latency, reducing one-off probe jitter without hiding valid data.
10. Click `开始监控`. The menu bar panel shows the latest delay plus the recent 4h trend.

## Notes

- If your controller uses a different path or port, update it in Settings.
- The app records probe history into `~/Library/Application Support/Latency Graph for ClashX Meta/probes.sqlite`.
- The default delay target is `https://www.gstatic.com/generate_204`.
- Proxy names are URL-encoded before calling `/proxies/{name}/delay`, so node names containing `/`, `?`, `#`, spaces, or emoji should work.
