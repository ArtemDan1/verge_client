import 'dart:io';
import 'package:tray_manager/tray_manager.dart';
import '../tunnel/tunnel_controller.dart';
import '../ui/tray_popover.dart';
import 'app_controller.dart';
import 'tray_menu.dart';
import 'tray_popover_controller.dart';

/// Значок в строке меню / области уведомлений. Статус подключения — формой
/// плитки. Левый клик — мини-окно трея (тумблер, сервер, режим), правый —
/// короткое меню: Открыть Verge · Подключиться/Отключиться · Выйти.
class TrayService with TrayListener {
  TrayService(this._controller, this._popover);
  final AppController _controller;
  final TrayPopoverController _popover;
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

  Future<void> _showWindow() => _popover.openMain();

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
    _popover.toggle(TrayPopover.heightFor(_controller));
  }

  @override
  void onTrayIconRightMouseDown() {
    // Меню и мини-окно вместе не показываем.
    if (_popover.isOpen) _popover.close();
    trayManager.popUpContextMenu();
  }

  void dispose() {
    trayManager.removeListener(this);
    _controller.removeListener(_onControllerChanged);
  }
}
