import 'dart:convert';
import 'package:flutter/services.dart';

/// Тестовый процесс sing-box. Отдельный канал, а не `singbox/tunnel`: тот
/// управляет боевым туннелем, и занять его под замер нельзя.
class SingboxTestProcess {
  static const _channel = MethodChannel('singbox/test');
  static const _events = EventChannel('singbox/test/events');

  /// Вывод процесса. Без него провал замера выглядит просто как «HTTP не
  /// прошёл ни у одной ноды», и причину не узнать.
  static Stream<String> get logs =>
      _events.receiveBroadcastStream().map((e) => '$e');

  Future<void> start(Map<String, dynamic> config) =>
      _channel.invokeMethod('start', {'config': jsonEncode(config)});

  Future<void> stop() => _channel.invokeMethod('stop');
}

/// Тестовый процесс Xray — для нод, которые sing-box не поднимает.
class XrayTestProcess {
  static const _channel = MethodChannel('xray/test');
  static const _events = EventChannel('xray/test/events');

  static Stream<String> get logs =>
      _events.receiveBroadcastStream().map((e) => '$e');

  Future<void> start(Map<String, dynamic> config) =>
      _channel.invokeMethod('start', {'config': jsonEncode(config)});

  Future<void> stop() => _channel.invokeMethod('stop');
}
