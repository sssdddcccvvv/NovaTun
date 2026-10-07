#!/bin/bash
# Сборка неподписанного .ipa для Sideloadly (запускать на Mac ИЛИ через GitHub Actions).
# Использование: ./Scripts/build-ipa.sh
set -e
cd "$(dirname "$0")/.."
APP="NovaTun"
SCHEME="NovaTun"
OUT="build"
IPA="$OUT/NovaTun-sideloadly.ipa"
rm -rf "$OUT" && mkdir -p "$OUT"
echo "==> archive (без подписи, для Sideloadly)…"
xcodebuild -project NovaTun.xcodeproj -scheme "$SCHEME" -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$OUT/NovaTun.xcarchive" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" archive
echo "==> упаковка .ipa…"
APP_PATH="$OUT/NovaTun.xcarchive/Products/Applications/$APP.app"
mkdir -p "$OUT/Payload"
cp -R "$APP_PATH" "$OUT/Payload/"
cd "$OUT" && zip -r "NovaTun-sideloadly.ipa" Payload > /dev/null && cd ..
echo "Готово: $IPA"
ls -lh "$IPA"
