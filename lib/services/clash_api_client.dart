import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/connection_info.dart';

/// Адрес и токен локального Clash API sing-box. Порт и секрет генерируются
/// заново на каждый запуск туннеля — API слушает только loopback.
class ClashApiCredentials {
  const ClashApiCredentials({
    required this.port,
    required this.secret,
    this.host = '127.0.0.1',
  });

  final String host;
  final int port;
  final String secret;

  static final _rnd = Random.secure();

  /// Свободный порт узнаём у ОС: биндим 0 и сразу отпускаем. Гонка теоретически
  /// возможна, но sing-box стартует через доли секунды.
  static Future<ClashApiCredentials> generate() async {
    final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = probe.port;
    await probe.close();
    final bytes = List<int>.generate(24, (_) => _rnd.nextInt(256));
    return ClashApiCredentials(port: port, secret: base64Url.encode(bytes));
  }
}

/// Тонкая обёртка над WebSocket, чтобы клиент можно было тестировать без сети.
abstract class ClashSocket {
  Stream<String> get messages;
  Future<void> close();
}

typedef ClashSocketOpener = Future<ClashSocket> Function(String url);

class _IoSocket implements ClashSocket {
  _IoSocket(this._ws);
  final WebSocket _ws;

  @override
  Stream<String> get messages => _ws.map((e) => e is String ? e : '$e');

  @override
  Future<void> close() => _ws.close();
}

Future<ClashSocket> _openIoSocket(String url) async =>
    _IoSocket(await WebSocket.connect(url));

/// Держит два потока Clash API: скорость (/traffic) и снапшот соединений
/// (/connections, раз в секунду). Оба переподключаются сами: sing-box поднимает
/// API не мгновенно после старта процесса, первые отказы — норма.
class ClashApiClient {
  ClashApiClient({
    ClashSocketOpener? open,
    Duration retryStep = const Duration(milliseconds: 500),
  })  : _open = open ?? _openIoSocket,
        _retryStep = retryStep;

  final ClashSocketOpener _open;
  final Duration _retryStep;
  static const _retryMax = Duration(seconds: 5);

  final _connections = ValueNotifier<List<ConnectionInfo>>(const []);
  final _traffic = ValueNotifier<TrafficStats>(TrafficStats.zero);

  ValueListenable<List<ConnectionInfo>> get connections => _connections;
  ValueListenable<TrafficStats> get traffic => _traffic;

  ClashApiCredentials? _creds;
  final _loops = <_SocketLoop>[];

  void start(ClashApiCredentials creds) {
    stop();
    _creds = creds;
    final base = 'ws://${creds.host}:${creds.port}';
    final token = Uri.encodeQueryComponent(creds.secret);
    _loops.add(_SocketLoop(
      url: '$base/traffic?token=$token',
      open: _open,
      retryStep: _retryStep,
      retryMax: _retryMax,
      onMessage: _onTraffic,
    )..start());
    _loops.add(_SocketLoop(
      url: '$base/connections?token=$token',
      open: _open,
      retryStep: _retryStep,
      retryMax: _retryMax,
      onMessage: _onConnections,
    )..start());
  }

  Future<void> stop() async {
    _creds = null;
    final loops = List<_SocketLoop>.from(_loops);
    _loops.clear();
    for (final l in loops) {
      await l.stop();
    }
    _connections.value = const [];
    _traffic.value = TrafficStats.zero;
  }

  Future<void> dispose() async {
    await stop();
    _connections.dispose();
    _traffic.dispose();
  }

  void _onTraffic(Map<String, dynamic> json) {
    _traffic.value = TrafficStats.fromTraffic(json, _traffic.value);
  }

  void _onConnections(Map<String, dynamic> json) {
    _connections.value = parseConnections(json);
    _traffic.value = TrafficStats.fromConnectionsSnapshot(json, _traffic.value);
  }

  /// Есть ли активные креденшелы (для проверок в тестах и UI).
  bool get isRunning => _creds != null;
}

class _SocketLoop {
  _SocketLoop({
    required this.url,
    required this.open,
    required this.retryStep,
    required this.retryMax,
    required this.onMessage,
  });

  final String url;
  final ClashSocketOpener open;
  final Duration retryStep;
  final Duration retryMax;
  final void Function(Map<String, dynamic>) onMessage;

  bool _stopped = false;
  ClashSocket? _socket;
  StreamSubscription<String>? _sub;
  Timer? _retry;
  int _attempt = 0;

  void start() {
    _stopped = false;
    _connect();
  }

  Future<void> _connect() async {
    if (_stopped) return;
    try {
      final s = await open(url);
      if (_stopped) {
        await s.close();
        return;
      }
      _socket = s;
      _attempt = 0;
      _sub = s.messages.listen(
        _handle,
        onDone: _scheduleRetry,
        onError: (_) => _scheduleRetry(),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleRetry();
    }
  }

  void _handle(String raw) {
    try {
      final json = jsonDecode(raw);
      if (json is Map) onMessage(json.cast<String, dynamic>());
    } catch (_) {
      // Битое сообщение просто пропускаем: следующее придёт через секунду.
    }
  }

  void _scheduleRetry() {
    if (_stopped) return;
    _sub?.cancel();
    _sub = null;
    _socket = null;
    _attempt++;
    final delay = Duration(
      microseconds:
          min(retryStep.inMicroseconds * _attempt, retryMax.inMicroseconds),
    );
    _retry?.cancel();
    _retry = Timer(delay, _connect);
  }

  Future<void> stop() async {
    _stopped = true;
    _retry?.cancel();
    _retry = null;
    await _sub?.cancel();
    _sub = null;
    await _socket?.close();
    _socket = null;
  }
}
