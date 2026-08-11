import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:singbox_client/app/tray_menu.dart';
import 'package:singbox_client/tunnel/tunnel_controller.dart';

void main() {
  group('trayIconAssetKeyFor', () {
    test('connected -> зелёная иконка', () {
      expect(trayIconAssetKeyFor(TunnelStatus.connected),
          'assets/tray/tray_connected.png');
    });
    test('connecting -> жёлтая иконка', () {
      expect(trayIconAssetKeyFor(TunnelStatus.connecting),
          'assets/tray/tray_connecting.png');
    });
    test('disconnected -> серая иконка', () {
      expect(trayIconAssetKeyFor(TunnelStatus.disconnected),
          'assets/tray/tray_disconnected.png');
    });
    test('error -> серая иконка (как disconnected)', () {
      expect(trayIconAssetKeyFor(TunnelStatus.error),
          'assets/tray/tray_disconnected.png');
    });

    test('на Windows отдаёт .ico: PNG там LoadImage не читает', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      expect(trayIconAssetKeyFor(TunnelStatus.connected),
          'assets/tray/tray_connected.ico');
      expect(trayIconAssetKeyFor(TunnelStatus.error),
          'assets/tray/tray_disconnected.ico');
    });
  });

  group('buildTrayMenu', () {
    Menu build(TunnelStatus status) => buildTrayMenu(
          status: status,
          onToggleConnection: () {},
          onShowWindow: () {},
          onQuit: () {},
        );

    test('disconnected: пункт подключения — «Подключиться», не задизейблен',
        () {
      final menu = build(TunnelStatus.disconnected);
      final toggle = menu.items!.firstWhere((i) => i.key == 'toggle_connection');
      expect(toggle.label, 'Подключиться');
      expect(toggle.disabled, isFalse);
    });

    test('connected: пункт подключения — «Отключиться», не задизейблен', () {
      final menu = build(TunnelStatus.connected);
      final toggle = menu.items!.firstWhere((i) => i.key == 'toggle_connection');
      expect(toggle.label, 'Отключиться');
      expect(toggle.disabled, isFalse);
    });

    test('connecting: пункт подключения задизейблен', () {
      final menu = build(TunnelStatus.connecting);
      final toggle = menu.items!.firstWhere((i) => i.key == 'toggle_connection');
      expect(toggle.disabled, isTrue);
    });

    test('содержит «Открыть», разделитель и «Закрыть» в этом порядке', () {
      final menu = build(TunnelStatus.disconnected);
      final keys = menu.items!.map((i) => i.key).toList();
      expect(keys, ['toggle_connection', 'show_window', null, 'quit']);
      final showWindow = menu.items!.firstWhere((i) => i.key == 'show_window');
      expect(showWindow.label, 'Открыть');
      final quit = menu.items!.firstWhere((i) => i.key == 'quit');
      expect(quit.label, 'Закрыть');
    });

    test('клик по «Подключиться» вызывает onToggleConnection', () {
      var calls = 0;
      final menu = buildTrayMenu(
        status: TunnelStatus.disconnected,
        onToggleConnection: () => calls++,
        onShowWindow: () {},
        onQuit: () {},
      );
      final toggle = menu.items!.firstWhere((i) => i.key == 'toggle_connection');
      toggle.onClick!(toggle);
      expect(calls, 1);
    });

    test('клик по «Открыть» вызывает onShowWindow', () {
      var calls = 0;
      final menu = buildTrayMenu(
        status: TunnelStatus.disconnected,
        onToggleConnection: () {},
        onShowWindow: () => calls++,
        onQuit: () {},
      );
      final item = menu.items!.firstWhere((i) => i.key == 'show_window');
      item.onClick!(item);
      expect(calls, 1);
    });

    test('клик по «Закрыть» вызывает onQuit', () {
      var calls = 0;
      final menu = buildTrayMenu(
        status: TunnelStatus.disconnected,
        onToggleConnection: () {},
        onShowWindow: () {},
        onQuit: () => calls++,
      );
      final item = menu.items!.firstWhere((i) => i.key == 'quit');
      item.onClick!(item);
      expect(calls, 1);
    });
  });
}
