#!/bin/bash
# Сборка неподписанного .ipa для Sideloadly (запускать на Mac ИЛИ через GitHub Actions).
# Использование: ./Scripts/build-ipa.sh
set -e
cd "$(dirname "$0")/.."
APP="NovaTun"
SCHEME="NovaTun"
OUT="build"
IPA="$OUT/NovaTun-sideloadly.ipa"
XRAY_VERSION="26.9.9"
rm -rf "$OUT" && mkdir -p "$OUT"

# 1. XrayMobile.xcframework (gomobile bind) — ядро Xray для PacketTunnel.
if [ ! -d "NovaTun/Frameworks/XrayMobile.xcframework" ]; then
  echo "==> сборка XrayMobile.xcframework (Xray-core v$XRAY_VERSION)…"
  command -v go >/dev/null || { echo "ОШИБКА: нужен Go (brew install go)"; exit 1; }
  go install golang.org/x/mobile/cmd/gomobile@latest
  export PATH="$PATH:$(go env GOPATH)/bin"
  gomobile init
  # gomobile bind требует bind-пакет внутри main-модуля Xray-core:
  # копируем наш wrapper в свежий клон Xray-core нужной версии.
  TMPXRAY="$(mktemp -d)/xray"
  git clone --depth 1 --branch "v$XRAY_VERSION" https://github.com/XTLS/Xray-core.git "$TMPXRAY"
  cp -R xray-mobile/mobile "$TMPXRAY/mobile"
  mkdir -p NovaTun/Frameworks
  FW_ABS="$(pwd)/NovaTun/Frameworks/XrayMobile.xcframework"
  ( cd "$TMPXRAY" && go get golang.org/x/mobile@latest && go mod tidy \
    && gomobile bind -v -target=ios -o "$FW_ABS" ./mobile )
fi

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
