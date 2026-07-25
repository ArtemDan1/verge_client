import 'dart:async';

enum TunnelStatus { disconnected, connecting, connected, error }

abstract class TunnelController {
  final _statusCtrl = StreamController<TunnelStatus>.broadcast();
  final _logCtrl = StreamController<String>.broadcast();

  Stream<TunnelStatus> get statusStream => _statusCtrl.stream;
  Stream<String> get logStream => _logCtrl.stream;

  TunnelStatus _status = TunnelStatus.disconnected;
  TunnelStatus get status => _status;

  /// Последняя причина аварийного завершения (FATAL и т.п.), если была.
  String? lastError;

  Future<void> start(Map<String, dynamic> config,
      {required int port, required String service});
  Future<void> stop();

  void emit(TunnelStatus s) {
    _status = s;
    _statusCtrl.add(s);
  }

  void emitLog(String line) => _logCtrl.add(line);

  Future<void> dispose() async {
    await _statusCtrl.close();
    await _logCtrl.close();
  }
}
