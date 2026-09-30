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
; После установки просим Проводник перечитать значки: путь к exe при
; обновлении тот же, и без этого ярлык показывает старую иконку из кэша.
; Заодно подхватывается свежезарегистрированная схема verge://.
ChangesAssociations=yes

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Code]
// Microsoft Visual C++ Redistributable 2015–2022 (x64). Без него приложение и
// служба не стартуют на чистой Windows: нет vcruntime140.dll / msvcp140.dll.
// Ставим только если рантайма нет или он старый; сам редистрибутив в
// инсталлятор не кладём (+25 МБ), а скачиваем с постоянного адреса Microsoft.
const
  VCRedistUrl = 'https://aka.ms/vs/17/release/vc_redist.x64.exe';
  VCRedistFile = 'vc_redist.x64.exe';
  // Сборка идёт MSVC из VS 2022 17.10+, а такие бинарники падают на рантайме
  // старше 14.40 (изменился std::mutex) — старый рантайм тоже обновляем.
  VCRedistMinMinor = 40;

var
  DownloadPage: TDownloadWizardPage;
  VCRedistRestart: Boolean;
  // Загрузку уже пробовали со страницей прогресса — второй раз не качаем.
  VCRedistDownloadTried: Boolean;

function VCRedistInView(RootKey: Integer): Boolean;
var
  Key: String;
  Installed, Major, Minor: Cardinal;
begin
  Key := 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64';
  Result := RegQueryDWordValue(RootKey, Key, 'Installed', Installed) and
            (Installed = 1) and
            RegQueryDWordValue(RootKey, Key, 'Major', Major) and
            RegQueryDWordValue(RootKey, Key, 'Minor', Minor) and
            ((Major > 14) or ((Major = 14) and (Minor >= VCRedistMinMinor)));
end;

// Редистрибутив — 32-битный bootstrapper и пишет ключ в WOW6432Node, но
// смотрим оба представления реестра, чтобы не зависеть от этого.
function VCRedistInstalled: Boolean;
begin
  Result := VCRedistInView(HKLM32) or VCRedistInView(HKLM64);
end;

procedure InitializeWizard;
begin
  DownloadPage := CreateDownloadPage(
    'Загрузка компонентов',
    'Скачивается Microsoft Visual C++ Redistributable, он нужен для работы Verge.',
    nil);
end;

// В интерактивной установке качаем на шаге «Готово к установке» со страницей
// прогресса. Если сети нет — даём повторить или продолжить без рантайма.
function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if (CurPageID <> wpReady) or VCRedistInstalled then Exit;
  VCRedistDownloadTried := True;
  DownloadPage.Clear;
  DownloadPage.Add(VCRedistUrl, VCRedistFile, '');
  DownloadPage.Show;
  try
    try
      DownloadPage.Download;
    except
      Log('VC++ Redistributable: загрузка не удалась: ' + GetExceptionMessage);
      if not DownloadPage.AbortedByUser then
        Result := SuppressibleMsgBox(
          'Не удалось скачать Microsoft Visual C++ Redistributable:' + #13#10 +
          GetExceptionMessage + #13#10#13#10 +
          'Продолжить установку без него? Если на компьютере его нет, Verge ' +
          'не запустится — тогда установите его вручную:' + #13#10 +
          VCRedistUrl + #13#10#13#10 +
          'Нажмите «Нет», чтобы попробовать ещё раз.',
          mbError, MB_YESNO, IDYES) = IDYES
      else
        Result := False;
    end;
  finally
    DownloadPage.Hide;
  end;
end;

procedure InstallVCRedist;
var
  Path: String;
  ResultCode: Integer;
begin
  if VCRedistInstalled then Exit;
  Path := ExpandConstant('{tmp}\' + VCRedistFile);
  // Запасной путь, если страница загрузки не отработала (например, её
  // пропустили) — качаем здесь же без UI.
  if not FileExists(Path) then
  begin
    if VCRedistDownloadTried then Exit;
    try
      DownloadTemporaryFile(VCRedistUrl, VCRedistFile, '', nil);
    except
      Log('VC++ Redistributable: загрузка не удалась: ' + GetExceptionMessage);
      Exit;
    end;
  end;
  WizardForm.StatusLabel.Caption :=
    'Установка Microsoft Visual C++ Redistributable...';
  if not Exec(Path, '/install /quiet /norestart', '', SW_HIDE,
              ewWaitUntilTerminated, ResultCode) then
  begin
    Log('VC++ Redistributable: не удалось запустить: ' +
        SysErrorMessage(ResultCode));
    Exit;
  end;
  // 1638 — уже стоит более новая версия, 3010 — нужна перезагрузка.
  if ResultCode = 3010 then
    VCRedistRestart := True
  else if (ResultCode <> 0) and (ResultCode <> 1638) then
    Log('VC++ Redistributable: код завершения ' + IntToStr(ResultCode));
end;

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

// Рантайм ставим до копирования файлов: к [Run] со стартом службы и запуском
// приложения он уже должен быть на месте.
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then InstallVCRedist;
end;

function NeedRestart: Boolean;
begin
  Result := VCRedistRestart;
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
; Автоперезапуск при сбое: без службы TUN-режим недоступен целиком, и
; единичное падение не должно требовать переустановки. Счётчик сбоев
; сбрасывается раз в сутки.
Filename: "{sys}\sc.exe"; \
  Parameters: "failure VergeTunnel reset= 86400 actions= restart/5000/restart/5000/restart/5000"; \
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
