import 'dart:convert';
import 'package:flutter/services.dart';
import 'tunnel_controller.dart';

class MacOSProcessTunnel extends TunnelController {
  static const _channel = MethodChannel('singbox/tunnel');
  static const _events = EventChannel('singbox/tunnel/events');

  MacOSProcessTunnel() {
    _events.receiveBroadcastStream().listen((e) {
      final map = Map<String, dynamic>.from(e as Map);
      if (map['type'] == 'log') emitLog(map['line'] as String);
      if (map['type'] == 'status') {
        final status = TunnelStatus.values.byName(map['value'] as String);
        if (status == TunnelStatus.error) {
          lastError = map['message'] as String?;
        }
        emit(status);
      }
    }, onError: (_) {});
  }

  @override
  Future<void> start(Map<String, dynamic> config,
      {required int port, required String service}) async {
    emit(TunnelStatus.connecting);
    try {
      await _channel.invokeMethod('start', {
        'config': jsonEncode(config),
        'port': port,
        'service': service,
      });
      emit(TunnelStatus.connected);
    } on PlatformException catch (e) {
      emitLog('start failed: ${e.message}');
      lastError = e.message;
      emit(TunnelStatus.error);
    }
  }

  @override
  Future<void> stop() async {
    await _channel.invokeMethod('stop');
    emit(TunnelStatus.disconnected);
  }
}
