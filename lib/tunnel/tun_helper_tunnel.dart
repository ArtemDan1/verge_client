import 'dart:convert';
import 'package:flutter/services.dart';
import 'tunnel_controller.dart';

/// Туннель TUN-режима. Говорит с нативным TunChannel, который проксирует
/// запросы привилегированному helper-демону по XPC.
class TunHelperTunnel extends TunnelController {
  static const _channel = MethodChannel('singbox/tun');
  static const _events = EventChannel('singbox/tun/events');

  TunHelperTunnel() {
    _events.receiveBroadcastStream().listen((e) {
      final map = Map<String, dynamic>.from(e as Map);
      if (map['type'] == 'log') emitLog(map['line'] as String);
      if (map['type'] == 'status') {
        emit(TunnelStatus.values.byName(map['value'] as String));
      }
    }, onError: (_) {});
  }

  @override
  Future<void> start(Map<String, dynamic> config,
      {required int port, required String service}) async {
    emit(TunnelStatus.connecting);
    try {
      await _channel.invokeMethod(
          'start', {'config': jsonEncode(config), 'service': service});
      emit(TunnelStatus.connected);
    } on PlatformException catch (e) {
      emitLog('tun start failed: ${e.message}');
      emit(TunnelStatus.error);
    }
  }

  @override
  Future<void> stop() async {
    await _channel.invokeMethod('stop');
    emit(TunnelStatus.disconnected);
  }
}
