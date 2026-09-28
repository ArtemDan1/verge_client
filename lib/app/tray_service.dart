import 'dart:io';
import 'package:tray_manager/tray_manager.dart';
import 'app_controller.dart';
import 'tray_menu.dart';
import 'window_control_channel.dart';
import '../tunnel/tunnel_controller.dart';

/// Иконка и меню в строке меню macOS: статус подключения — формой плитки,
/// клик — то же самое меню (Подключиться/Отключиться, Открыть, Закрыть).
class TrayService with TrayListener {
  TrayService(this._controller, [WindowControlChannel? windowControl])
      : _windowControl = windowControl ?? WindowControlChannel();
  final AppController _controller;
  final WindowControlChannel _windowControl;
  TunnelStatus? _lastRenderedStatus;

  Future<void> init() async {
    trayManager.addListener(this);
    await trayManager.setToolTip('Verge');
    await _render();
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (_controller.status == _lastRenderedStatus) return;
    _render();
  }

  Future<void> _render() async {
    final status = _controller.status;
    _lastRenderedStatus = status;
    // На macOS иконки — монохромные template-образы: система сама
    // перекрашивает их под светлую/тёмную строку меню. На Windows — цветные.
    await trayManager.setIcon(
      trayIconAssetKeyFor(status),
      isTemplate: Platform.isMacOS,
    );
    await trayManager.setContextMenu(buildTrayMenu(
      status: status,
      onToggleConnection: _toggleConnection,
      onShowWindow: _showWindow,
      onQuit: _quit,
    ));
  }

  void _toggleConnection() {
    final busy = _controller.status == TunnelStatus.connected ||
        _controller.status == TunnelStatus.connecting;
    if (busy) {
      _controller.disconnect();
    } else {
      _controller.connect();
    }
  }

  Future<void> _showWindow() => _windowControl.show();

  /// Выход из трея — единственный способ закрыть приложение на Windows
  /// (крестик там прячет окно). Раньше это был голый `exit(0)`, и нативная
  /// часть не успевала прибраться: системный прокси оставался прописанным в
  /// реестре и указывал на убитый вместе с процессом sing-box — интернет
  /// пропадал до следующего запуска Verge. Поэтому сначала штатное отключение,
  /// и только потом выход.
  Future<void> _quit() async {
    try {
      await _controller.disconnect().timeout(const Duration(seconds: 3));
    } catch (_) {
      // Отключиться не вышло — выходим всё равно: держать пользователя в
      // приложении из-за неудачной уборки хуже.
    }
    exit(0);
  }

  @override
  void onTrayIconMouseDown() {
    trayManager.popUpContextMenu();
  }

  void dispose() {
    trayManager.removeListener(this);
    _controller.removeListener(_onControllerChanged);
  }
}
