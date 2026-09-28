import 'package:flutter/foundation.dart';
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
