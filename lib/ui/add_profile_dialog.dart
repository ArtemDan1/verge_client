import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart' show Clipboard;
import 'package:shadcn_ui/shadcn_ui.dart';
import '../app/app_controller.dart';
import '../services/subscription_service.dart';

/// Имя профиля из ссылки: фрагмент после `#`, иначе хост, иначе «Профиль».
String deriveProfileName(String link) {
  final first = link
      .trim()
      .split('\n')
      .firstWhere((l) => l.trim().isNotEmpty, orElse: () => '')
      .trim();
  final hash = first.lastIndexOf('#');
  if (hash >= 0 && hash < first.length - 1) {
    final frag = Uri.decodeComponent(first.substring(hash + 1)).trim();
    if (frag.isNotEmpty) return frag;
  }
  final uri = Uri.tryParse(first);
  if (uri != null && uri.host.isNotEmpty) return uri.host;
  return 'Профиль';
}

/// Нижний лист добавления подписки: из буфера обмена или вводом ссылки.
/// Имя профиля берётся из ссылки. Возвращает true при успехе.
Future<bool> showAddProfileDialog(BuildContext context, AppController c) async {
  final result = await showShadSheet<bool>(
    context: context,
    side: ShadSheetSide.bottom,
    builder: (sheetContext) => _AddProfileSheet(controller: c),
  );
  return result ?? false;
}

class _AddProfileSheet extends StatefulWidget {
  const _AddProfileSheet({required this.controller});
  final AppController controller;

  @override
  State<_AddProfileSheet> createState() => _AddProfileSheetState();
}

class _AddProfileSheetState extends State<_AddProfileSheet> {
  bool _manual = false;
  bool _busy = false;
  String? _error;
  final _linkCtrl = TextEditingController();

  @override
  void dispose() {
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _add(String link) async {
    final trimmed = link.trim();
    if (trimmed.isEmpty) {
      setState(() => _error = 'Пустая ссылка');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.controller.addProfile(deriveProfileName(trimmed), trimmed);
      if (mounted) Navigator.of(context).pop(true);
    } on SubscriptionException catch (e) {
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _error = '$e';
      });
    }
  }

  Future<void> _fromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text ?? '';
    if (text.trim().isEmpty) {
      setState(() => _error = 'Буфер обмена пуст');
      return;
    }
    await _add(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadSheet(
      title: Text(_manual ? 'Вставьте ссылку' : 'Добавить профиль'),
      constraints: const BoxConstraints(maxWidth: 560),
      actions: _manual
          ? [
              ShadButton.outline(
                onPressed: _busy ? null : () => setState(() => _manual = false),
                child: const Text('Назад'),
              ),
              ShadButton(
                onPressed: _busy ? null : () => _add(_linkCtrl.text),
                child: const Text('Добавить'),
              ),
            ]
          : const [],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_manual)
              ShadInput(
                controller: _linkCtrl,
                placeholder: const Text(
                    'https://… или vless://… (имя возьмётся из ссылки)'),
                onSubmitted: _busy ? null : (v) => _add(v),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ShadButton.outline(
                      height: 88,
                      onPressed: _busy ? null : _fromClipboard,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.clipboard, size: 24),
                          SizedBox(height: 8),
                          Text('Добавить из буфера'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ShadButton.outline(
                      height: 88,
                      onPressed:
                          _busy ? null : () => setState(() => _manual = true),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.keyboard, size: 24),
                          SizedBox(height: 8),
                          Text('Ввести ссылку'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!,
                    style:
                        TextStyle(color: theme.colorScheme.destructive)),
              ),
          ],
        ),
      ),
    );
  }
}
