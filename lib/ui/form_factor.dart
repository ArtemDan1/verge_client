import 'package:flutter/widgets.dart';

/// Компактная (телефонная) раскладка интерфейса.
///
/// Экраны общие для десктопа и телефона; там, где раскладка различается
/// (отступы, ряд кнопок в заголовке), они спрашивают [FormFactor.isCompact].
/// Включает компактный режим [MobileShell].
class FormFactor extends InheritedWidget {
  const FormFactor({super.key, required this.compact, required super.child});

  final bool compact;

  static bool isCompact(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FormFactor>()?.compact ??
      false;

  @override
  bool updateShouldNotify(FormFactor oldWidget) => compact != oldWidget.compact;
}
