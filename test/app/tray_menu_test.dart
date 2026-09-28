import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/app/tray_menu.dart';
import 'package:singbox_client/tunnel/tunnel_controller.dart';

void main() {
  group('trayIconAssetKeyFor', () {
    test('connected -> залитая плитка', () {
      expect(trayIconAssetKeyFor(TunnelStatus.connected),
          'assets/tray/tray_connected.png');
    });
    test('connecting -> пунктирная плитка', () {
      expect(trayIconAssetKeyFor(TunnelStatus.connecting),
          'assets/tray/tray_connecting.png');
    });
    test('disconnected -> пустая плитка', () {
      expect(trayIconAssetKeyFor(TunnelStatus.disconnected),
          'assets/tray/tray_disconnected.png');
    });
    test('error -> пустая плитка (как disconnected)', () {
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
}
