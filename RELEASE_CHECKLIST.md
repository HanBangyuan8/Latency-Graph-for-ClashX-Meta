# v1.0.0 Release Checklist

## Before Publishing

- Run `swift build`.
- Run `./scripts/package-app.sh`.
- Open `dist/Latency Graph for ClashX Meta.app` locally and confirm the app starts.
- Confirm ClashX Meta external controller settings work with your local config.
- Confirm the database is created at `~/Library/Application Support/Latency Graph for ClashX Meta/probes.sqlite`.

## Create the GitHub Release

1. Commit all files.
2. Create and push tag `v1.0.0`.
3. Upload `dist/Latency Graph for ClashX Meta.app` or a zipped copy of it to the GitHub release.
4. Use the `CHANGELOG.md` v1.0.0 notes as the release description.

## Terminal Commands

```bash
swift build
./scripts/package-app.sh
ditto --norsrc -c -k --keepParent "dist/Latency Graph for ClashX Meta.app" "dist/Latency Graph for ClashX Meta-v1.0.0-macOS.zip"
git init
git add .
git commit -m "Release v1.0.0"
git branch -M main
git tag v1.0.0
```

After creating an empty public repository on GitHub, run:

```bash
git remote add origin https://github.com/YOUR-USERNAME/Latency-Graph-for-ClashX-Meta.git
git push -u origin main
git push origin v1.0.0
```
