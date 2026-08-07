import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import '../tunnel/tunnel_controller.dart';

/// Ключ Flutter-ассета для иконки трея.
///
/// Расширение зависит от платформы. На Windows tray_manager отдаёт путь в
/// LoadImage с флагом IMAGE_ICON, а тот читает только формат .ico: с PNG вызов
/// молча возвращает null, и у пункта в трее не оказывается значка. На macOS
/// setIcon читает ассет через rootBundle и ждёт PNG.
String trayIconAssetKeyFor(TunnelStatus status) {
  final ext = defaultTargetPlatform == TargetPlatform.windows ? 'ico' : 'png';
  final name = switch (status) {
    TunnelStatus.connected => 'tray_connected',
    TunnelStatus.connecting => 'tray_connecting',
    TunnelStatus.disconnected || TunnelStatus.error => 'tray_disconnected',
  };
  return 'assets/tray/$name.$ext';
}

/// Чистая сборка меню трея — без обращения к trayManager, поэтому
/// тестируется напрямую (в отличие от TrayService, который дёргает плагин).
Menu buildTrayMenu({
  required TunnelStatus status,
  required VoidCallback onToggleConnection,
  required VoidCallback onShowWindow,
  required VoidCallback onQuit,
}) {
  final busyOrConnected =
      status == TunnelStatus.connecting || status == TunnelStatus.connected;
  return Menu(items: [
    MenuItem(
      key: 'toggle_connection',
      label: busyOrConnected ? 'Отключиться' : 'Подключиться',
      disabled: status == TunnelStatus.connecting,
      onClick: (_) => onToggleConnection(),
    ),
    MenuItem(
      key: 'show_window',
      label: 'Открыть',
      onClick: (_) => onShowWindow(),
    ),
    MenuItem.separator(),
    MenuItem(
      key: 'quit',
      label: 'Закрыть',
      onClick: (_) => onQuit(),
    ),
  ]);
}
