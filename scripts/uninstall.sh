#!/bin/bash
# Полностью удаляет приложение и helper-демон для теста установки "с нуля".
# Требует sudo для системных путей. Идемпотентен (ошибки отсутствия игнорируются).
set -u

echo "==> bootout helper-демона"
sudo launchctl bootout system/com.singboxclient.helper 2>/dev/null || true

echo "==> удаление системных файлов helper'а"
sudo rm -f /Library/LaunchDaemons/com.singboxclient.helper.plist
sudo rm -f /Library/PrivilegedHelperTools/com.singboxclient.helper

echo "==> удаление приложения"
sudo rm -rf /Applications/Verge.app

echo "==> удаление пользовательских данных"
rm -rf "$HOME/Library/Application Support/com.singboxclient.singboxFlutter"
rm -rf "$HOME/Library/Caches/com.singboxclient.singboxFlutter"
rm -f  "$HOME/Library/Preferences/com.singboxclient.singboxFlutter.plist"

echo "==> забыть pkg-ресиверы"
sudo pkgutil --forget com.singboxclient.app 2>/dev/null || true
sudo pkgutil --forget com.singboxclient.helper 2>/dev/null || true

echo "==> готово. (Если ранее регистрировался SMAppService — его запись в"
echo "    System Settings > Login Items исчезает после удаления .app; при"
echo "    необходимости перелогиньтесь.)"
