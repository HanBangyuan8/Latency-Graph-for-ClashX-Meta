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
ARCHS="$(lipo -archs "$APP_PATH/Contents/MacOS/$PRODUCT_NAME")"
if [[ "$ARCHS" == *"arm64"* && "$ARCHS" == *"x86_64"* ]]; then
    ARCH_LABEL="universal"
elif [[ "$ARCHS" == *"arm64"* ]]; then
    ARCH_LABEL="arm64"
else
    ARCH_LABEL="x86_64"
fi
ARTIFACT_BASENAME="Latency-Graph-for-ClashX-Meta-v${VERSION}-macOS-${ARCH_LABEL}"
ZIP_PATH="$DIST_DIR/${ARTIFACT_BASENAME}.zip"
DMG_PATH="$DIST_DIR/${ARTIFACT_BASENAME}.dmg"
STAGE_DIR="${TMPDIR:-/tmp}/latency-graph-dmg.$$"

trap 'rm -rf "$STAGE_DIR"' EXIT
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"

ditto --norsrc "$APP_PATH" "$STAGE_DIR/$PRODUCT_NAME.app"
ln -s /Applications "$STAGE_DIR/Applications"

ditto -c -k --norsrc --keepParent "$APP_PATH" "$ZIP_PATH"

hdiutil create \
    -volname "$PRODUCT_NAME $VERSION" \
    -srcfolder "$STAGE_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH" >/dev/null

printf '%s\n%s\n' "$ZIP_PATH" "$DMG_PATH"
