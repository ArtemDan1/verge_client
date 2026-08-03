#!/bin/bash
# Собирает продуктовый .pkg из готовой release-сборки: app в /Applications +
# helper-демон в /Library. Запускать после scripts/build_release.sh.
set -euo pipefail

cd "$(dirname "$0")/.."

# Стрипает extended attributes (quarantine/provenance и пр.) со staging-папки:
# иначе pkgbuild кодирует их как AppleDouble (._*) в payload. Подпись бандла
# хранится в _CodeSignature/ и в Mach-O, не в xattr, — её это не трогает.
strip_appledouble() { xattr -rc "$1"; }

VERSION="$(grep '^version:' pubspec.yaml | sed 's/version: //; s/+.*//')"
APP="build/macos/Build/Products/Release/Verge.app"
HELPER="build/macos/Build/Products/Release/com.singboxclient.helper"
WORK="$(mktemp -d)"
OUT="dist"
mkdir -p "$OUT"

# Оба движка обязаны быть в бандле: sing-box владеет туннелем, xray поднимается
# для hysteria2 и vless+xhttp. Проверяем здесь, иначе отсутствие вылезет только
# при подключении к ноде у пользователя.
for BIN in sing-box xray; do
  if [ ! -x "$APP/Contents/Resources/$BIN" ]; then
    echo "ERROR: в бандле нет исполняемого $BIN — прогони scripts/build_release.sh" >&2
    exit 1
  fi
done

# --- Компонент 1: приложение в /Applications ---
APP_ROOT="$WORK/app_root/Applications"
mkdir -p "$APP_ROOT"
cp -R "$APP" "$APP_ROOT/"
strip_appledouble "$WORK/app_root"

# pkgbuild по умолчанию делает app-бандл relocatable: инсталлятор ставит его НЕ в
# /Applications, а в существующую копию bundle id (которую находит LaunchServices,
# напр. dev-сборку в build/). Отключаем relocation через component-plist, чтобы
# app всегда ставился в /Applications.
pkgbuild --analyze --root "$WORK/app_root" "$WORK/app-component.plist"
perl -0pi -e 's{(<key>BundleIsRelocatable</key>\s*)<true/>}{${1}<false/>}g' \
  "$WORK/app-component.plist"
pkgbuild --root "$WORK/app_root" \
  --component-plist "$WORK/app-component.plist" \
  --identifier com.singboxclient.app \
  --version "$VERSION" \
  --install-location / \
  "$WORK/app.pkg"

# --- Компонент 2: helper + LaunchDaemon в /Library, postinstall грузит демона ---
H_ROOT="$WORK/helper_root"
mkdir -p "$H_ROOT/Library/PrivilegedHelperTools" "$H_ROOT/Library/LaunchDaemons"
cp "$HELPER" "$H_ROOT/Library/PrivilegedHelperTools/com.singboxclient.helper"
cp packaging/com.singboxclient.helper.daemon.plist \
  "$H_ROOT/Library/LaunchDaemons/com.singboxclient.helper.plist"
strip_appledouble "$H_ROOT"
pkgbuild --root "$H_ROOT" \
  --identifier com.singboxclient.helper \
  --version "$VERSION" \
  --scripts packaging/scripts \
  --install-location / \
  "$WORK/helper.pkg"

# --- Продуктовый pkg из двух компонентов ---
cat > "$WORK/distribution.xml" <<XML
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="1">
  <title>Verge</title>
  <options customize="never" require-scripts="false"/>
  <!-- Installer сам потребует закрыть запущенную копию: перезапись бандла под
       живым процессом даёт SIGKILL по невалидной подписи, а bootout демона в
       postinstall рвёт активный туннель. -->
  <pkg-ref id="com.singboxclient.app">
    <must-close>
      <app id="com.singboxclient.singboxFlutter"/>
    </must-close>
  </pkg-ref>
  <pkg-ref id="com.singboxclient.helper"/>
  <choices-outline>
    <line choice="default">
      <line choice="com.singboxclient.app"/>
      <line choice="com.singboxclient.helper"/>
    </line>
  </choices-outline>
  <choice id="default"/>
  <choice id="com.singboxclient.app" visible="false">
    <pkg-ref id="com.singboxclient.app"/>
  </choice>
  <choice id="com.singboxclient.helper" visible="false">
    <pkg-ref id="com.singboxclient.helper"/>
  </choice>
  <pkg-ref id="com.singboxclient.app" version="$VERSION">app.pkg</pkg-ref>
  <pkg-ref id="com.singboxclient.helper" version="$VERSION">helper.pkg</pkg-ref>
</installer-gui-script>
XML

productbuild --distribution "$WORK/distribution.xml" \
  --package-path "$WORK" \
  "$OUT/Verge-$VERSION.pkg"

rm -rf "$WORK"
echo "==> готово: $OUT/Verge-$VERSION.pkg"
