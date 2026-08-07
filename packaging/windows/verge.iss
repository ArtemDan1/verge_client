; Инсталлятор Verge для Windows — аналог .pkg на macOS.
;
; Версия приходит снаружи: iscc /DAppVersion=1.2.3. Единственный источник —
; поле version в pubspec.yaml, см. scripts/make_installer.ps1.
#ifndef AppVersion
  #error AppVersion не задан: собирайте через scripts/make_installer.ps1
#endif

#define AppName "Verge"
#define AppExeName "singbox_flutter.exe"
#define AppPublisher "Verge"

[Setup]
AppId={{8F3C1D4E-6B2A-4F19-9E77-5C0A1B2D3E4F}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
; Ставим для всех пользователей: TUN-служба этапа 3 иначе не встанет.
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#SourcePath}\..\..\dist
OutputBaseFilename=Verge-{#AppVersion}-setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
; Обновление поверх запущенной копии: приложение само себя закрывает перед
; запуском инсталлятора (installUpdate в tunnel_channel.cpp), но подстрахуемся.
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Code]
// Служба держит свой exe открытым: без остановки установка новой версии
// поверх старой падает на «файл занят другим процессом».
function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  ResultCode: Integer;
begin
  Result := '';
  Exec(ExpandConstant('{sys}\sc.exe'), 'stop VergeTunnel', '',
       SW_HIDE, ewWaitUntilTerminated, ResultCode);
  // Дать службе догаснуть: sc.exe возвращается сразу, не дожидаясь остановки.
  Sleep(2000);
end;

[Files]
Source: "{#SourcePath}\..\..\build\windows\x64\runner\Release\*"; \
  DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; \
  Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Создать ярлык на рабочем столе"; \
  GroupDescription: "Дополнительно:"

[Registry]
; Схема verge:// — импорт подписки одним кликом из браузера. На macOS её
; объявляет Info.plist, здесь регистрируем руками.
Root: HKLM; Subkey: "Software\Classes\verge"; ValueType: string; \
  ValueName: ""; ValueData: "URL:Verge Protocol"; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\Classes\verge"; ValueType: string; \
  ValueName: "URL Protocol"; ValueData: ""
Root: HKLM; Subkey: "Software\Classes\verge\DefaultIcon"; ValueType: string; \
  ValueName: ""; ValueData: "{app}\{#AppExeName},0"
Root: HKLM; Subkey: "Software\Classes\verge\shell\open\command"; \
  ValueType: string; ValueName: ""; \
  ValueData: """{app}\{#AppExeName}"" ""%1"""

[Run]
; Служба создаётся с автозапуском: приложение стартует без прав администратора
; и поднять её само не сможет.
Filename: "{sys}\sc.exe"; \
  Parameters: "create VergeTunnel binPath= ""{app}\verge_service.exe"" start= auto DisplayName= ""Verge Tunnel"""; \
  Flags: runhidden
Filename: "{sys}\sc.exe"; \
  Parameters: "description VergeTunnel ""Привилегированная часть Verge: поднимает TUN-туннель"""; \
  Flags: runhidden
Filename: "{sys}\sc.exe"; Parameters: "start VergeTunnel"; Flags: runhidden

Filename: "{app}\{#AppExeName}"; Description: "Запустить {#AppName}"; \
  Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{sys}\sc.exe"; Parameters: "stop VergeTunnel"; Flags: runhidden; \
  RunOnceId: "StopService"
Filename: "{sys}\sc.exe"; Parameters: "delete VergeTunnel"; Flags: runhidden; \
  RunOnceId: "DeleteService"

[UninstallDelete]
; Подчищаем каталог целиком: sing-box пишет рядом с собой временные файлы,
; которых инсталлятор не ставил и сам бы не удалил.
;
; Настройки, подписки и geo-ассеты живут не здесь, а в %APPDATA% (main.dart
; берёт getApplicationSupportDirectory) и удаление их НЕ трогает — переустановка
; сохраняет состояние пользователя.
Type: filesandordirs; Name: "{app}"
