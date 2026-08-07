import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import '../tunnel/tunnel_controller.dart';

/// Ключ Flutter-ассета. На macOS trayManager.setIcon() сам читает его через
/// rootBundle — отдельного файла на диске не нужно.
String trayIconAssetKeyFor(TunnelStatus status) => switch (status) {
      TunnelStatus.connected => 'assets/tray/tray_connected.png',
      TunnelStatus.connecting => 'assets/tray/tray_connecting.png',
      TunnelStatus.disconnected ||
      TunnelStatus.error =>
        'assets/tray/tray_disconnected.png',
    };

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
