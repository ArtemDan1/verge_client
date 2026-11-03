#!/bin/bash
# Ставит версию приложения = дата релиза ГГГГ.М.Д (без ведущих нулей: Flutter,
# macOS и Windows принимают только три числа, «2026.03.07» не пройдёт).
#   scripts/set_version.sh              — сегодняшняя дата
#   scripts/set_version.sh 2026-11-03   — конкретная дата
# Тег релиза на GitHub — v<версия>: по нему клиенты находят обновление.
set -euo pipefail

cd "$(dirname "$0")/.."

if [ $# -gt 0 ]; then
  IFS=- read -r Y M D <<< "$1"
else
  Y=$(date +%Y); M=$(date +%m); D=$(date +%d)
fi
VERSION="$((10#$Y)).$((10#$M)).$((10#$D))"

CURRENT="$(grep '^version:' pubspec.yaml | sed 's/version: //; s/+.*//')"
if [ "$CURRENT" = "$VERSION" ]; then
  echo "Версия уже $VERSION. Второй релиз за день номер не различит —" >&2
  echo "клиенты его не увидят. Выпускай следующим днём или передай дату явно." >&2
  exit 1
fi

sed -i '' "s/^version: .*/version: $VERSION/" pubspec.yaml
echo "$CURRENT → $VERSION"
