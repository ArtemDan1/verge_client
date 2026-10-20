import 'dart:convert';

import 'package:flutter/services.dart';

import 'tunnel_controller.dart';

/// Туннель, который может уже работать к моменту запуска UI.
///
/// На Android VPN живёт в сервисе дольше движка Flutter: смахнули приложение
/// из недавних — интерфейс умер, VPN остался. Новый интерфейс должен
/// подхватить туннель, а не считать себя отключённым.
abstract interface class AttachableTunnel {
  /// Конфиг работающего туннеля или null, если туннель не поднят. Если
  /// поднят, туннель заодно переходит в [TunnelStatus.connected].
  Future<Map<String, dynamic>?> attach();
}

/// VPN на Android: VpnService + sing-box (libbox) в нативной части.
///
/// Тот же канал `singbox/tun`, что у TUN-режима на десктопе, только под ним
/// не helper-демон, а VpnService. Системный диалог разрешения VPN нативная
/// сторона показывает сама, `start` отвечает после реального старта ядра.
class AndroidVpnTunnel extends TunnelController implements AttachableTunnel {
  AndroidVpnTunnel({MethodChannel? channel, EventChannel? events})
      : _channel = channel ?? const MethodChannel('singbox/tun') {
    (events ?? const EventChannel('singbox/tun/events'))
        .receiveBroadcastStream()
        .listen(_onEvent, onError: (_) {});
  }

  final MethodChannel _channel;

  void _onEvent(dynamic e) {
    final map = Map<String, dynamic>.from(e as Map);
    if (map['type'] == 'log') {
      emitLog(map['line'] as String);
      return;
    }
    if (map['type'] != 'status') return;
    final next = TunnelStatus.values.byName(map['value'] as String);
    // Событие и ответ на start/stop несут один и тот же статус. Повтор не
    // нужен: каждый статус перезапускает таймеры контроллера, а ошибка —
    // ещё и показывает уведомление.
    if (next == status) return;
    if (next == TunnelStatus.error) {
      lastError = map['message'] as String?;
    }
    emit(next);
  }

  @override
  Future<void> start(Map<String, dynamic> config,
      {required int port, required String service}) async {
    emit(TunnelStatus.connecting);
    try {
      await _channel.invokeMethod('start', {'config': jsonEncode(config)});
      if (status != TunnelStatus.connected) emit(TunnelStatus.connected);
    } on PlatformException catch (e) {
      emitLog('VPN не запустился: ${e.message}');
      lastError = e.message;
      if (status != TunnelStatus.error) emit(TunnelStatus.error);
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _channel.invokeMethod('stop');
    } on PlatformException catch (e) {
      emitLog('VPN остановлен с ошибкой: ${e.message}');
    }
    if (status != TunnelStatus.disconnected) emit(TunnelStatus.disconnected);
  }

  @override
  Future<Map<String, dynamic>?> attach() async {
    final state = await _channel.invokeMapMethod<String, dynamic>('state');
    if (state == null || state['status'] != TunnelStatus.connected.name) {
      return null;
    }
    final raw = state['config'];
    if (status != TunnelStatus.connected) emit(TunnelStatus.connected);
    if (raw is! String) return const {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return const {};
    }
  }
}

/// Режим, которого на платформе нет (системный прокси на Android). Контроллер
/// туда не попадает — на Android он всегда в TUN, — но если попадёт, честно
/// сообщит об ошибке, а не повиснет.
class UnsupportedTunnel extends TunnelController {
  UnsupportedTunnel(this.reason);
  final String reason;

  @override
  Future<void> start(Map<String, dynamic> config,
      {required int port, required String service}) async {
    lastError = reason;
    emit(TunnelStatus.error);
  }

  @override
  Future<void> stop() async => emit(TunnelStatus.disconnected);
}
