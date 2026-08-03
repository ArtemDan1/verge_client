import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

/// Свободный TCP-порт на loopback. Ядро выдаёт порт по bind(0), после чего
/// сокет закрывается — крошечное окно гонки здесь приемлемо: порт тут же
/// занимает Xray, а неудачный старт всё равно ловится пробой.
Future<int> pickFreePort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

/// Принимает ли socks-порт TCP-соединение. Это и есть критерий «Xray поднялся»:
/// реальный трафик не проверяем — это добавило бы секунды к подключению.
Future<bool> probeSocks(int port,
    {Duration timeout = const Duration(milliseconds: 700)}) async {
  try {
    final socket = await Socket.connect(
        InternetAddress.loopbackIPv4, port, timeout: timeout);
    socket.destroy();
    return true;
  } on SocketException {
    return false;
  }
}

/// Дочерний процесс Xray-core на стороне платформы.
class XrayProcess {
  static const _channel = MethodChannel('singbox/xray');
  static const _events = EventChannel('singbox/xray/events');

  final _logs = StreamController<String>.broadcast();
  StreamSubscription? _sub;

  /// Подписка на платформенный канал — ленивая: контроллер создаёт XrayProcess
  /// только когда движок реально нужен, а тестовые дублёры канал не трогают
  /// вовсе.
  Stream<String> get logs {
    _sub ??= _events.receiveBroadcastStream().listen((e) {
      final map = Map<String, dynamic>.from(e as Map);
      if (map['type'] == 'log') _logs.add(map['line'] as String);
    }, onError: (_) {});
    return _logs.stream;
  }

  /// Бросает [PlatformException], если процесс не поднялся.
  Future<void> start(Map<String, dynamic> config) =>
      _channel.invokeMethod('start', {'config': jsonEncode(config)});

  Future<void> stop() => _channel.invokeMethod('stop');

  void dispose() {
    _sub?.cancel();
    _logs.close();
  }
}
