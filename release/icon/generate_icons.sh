#!/bin/bash
# Generates every Android + iOS launcher icon size PlayTap needs from a
# single master PNG, using macOS's built-in `sips` (no new pub dependency
# — see docs/DATA_MODEL.md "Résolution drift_dev" for why this repo keeps
# its pinned dependency set as small as possible).
#
# Usage:
#   1. Drop the master icon at release/icon/source/icon-1024.png
#      — square, at least 1024x1024, PNG.
#   2. Run: bash release/icon/generate_icons.sh
#   3. Rebuild: cd mobile && flutter build appbundle --release
#      (and flutter build apk --release for device QA)
#
# This script only overwrites existing icon files at their existing
# paths/filenames — it does not touch AndroidManifest.xml, Info.plist, or
# any Contents.json, since the current filenames/sizes already match
# what Flutter's default template (still in place) expects.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE="$ROOT_DIR/release/icon/source/icon-1024.png"
MOBILE_DIR="$ROOT_DIR/mobile"

if [ ! -f "$SOURCE" ]; then
  echo "error: master icon not found at $SOURCE" >&2
  echo "Drop a square PNG (>= 1024x1024) there first." >&2
  exit 1
fi

WIDTH=$(sips -g pixelWidth "$SOURCE" | awk '/pixelWidth/ {print $2}')
HEIGHT=$(sips -g pixelHeight "$SOURCE" | awk '/pixelHeight/ {print $2}')
if [ "$WIDTH" != "$HEIGHT" ]; then
  echo "error: master icon must be square (got ${WIDTH}x${HEIGHT})" >&2
  exit 1
fi
if [ "$WIDTH" -lt 1024 ]; then
  echo "error: master icon must be at least 1024x1024 (got ${WIDTH}x${HEIGHT})" >&2
  exit 1
fi

resize() {
  local size="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  sips -z "$size" "$size" "$SOURCE" --out "$dest" >/dev/null
  echo "  $dest (${size}x${size})"
}

echo "Android launcher icon (legacy, 5 densities):"
resize 48  "$MOBILE_DIR/android/app/src/main/res/mipmap-mdpi/ic_launcher.png"
resize 72  "$MOBILE_DIR/android/app/src/main/res/mipmap-hdpi/ic_launcher.png"
resize 96  "$MOBILE_DIR/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png"
resize 144 "$MOBILE_DIR/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png"
resize 192 "$MOBILE_DIR/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"

echo "iOS AppIcon.appiconset (matches existing Contents.json exactly):"
ICONSET="$MOBILE_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset"
resize 20   "$ICONSET/Icon-App-20x20@1x.png"
resize 40   "$ICONSET/Icon-App-20x20@2x.png"
resize 60   "$ICONSET/Icon-App-20x20@3x.png"
resize 29   "$ICONSET/Icon-App-29x29@1x.png"
resize 58   "$ICONSET/Icon-App-29x29@2x.png"
resize 87   "$ICONSET/Icon-App-29x29@3x.png"
resize 40   "$ICONSET/Icon-App-40x40@1x.png"
resize 80   "$ICONSET/Icon-App-40x40@2x.png"
resize 120  "$ICONSET/Icon-App-40x40@3x.png"
resize 120  "$ICONSET/Icon-App-60x60@2x.png"
resize 180  "$ICONSET/Icon-App-60x60@3x.png"
resize 76   "$ICONSET/Icon-App-76x76@1x.png"
resize 152  "$ICONSET/Icon-App-76x76@2x.png"
resize 167  "$ICONSET/Icon-App-83.5x83.5@2x.png"
resize 1024 "$ICONSET/Icon-App-1024x1024@1x.png"

echo "Play Store listing hi-res icon (store asset, not part of the app itself):"
resize 512 "$ROOT_DIR/release/store/assets/play-store-icon-512.png"

echo
echo "Done. Note: legacy Android launcher icons with transparency can look"
echo "wrong on some home-screen launchers — if the master PNG has an alpha"
echo "channel, flatten it onto an opaque background before running this,"
echo "or add a proper adaptive icon (foreground+background) separately."
echo
echo "Next: cd mobile && flutter build appbundle --release && flutter build apk --release"
