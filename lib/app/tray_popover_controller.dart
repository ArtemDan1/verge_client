import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Size, WidgetsBinding;

import 'window_control_channel.dart';

/// Состояние мини-окна трея: открыто ли оно и переходы между ним и главным
/// окном. Интерфейс (main.dart) слушает [isOpen] и рисует либо главный экран,
/// либо мини-окно.
class TrayPopoverController extends ChangeNotifier {
  TrayPopoverController(
    this._window, {
    Future<void> Function()? waitForFrame,
    DateTime Function()? now,
  })  : _waitForFrame = waitForFrame ?? _defaultWaitForFrame,
        _now = now ?? DateTime.now {
    _window.onPopoverDismissed(_onNativeDismissed);
  }

  final WindowControlChannel _window;
  final Future<void> Function() _waitForFrame;
  final DateTime Function() _now;

  /// Ширина мини-окна в логических пикселях.
  static const double width = 340;

  bool _open = false;
  bool get isOpen => _open;

  /// Когда мини-окно последний раз закрылось само.
  DateTime? _dismissedAt;

  /// Клик по значку трея сначала снимает фокус с мини-окна (оно
  /// закрывается), и только потом приходит событие клика. Без этого окна
  /// клик «закрыть» тут же открывал бы мини-окно заново.
  static const _reopenGuard = Duration(milliseconds: 400);

  /// Клик по значку трея: открыть или закрыть мини-окно.
  Future<void> toggle(double height) async {
    if (_open) {
      await close();
      return;
    }
    final dismissed = _dismissedAt;
    if (dismissed != null && _now().difference(dismissed) < _reopenGuard) {
      return;
    }
    _open = true;
    notifyListeners();
    // Сначала Flutter рисует компактный интерфейс, потом окно ужимается —
    // иначе на мгновение мелькнул бы главный экран в маленьком окне.
    await _waitForFrame();
    await _window.showPopover(Size(width, height));
  }

  /// Закрыть мини-окно; [openMain] — показать главное окно.
  Future<void> close({bool openMain = false}) async {
    if (!_open) {
      if (openMain) await _window.show();
      return;
    }
    _open = false;
    notifyListeners();
    await _window.hidePopover(openMain: openMain);
  }

  /// Показать главное окно из мини-окна.
  Future<void> openMain() => close(openMain: true);

  /// Выход из приложения — задаёт TrayService (там же штатное отключение).
  Future<void> Function()? onQuit;

  /// Кнопка «Выйти» в мини-окне. Меню трея больше нет, а на Windows крестик
  /// лишь прячет окно — это единственный путь закрыть приложение.
  Future<void> quit() async => onQuit?.call();

  void _onNativeDismissed() {
    _dismissedAt = _now();
    if (!_open) return;
    _open = false;
    notifyListeners();
  }

  static Future<void> _defaultWaitForFrame() async {
    WidgetsBinding.instance.scheduleFrame();
    // Скрытое окно кадры может и не рисовать — ждём недолго.
    await WidgetsBinding.instance.endOfFrame
        .timeout(const Duration(milliseconds: 150), onTimeout: () {});
  }
}
