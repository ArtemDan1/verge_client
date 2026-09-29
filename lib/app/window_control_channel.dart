import 'package:flutter/services.dart';

/// Управление главным окном из нативной части.
///
/// Скрытие при закрытии крестиком нативная сторона делает сама
/// (MainFlutterWindow / WM_CLOSE) — сюда для этого ходить не нужно.
///
/// Мини-окно трея — это то же главное окно, временно без рамки и поверх всех
/// у значка: второго окна Flutter на десктопе в стабильной ветке нет, а
/// отдельный движок потребовал бы гонять состояние между изолятами.
class WindowControlChannel {
  WindowControlChannel([MethodChannel? channel])
      : _channel = channel ?? const MethodChannel('window/control');

  final MethodChannel _channel;

  Future<void> show() => _channel.invokeMethod('show');

  /// Сделать окно мини-окном трея размером [size] (логические пиксели).
  Future<void> showPopover(Size size) => _channel.invokeMethod(
      'showPopover', {'width': size.width, 'height': size.height});

  /// Вернуть окну обычный вид; [openMain] — сразу показать главное окно.
  Future<void> hidePopover({bool openMain = false}) =>
      _channel.invokeMethod('hidePopover', {'openMain': openMain});

  /// Нативная сторона закрыла мини-окно сама: клик мимо, Cmd+W, «Открыть»
  /// из меню или Dock.
  void onPopoverDismissed(VoidCallback callback) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'popoverDismissed') callback();
      return null;
    });
  }
}
