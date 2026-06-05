#!/usr/bin/env bash
# shoot_screenshots.sh — capture raw App Store screenshots.
#
# Builds the app (Debug), boots iPhone 17 Pro Max, and drives the DEBUG-only
# ScreenshotHarness (Swift) to render each screen as the app root, capturing
# 6 screens × 2 sets (en, zh-TW) = 12 raw PNGs into outputs/screenshots/raw/.
#
# The harness is compiled out of Release builds — see ScreenshotHarness.swift.
# Next step: tools/render_screenshots.swift overlays the marketing taglines.
#
# Usage:  bash tools/shoot_screenshots.sh

set -euo pipefail
cd "$(dirname "$0")/.."   # repo root

DEVICE_NAME="iPhone 17 Pro Max"
BUNDLE_ID="com.gotman.agenticlex"
OUT_DIR="outputs/screenshots/raw"
BUILD_LOG="/tmp/cclex_screenshot_build.log"
SCREENS=(today detail quiz browse settings dark)

mkdir -p "$OUT_DIR"

# --- locate + boot the simulator ----------------------------------------
UDID=$(xcrun simctl list devices available \
        | grep "$DEVICE_NAME (" | head -1 \
        | grep -oE '[0-9A-F-]{36}')
[ -z "${UDID:-}" ] && { echo "✗ no '$DEVICE_NAME' simulator found"; exit 1; }
echo "device : $DEVICE_NAME  ($UDID)"

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null

# --- build (Debug, simulator) -------------------------------------------
echo "build  : compiling (Debug)…"
if ! xcodebuild -project ClaudeCodeLex.xcodeproj -scheme ClaudeCodeLex \
        -configuration Debug \
        -destination "platform=iOS Simulator,id=$UDID" \
        -derivedDataPath build/dd \
        -sdk iphonesimulator build CODE_SIGNING_ALLOWED=NO \
        >"$BUILD_LOG" 2>&1; then
    echo "✗ build failed:"; tail -30 "$BUILD_LOG"; exit 1
fi
APP=$(find build/dd/Build/Products -name "ClaudeCodeLex.app" -type d | head -1)
[ -z "${APP:-}" ] && { echo "✗ build product not found"; exit 1; }
echo "build  : $APP"

# --- install + clean status bar -----------------------------------------
xcrun simctl install "$UDID" "$APP"
xcrun simctl status_bar "$UDID" override \
    --time "9:41" --batteryState charged --batteryLevel 100 \
    --cellularBars 4 --wifiBars 3 2>/dev/null || true

# --- capture loop -------------------------------------------------------
# $1 set name | $2 AppleLanguages value | $3 AppleLocale value
shoot() {
    local set="$1" lang="$2" locale="$3"
    echo "shoot  : $set set"
    for screen in "${SCREENS[@]}"; do
        xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
        xcrun simctl launch "$UDID" "$BUNDLE_ID" \
            -screenshotScreen "$screen" -screenshotSet "$set" \
            -AppleLanguages "($lang)" -AppleLocale "$locale" >/dev/null
        sleep 3
        xcrun simctl io "$UDID" screenshot "$OUT_DIR/${set}_${screen}.png" >/dev/null 2>&1
        echo "         ✓ ${set}_${screen}.png"
    done
}

shoot "en"    "en"      "en_US"
shoot "zh-TW" "zh-Hant" "zh_TW"

xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl status_bar "$UDID" clear 2>/dev/null || true

echo "done   : $(ls -1 "$OUT_DIR" | wc -l | tr -d ' ') PNGs → $OUT_DIR"
