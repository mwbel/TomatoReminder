#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_EXECUTABLE="TomatoReminder"
APP_DISPLAY_NAME="不忘"
APP_ICON_FILE="BuwangAppIcon"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_DISPLAY_NAME.app"
LEGACY_APP_DIR="$DIST_DIR/TomatoReminder.app"
INSTALL_DIR="${HOME}/Applications"
INSTALL_APP_DIR="$INSTALL_DIR/$APP_DISPLAY_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

cd "$ROOT_DIR"
swift build -c release

rm -rf "$APP_DIR" "$LEGACY_APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR/data"
cp ".build/release/$APP_EXECUTABLE" "$MACOS_DIR/$APP_EXECUTABLE"
cp "data/qishi_ocr.json" "$RESOURCES_DIR/data/qishi_ocr.json"
cp "assets/$APP_ICON_FILE.icns" "$RESOURCES_DIR/$APP_ICON_FILE.icns"

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_EXECUTABLE</string>
  <key>CFBundleIdentifier</key>
  <string>local.tomato-reminder</string>
  <key>CFBundleName</key>
  <string>$APP_DISPLAY_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_DISPLAY_NAME</string>
  <key>CFBundleIconFile</key>
  <string>$APP_ICON_FILE</string>
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

mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_APP_DIR"
ditto "$APP_DIR" "$INSTALL_APP_DIR"

echo "$APP_DIR"
echo "$INSTALL_APP_DIR"
