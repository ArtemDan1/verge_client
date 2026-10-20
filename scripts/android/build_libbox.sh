#!/usr/bin/env bash
# Собирает sing-box как Android-библиотеку: android/app/libs/libbox.aar.
#
# Нужны Go (версия из go.mod sing-box), JDK 17+, Android SDK и NDK
# (ANDROID_HOME и ANDROID_NDK_HOME). Сборка всех ABI занимает 10–20 минут,
# поэтому в CI результат кешируется по версии sing-box и хешу этого скрипта.
#
# Версия sing-box обязана совпадать с десктопной (windows/runner/resources,
# macos/Runner/Resources): конфиг собирает общий Dart-код.
set -euo pipefail

SINGBOX_VERSION="${SINGBOX_VERSION:-v1.14.1}"
# Те же ABI, что у APK. 386 не собираем: таких устройств практически нет.
TARGETS="${TARGETS:-android/arm64,android/arm,android/amd64}"

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/android/app/libs/libbox.aar"
WORK="${WORK_DIR:-$ROOT/build/libbox}"

: "${ANDROID_HOME:?нужен ANDROID_HOME}"
: "${ANDROID_NDK_HOME:?нужен ANDROID_NDK_HOME}"

mkdir -p "$WORK" "$(dirname "$OUT")"
if [ ! -d "$WORK/sing-box/.git" ]; then
  git clone --depth 1 --branch "$SINGBOX_VERSION" \
    https://github.com/SagerNet/sing-box "$WORK/sing-box"
fi
cd "$WORK/sing-box"

# gomobile той же версии, что прописана в go.mod sing-box: бинарь и пакет
# bind, который он подтягивает из модуля, должны совпадать.
GOMOBILE_VERSION="$(go list -m -f '{{.Version}}' github.com/sagernet/gomobile)"
go install "github.com/sagernet/gomobile/cmd/gomobile@$GOMOBILE_VERSION"
go install "github.com/sagernet/gomobile/cmd/gobind@$GOMOBILE_VERSION"
export PATH="$(go env GOPATH)/bin:$PATH"

# Набор тегов — как в официальном cmd/internal/build_libbox, но без
# Tailscale, USB/IP, OpenVPN и OpenConnect: Verge их не использует, а каждый
# добавляет мегабайты в APK. naive (cronet) оставлен — он нужен нодам naive.
TAGS="with_gvisor,with_quic,with_wireguard,with_utls,with_naive_outbound,with_clash_api,badlinkname,tfogo_checklinkname0"
LDFLAGS="-X github.com/sagernet/sing-box/constant.Version=${SINGBOX_VERSION#v} -X runtime.godebugDefault=multipathtcp=0,tlssha1=1 -checklinkname=0 -s -w -buildid="

gomobile bind -v \
  -o "$OUT" \
  -target "$TARGETS" \
  -androidapi 24 \
  -javapkg=io.nekohasekai \
  -libname=box \
  -trimpath -buildvcs=false \
  -ldflags "$LDFLAGS" \
  -tags "$TAGS" \
  ./experimental/libbox

ls -la "$OUT"
