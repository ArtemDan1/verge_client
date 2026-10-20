#!/usr/bin/env bash
# Кладёт Xray-core для Android в android/app/src/main/jniLibs/<abi>/libxray.so.
#
# Xray запускается отдельным процессом. Android разрешает исполнять файлы
# только из nativeLibraryDir, а туда попадают лишь lib*.so из APK — отсюда имя.
#
# Официальные Android-сборки Xray есть только для arm64 и x86_64. На
# armeabi-v7a Xray нет: ноды, которым он нужен, приложение молча поднимает на
# sing-box (так же, как при любом сбое старта Xray).
set -euo pipefail

XRAY_VERSION="${XRAY_VERSION:-v26.3.27}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
JNI="$ROOT/android/app/src/main/jniLibs"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fetch() {
  local asset="$1" abi="$2"
  local base="https://github.com/XTLS/Xray-core/releases/download/$XRAY_VERSION"
  curl -fsSL --retry 3 -o "$TMP/$asset" "$base/$asset"
  curl -fsSL --retry 3 -o "$TMP/$asset.dgst" "$base/$asset.dgst"
  local want got
  want="$(grep -i '^SHA2-256' "$TMP/$asset.dgst" | awk '{print $NF}')"
  got="$(sha256sum "$TMP/$asset" | awk '{print $1}')"
  if [ -z "$want" ] || [ "$want" != "$got" ]; then
    echo "SHA-256 не совпал для $asset: ждали '$want', получили '$got'" >&2
    exit 1
  fi
  echo "$asset: sha256 $got"
  mkdir -p "$TMP/$abi" "$JNI/$abi"
  unzip -q -o "$TMP/$asset" xray -d "$TMP/$abi"
  install -m 0755 "$TMP/$abi/xray" "$JNI/$abi/libxray.so"
}

fetch "Xray-android-arm64-v8a.zip" "arm64-v8a"
fetch "Xray-android-amd64.zip" "x86_64"
ls -la "$JNI"/*/libxray.so
