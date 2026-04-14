#!/usr/bin/env bash
set -euo pipefail

PRODUCT_NAME="Latency Graph for ClashX Meta"
BUNDLE_IDENTIFIER="com.han.LatencyGraphForClashXMeta"
CONFIGURATION="${1:-release}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$PRODUCT_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
CLANG_CACHE_DIR="$ROOT_DIR/.build/clang-module-cache"

cd "$ROOT_DIR"
mkdir -p "$CLANG_CACHE_DIR"
export CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR"

swift build -c "$CONFIGURATION"
BINARY_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"
BINARY_PATH="$BINARY_DIR/$PRODUCT_NAME"

if [[ ! -x "$BINARY_PATH" ]]; then
    echo "Built executable not found: $BINARY_PATH" >&2
    exit 1
fi

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$BINARY_PATH" "$MACOS_DIR/$PRODUCT_NAME"
chmod +x "$MACOS_DIR/$PRODUCT_NAME"

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>zh_CN</string>
    <key>CFBundleDisplayName</key>
    <string>$PRODUCT_NAME</string>
    <key>CFBundleExecutable</key>
    <string>$PRODUCT_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_IDENTIFIER</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$PRODUCT_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.1.1</string>
    <key>CFBundleVersion</key>
    <string>5</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <false/>
</dict>
</plist>
PLIST

if command -v codesign >/dev/null 2>&1; then
    if command -v xattr >/dev/null 2>&1; then
        xattr -cr "$APP_DIR"
    fi
    codesign --force --deep --sign - "$APP_DIR" >/dev/null
    if command -v xattr >/dev/null 2>&1; then
        xattr -cr "$APP_DIR"
    fi
    codesign --verify --deep "$APP_DIR"
fi

echo "$APP_DIR"
