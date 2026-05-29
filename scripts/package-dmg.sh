#!/usr/bin/env bash
set -euo pipefail

PRODUCT_NAME="Latency Graph for ClashX Meta"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
CONFIGURATION="${1:-release}"

cd "$ROOT_DIR"
PACKAGE_OUTPUT="$("$ROOT_DIR/scripts/package-app.sh" "$CONFIGURATION")"
APP_PATH="$(printf "%s\n" "$PACKAGE_OUTPUT" | tail -n 1)"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")"
DMG_PATH="$DIST_DIR/$PRODUCT_NAME-$VERSION.dmg"
STAGE_DIR="${TMPDIR:-/tmp}/latency-graph-dmg.$$"

trap 'rm -rf "$STAGE_DIR"' EXIT
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"

ditto --norsrc "$APP_PATH" "$STAGE_DIR/$PRODUCT_NAME.app"
ln -s /Applications "$STAGE_DIR/Applications"

hdiutil create \
    -volname "$PRODUCT_NAME $VERSION" \
    -srcfolder "$STAGE_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH" >/dev/null

echo "$DMG_PATH"
