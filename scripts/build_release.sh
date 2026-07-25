#!/bin/bash
# Собирает release-сборку Flutter macOS и ad-hoc подписывает app, helper и sing-box.
# Ad-hoc (codesign -s -) не требует аккаунта и даёт стабильную подпись для XPC/launchd.
set -euo pipefail

cd "$(dirname "$0")/.."

APP="build/macos/Build/Products/Release/Verge.app"
HELPER="build/macos/Build/Products/Release/com.singboxclient.helper"

echo "==> flutter build macos --release"
flutter build macos --release

echo "==> ad-hoc sign sing-box"
codesign --force --sign - "$APP/Contents/Resources/sing-box"

echo "==> ad-hoc sign helper"
if [ -f "$HELPER" ]; then
  codesign --force --sign - "$HELPER"
else
  echo "WARN: helper-бинарь не найден по $HELPER — проверь, что таргет собрался" >&2
fi

echo "==> ad-hoc sign app (глубоко)"
codesign --force --deep --sign - "$APP"

echo "==> готово: $APP"
