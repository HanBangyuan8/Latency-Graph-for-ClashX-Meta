#!/usr/bin/env bash
set -euo pipefail

PRODUCT_NAME="Latency Graph for ClashX Meta"
BUNDLE_IDENTIFIER="com.han.LatencyGraphForClashXMeta"
CONFIGURATION="${1:-release}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
FINAL_APP_DIR="$DIST_DIR/$PRODUCT_NAME.app"
STAGE_DIR="${TMPDIR:-/tmp}/latency-graph-package.$$"
APP_DIR="$STAGE_DIR/$PRODUCT_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
CLANG_CACHE_DIR="$ROOT_DIR/.build/clang-module-cache"
ARCH_FLAGS=()
USE_ARCH_FLAGS=0

cd "$ROOT_DIR"
mkdir -p "$CLANG_CACHE_DIR"
export CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR"
export MACOSX_DEPLOYMENT_TARGET="10.15"
trap 'rm -rf "$STAGE_DIR"' EXIT

clean_bundle_metadata() {
    local bundle_dir="${1:-$APP_DIR}"
    find "$bundle_dir" -name "._*" -delete
    if command -v dot_clean >/dev/null 2>&1; then
        dot_clean -m "$bundle_dir"
    fi
    if command -v xattr >/dev/null 2>&1; then
        xattr -cr "$bundle_dir" 2>/dev/null || true
        while IFS= read -r -d '' file_path; do
            xattr -d com.apple.FinderInfo "$file_path" 2>/dev/null || true
            xattr -d 'com.apple.fileprovider.fpfs#P' "$file_path" 2>/dev/null || true
        done < <(find "$bundle_dir" -print0)
    fi
}

if [[ "$(uname -s)" == "Darwin" ]]; then
    ARCH_FLAGS=(--arch arm64 --arch x86_64)
    USE_ARCH_FLAGS=1
fi

if ! swift build -c "$CONFIGURATION" "${ARCH_FLAGS[@]}"; then
    echo "Universal build failed; retrying for the current host architecture." >&2
    ARCH_FLAGS=()
    USE_ARCH_FLAGS=0
    swift build -c "$CONFIGURATION"
fi

if [[ "$USE_ARCH_FLAGS" == "1" ]]; then
    BINARY_DIR="$(swift build -c "$CONFIGURATION" "${ARCH_FLAGS[@]}" --show-bin-path)"
else
    BINARY_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"
fi
BINARY_PATH="$BINARY_DIR/$PRODUCT_NAME"

if [[ ! -x "$BINARY_PATH" ]]; then
    echo "Built executable not found: $BINARY_PATH" >&2
    exit 1
fi

rm -rf "$STAGE_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$BINARY_PATH" "$MACOS_DIR/$PRODUCT_NAME"
chmod +x "$MACOS_DIR/$PRODUCT_NAME"
clean_bundle_metadata

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
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>CFBundleShortVersionString</key>
    <string>1.2.0</string>
    <key>CFBundleVersion</key>
    <string>6</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <false/>
</dict>
</plist>
PLIST

if command -v codesign >/dev/null 2>&1; then
    clean_bundle_metadata
    codesign --force --deep --sign - "$APP_DIR" >/dev/null
    clean_bundle_metadata
    codesign --verify --deep --strict "$APP_DIR"
fi

mkdir -p "$DIST_DIR"
rm -rf "$FINAL_APP_DIR"
ditto --norsrc "$APP_DIR" "$FINAL_APP_DIR"
clean_bundle_metadata "$FINAL_APP_DIR"
if command -v codesign >/dev/null 2>&1; then
    codesign --verify --deep "$FINAL_APP_DIR"
fi

echo "$FINAL_APP_DIR"
