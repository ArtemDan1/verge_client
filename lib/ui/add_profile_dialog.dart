import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart' show Clipboard;
import 'package:shadcn_ui/shadcn_ui.dart';
import '../app/app_controller.dart';
import '../services/subscription_service.dart';
import '../theme/verge_palette.dart';

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

/// Диалог добавления подписки: из буфера обмена одной кнопкой или вводом
/// ссылки. Имя профиля берётся из ссылки. Возвращает true при успехе.
Future<bool> showAddProfileDialog(BuildContext context, AppController c) async {
  final result = await showShadDialog<bool>(
    context: context,
    builder: (dialogContext) => _AddProfileSheet(controller: c),
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
    final palette = VergePalette.of(context);
    return ShadDialog(
      title: const Text('Добавить подписку'),
      description: const Text(
          'URL подписки, share-ссылка (vless://, ss://…) или JSON-конфиг'),
      constraints: const BoxConstraints(maxWidth: 440),
      actions: [
        ShadButton.outline(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
        ),
        ShadButton(
          onPressed: _busy ? null : () => _add(_linkCtrl.text),
          child: const Text('Добавить'),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.accentSoft,
                border: Border.all(color: palette.accentSoftBorder),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.clipboardPaste,
                      size: 20, color: palette.accentText),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Скопировали ссылку? Добавим прямо из буфера обмена',
                      style: TextStyle(
                          fontSize: 13, color: theme.colorScheme.foreground),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ShadButton(
                    size: ShadButtonSize.sm,
                    backgroundColor: palette.accent,
                    foregroundColor: const Color(0xFFFFFFFF),
                    onPressed: _busy ? null : _fromClipboard,
                    child: const Text('Вставить'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: Container(height: 1, color: palette.panelBorder)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('или',
                      style: theme.textTheme.muted.copyWith(fontSize: 12)),
                ),
                Expanded(
                    child: Container(height: 1, color: palette.panelBorder)),
              ],
            ),
            const SizedBox(height: 14),
            ShadInput(
              controller: _linkCtrl,
              autofocus: true,
              placeholder: const Text('https://… или vless://…'),
              onSubmitted: _busy ? null : (v) => _add(v),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!,
                    style: TextStyle(color: palette.dangerText)),
              ),
          ],
        ),
      ),
    );
  }
}
