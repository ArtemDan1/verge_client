#!/bin/bash
# Ставит собранный .pkg и проверяет, что helper-демон загружен в launchd.
set -euo pipefail

cd "$(dirname "$0")/.."
VERSION="$(grep '^version:' pubspec.yaml | sed 's/version: //; s/+.*//')"
PKG="dist/Verge-$VERSION.pkg"

echo "==> установка $PKG"
sudo installer -pkg "$PKG" -target /

echo "==> проверка демона"
if launchctl print system/com.singboxclient.helper >/dev/null 2>&1; then
  echo "OK: демон com.singboxclient.helper загружен"
else
  echo "FAIL: демон не загружен" >&2
  exit 1
fi

echo "==> приложение установлено: $(ls -d /Applications/Verge.app)"
