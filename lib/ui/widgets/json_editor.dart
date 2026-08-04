import 'dart:convert';
import 'package:flutter/material.dart'
    show InputBorder, InputDecoration, Material, MaterialType, TextField;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Разбирает и форматирует JSON с отступом в 2 пробела, пробрасывая
/// FormatException наружу. Отдельно от [prettyPrintJson], чтобы вызывающий мог
/// получить позицию ошибки, а не только факт неудачи.
String prettyPrintJsonOrThrow(String source) =>
    const JsonEncoder.withIndent('  ').convert(jsonDecode(source));

String? prettyPrintJson(String source) {
  try {
    return prettyPrintJsonOrThrow(source);
  } on FormatException {
    return null;
  }
}

/// Позиция важнее текста: в конфиге на сотню строк «Unexpected character»
/// без номера символа бесполезно.
String jsonErrorMessage(FormatException e) {
  final offset = e.offset;
  return offset == null
      ? 'Некорректный JSON: ${e.message}'
      : 'Некорректный JSON: ${e.message} (символ $offset)';
}

/// Фолбэк-реализация поверх обычного TextField: flutter_code_editor 0.3.5
/// портит содержимое при замене текста целиком (paste, программная замена),
/// если новый текст отличается от старого числом строк — воспроизводится на
/// уровне CodeController.value, без подсветки синтаксиса и сворачивания, но
/// корректная замена важнее подсветки.
class JsonEditor extends StatefulWidget {
  const JsonEditor({
    super.key,
    required this.initialText,
    required this.onChanged,
  });

  final String initialText;
  final ValueChanged<String> onChanged;

  @override
  State<JsonEditor> createState() => _JsonEditorState();
}

class _InsertTabIntent extends Intent {
  const _InsertTabIntent();
}

class _JsonEditorState extends State<JsonEditor> {
  late final TextEditingController _controller;
  // Два отдельных контроллера, а не общий: TextField сам присваивает своему
  // ScrollController единственного клиента и падает на любом обращении к
  // .position, если к тому же контроллеру подключить ещё и колонку номеров.
  final _fieldScroll = ScrollController();
  final _gutterScroll = ScrollController();

  static const _textStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    height: 1.4,
  );

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _controller.addListener(() => widget.onChanged(_controller.text));
    _fieldScroll.addListener(() {
      if (_gutterScroll.hasClients &&
          _gutterScroll.offset != _fieldScroll.offset) {
        _gutterScroll.jumpTo(_fieldScroll.offset);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _fieldScroll.dispose();
    _gutterScroll.dispose();
    super.dispose();
  }

  /// Tab вставляет два пробела вместо перевода фокуса — привычное поведение
  /// для редактора кода.
  void _insertTab() {
    final sel = _controller.selection;
    final text = _controller.text;
    final start = sel.start < 0 ? text.length : sel.start;
    final end = sel.end < 0 ? text.length : sel.end;
    final newText = text.replaceRange(start, end, '  ');
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
              child: SizedBox(
                width: 28,
                child: SingleChildScrollView(
                  controller: _gutterScroll,
                  physics: const NeverScrollableScrollPhysics(),
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _controller,
                    builder: (context, value, _) {
                      final lineCount = '\n'.allMatches(value.text).length + 1;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 1; i <= lineCount; i++)
                            Text(
                              '$i',
                              style: _textStyle.copyWith(
                                  color: theme.colorScheme.mutedForeground),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              child: Shortcuts(
                shortcuts: const {
                  SingleActivator(LogicalKeyboardKey.tab): _InsertTabIntent(),
                },
                child: Actions(
                  actions: {
                    _InsertTabIntent: CallbackAction<_InsertTabIntent>(
                      onInvoke: (_) {
                        _insertTab();
                        return null;
                      },
                    ),
                  },
                  child: TextField(
                    controller: _controller,
                    scrollController: _fieldScroll,
                    maxLines: null,
                    style: _textStyle,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.all(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
