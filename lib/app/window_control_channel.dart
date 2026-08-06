import 'package:flutter/services.dart';

/// Показ главного окна из Dart (тап «Открыть» в меню трея). Скрытие при
/// закрытии крестиком делает нативная сторона сама (MainFlutterWindow) —
/// сюда для этого ходить не нужно.
class WindowControlChannel {
  static const _channel = MethodChannel('window/control');

  Future<void> show() => _channel.invokeMethod('show');
}
