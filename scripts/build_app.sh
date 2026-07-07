#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="TomatoReminder"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

cd "$ROOT_DIR"
swift build -c release

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR/data"
cp ".build/release/$APP_NAME" "$MACOS_DIR/$APP_NAME"
cp "data/qishi_ocr.json" "$RESOURCES_DIR/data/qishi_ocr.json"

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>local.tomato-reminder</string>
  <key>CFBundleName</key>
  <string>Tomato Reminder</string>
  <key>CFBundleDisplayName</key>
  <string>Tomato Reminder</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSCalendarsFullAccessUsageDescription</key>
  <string>用于将你手动选择的任务同步到 Mac 日历，不会写入番茄钟专注记录。</string>
  <key>NSCalendarsUsageDescription</key>
  <string>用于将你手动选择的任务同步到 Mac 日历，不会写入番茄钟专注记录。</string>
</dict>
</plist>
PLIST

echo "$APP_DIR"
