# Собирает инсталлятор Windows. Версию берёт из pubspec.yaml — дублировать её
# в .iss или в workflow нельзя, иначе рано или поздно разъедутся.
#
# Запуск: pwsh scripts/make_installer.ps1
# Требует: собранный build\windows\x64\runner\Release и iscc в PATH.
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$pubspec = Join-Path $root 'pubspec.yaml'

$versionLine = Select-String -Path $pubspec -Pattern '^version:\s*(.+)$' |
  Select-Object -First 1
if (-not $versionLine) {
  throw "Не нашёл поле version в $pubspec"
}
# "1.2.3+4" → "1.2.3": build-номер в имя инсталлятора не идёт, как и в .pkg.
$version = $versionLine.Matches[0].Groups[1].Value.Trim().Split('+')[0]

$release = Join-Path $root 'build\windows\x64\runner\Release'
if (-not (Test-Path (Join-Path $release 'sing-box.exe'))) {
  throw "Нет $release\sing-box.exe — сначала flutter build windows --release"
}

$iss = Join-Path $root 'packaging\windows\verge.iss'
& iscc "/DAppVersion=$version" $iss
if ($LASTEXITCODE -ne 0) { throw "iscc завершился с кодом $LASTEXITCODE" }

$out = Join-Path $root "dist\Verge-$version-setup.exe"
if (-not (Test-Path $out)) { throw "Инсталлятор не появился: $out" }
Write-Host $out
