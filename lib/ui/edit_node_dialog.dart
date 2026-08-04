import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../app/app_controller.dart';
import '../models/node_config.dart';
import '../services/node_editor.dart';
import 'widgets/json_editor.dart';

/// Диалог редактирования ноды: имя + сырой outbound-JSON. Формы больше нет —
/// у каждого протокола свой набор полей, и поддерживать их таблицами дороже,
/// чем дать редактировать конфиг напрямую.
Future<void> showEditNodeDialog(
  BuildContext context,
  AppController controller,
  String profileId,
  int index,
  NodeConfig node,
) async {
  await showShadDialog(
    context: context,
    builder: (ctx) => _EditNodeDialog(
      controller: controller,
      profileId: profileId,
      index: index,
      node: node,
    ),
  );
}

class _EditNodeDialog extends StatefulWidget {
  const _EditNodeDialog({
    required this.controller,
    required this.profileId,
    required this.index,
    required this.node,
  });

  final AppController controller;
  final String profileId;
  final int index;
  final NodeConfig node;

  @override
  State<_EditNodeDialog> createState() => _EditNodeDialogState();
}

class _EditNodeDialogState extends State<_EditNodeDialog> {
  final _nameCtrl = TextEditingController();

  /// Текущий текст редактора. Держим в State, а не читаем из виджета: по нему
  /// считается валидность и блокировка кнопки «Сохранить».
  late String _text;

  /// Ключ пересоздаёт JsonEditor после форматирования — CodeController не
  /// предполагает подмену текста снаружи.
  int _editorEpoch = 0;

  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.node.name;
    _text = nodeToEditableJson(widget.node);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    setState(() {
      _text = value;
      try {
        nodeFromJson(widget.node, _nameCtrl.text, value);
        _error = null;
      } on FormatException catch (e) {
        _error = jsonErrorMessage(e);
      }
    });
  }

  void _format() {
    final pretty = prettyPrintJson(_text);
    if (pretty == null) return;
    setState(() {
      _text = pretty;
      _editorEpoch++;
    });
  }

  Future<void> _save() async {
    final NodeConfig updated;
    try {
      updated = nodeFromJson(widget.node, _nameCtrl.text, _text);
    } on FormatException catch (e) {
      setState(() => _error = jsonErrorMessage(e));
      return;
    }
    await widget.controller
        .updateNode(widget.profileId, widget.index, updated);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadDialog(
      title: const Text('Редактировать ноду'),
      // Ширина — родным параметром диалога, а скролл целиком отдан ShadDialog
      // (scrollable: true по умолчанию). Свой SingleChildScrollView внутри
      // получал бы от внешнего неограниченную высоту, считал что контент влез,
      // и не скроллился, а maxHeight резал содержимое.
      constraints: const BoxConstraints(maxWidth: 640),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ShadButton(
          onPressed: _error == null ? _save : null,
          child: const Text('Сохранить'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Имя', style: theme.textTheme.muted),
          const SizedBox(height: 4),
          // Имя живёт в NodeConfig.name, а не в outbound-JSON, поэтому
          // отдельным полем, а не внутри редактора.
          ShadInput(controller: _nameCtrl),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                widget.node.rawSchema == RawSchema.xray
                    ? 'Схема: Xray'
                    : 'Схема: sing-box',
                style: theme.textTheme.muted,
              ),
              const Spacer(),
              ShadButton.ghost(
                size: ShadButtonSize.sm,
                onPressed: _format,
                child: const Text('Форматировать'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 360,
            child: JsonEditor(
              key: ValueKey(_editorEpoch),
              initialText: _text,
              onChanged: _onTextChanged,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: TextStyle(color: theme.colorScheme.destructive)),
          ],
          const SizedBox(height: 12),
          Text(
            'Изменения будут перезаписаны при обновлении подписки',
            style: theme.textTheme.muted,
          ),
        ],
      ),
    );
  }
}
