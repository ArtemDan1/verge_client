#!/bin/bash
# Собирает release-сборку Flutter macOS и ad-hoc подписывает app, helper и
# оба движка (sing-box и xray).
# Ad-hoc (codesign -s -) не требует аккаунта и даёт стабильную подпись для XPC/launchd.
set -euo pipefail

cd "$(dirname "$0")/.."

APP="build/macos/Build/Products/Release/Verge.app"
HELPER="build/macos/Build/Products/Release/com.singboxclient.helper"

echo "==> flutter build macos --release"
flutter build macos --release

# xray бандлится наравне с sing-box: он запускается для hysteria2 и vless+xhttp.
for BIN in sing-box xray; do
  echo "==> ad-hoc sign $BIN"
  if [ -f "$APP/Contents/Resources/$BIN" ]; then
    codesign --force --sign - "$APP/Contents/Resources/$BIN"
  else
    echo "ERROR: $BIN не попал в бандл ($APP/Contents/Resources/$BIN)" >&2
    exit 1
  fi
done

echo "==> ad-hoc sign helper"
if [ -f "$HELPER" ]; then
  codesign --force --sign - "$HELPER"
else
  echo "WARN: helper-бинарь не найден по $HELPER — проверь, что таргет собрался" >&2
fi

echo "==> ad-hoc sign app (глубоко)"
codesign --force --deep --sign - "$APP"

echo "==> готово: $APP"
