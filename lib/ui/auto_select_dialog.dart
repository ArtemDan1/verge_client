import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../app/app_controller.dart';
import '../models/auto_select_settings.dart';
import '../tunnel/tunnel_controller.dart';

/// Настройки автовыбора: тумблер, адрес для теста, интервал фоновой проверки
/// и набор профилей, в которых подбирается лучшая нода.
void showAutoSelectDialog(BuildContext context, AppController c) {
  showShadDialog(
    context: context,
    builder: (ctx) => _AutoSelectDialog(controller: c),
  );
}

/// Часы:минуты:секунды последней фоновой проверки.
String _time(DateTime t) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
}

class _AutoSelectDialog extends StatefulWidget {
  final AppController controller;
  const _AutoSelectDialog({required this.controller});

  @override
  State<_AutoSelectDialog> createState() => _AutoSelectDialogState();
}

class _AutoSelectDialogState extends State<_AutoSelectDialog> {
  late bool _enabled;
  late Set<String> _profileIds;
  late final TextEditingController _url;
  late final TextEditingController _interval;

  @override
  void initState() {
    super.initState();
    final s = widget.controller.autoSelect;
    _enabled = s.enabled;
    _profileIds = {...s.profileIds};
    _url = TextEditingController(text: s.testUrl);
    _interval = TextEditingController(text: '${s.healthCheckIntervalSeconds}');
  }

  @override
  void dispose() {
    _url.dispose();
    _interval.dispose();
    super.dispose();
  }

  AutoSelectSettings _collect() {
    final url = _url.text.trim();
    final seconds = int.tryParse(_interval.text.trim());
    return AutoSelectSettings(
      enabled: _enabled,
      // Пустое поле — не повод сохранить неработающий адрес.
      testUrl: url.isEmpty ? AutoSelectSettings.defaultTestUrl : url,
      profileIds: _profileIds,
      healthCheckIntervalSeconds: AutoSelectSettings.clampInterval(
        seconds ?? AutoSelectSettings.defaultIntervalSeconds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final c = widget.controller;
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) => ShadDialog(
        title: const Text('Автовыбор ноды'),
        constraints: const BoxConstraints(maxWidth: 460),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ShadButton(
            onPressed: () {
              // Переподключаемся, чтобы новые настройки применились сразу, а
              // не со следующего ручного подключения.
              c.updateAutoSelectSettings(_collect()).then((_) {
                if (c.status == TunnelStatus.connected) c.reconnect();
              });
              Navigator.of(context).pop();
            },
            child: const Text('Сохранить'),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Подбирать лучшую ноду',
                      style: theme.textTheme.p,
                    ),
                  ),
                  ShadSwitch(
                    value: _enabled,
                    onChanged: (v) => setState(() => _enabled = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Адрес для проверки', style: theme.textTheme.muted),
              const SizedBox(height: 4),
              ShadInput(
                controller: _url,
                placeholder: const Text(AutoSelectSettings.defaultTestUrl),
              ),
              const SizedBox(height: 12),
              Text(
                'Интервал фоновой проверки, секунды '
                '(${AutoSelectSettings.minIntervalSeconds}…'
                '${AutoSelectSettings.maxIntervalSeconds})',
                style: theme.textTheme.muted,
              ),
              const SizedBox(height: 4),
              ShadInput(
                controller: _interval,
                keyboardType: TextInputType.number,
                placeholder: const Text(
                  '${AutoSelectSettings.defaultIntervalSeconds}',
                ),
              ),
              const SizedBox(height: 12),
              Text('Профили', style: theme.textTheme.muted),
              const SizedBox(height: 4),
              // Прокручивается только список: профилей может быть десяток,
              // а поля и кнопки должны оставаться на виду.
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final p in c.profiles)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: ShadCheckbox(
                            value: _profileIds.contains(p.id),
                            onChanged: (v) => setState(() {
                              if (v) {
                                _profileIds.add(p.id);
                              } else {
                                _profileIds.remove(p.id);
                              }
                            }),
                            label: Text(p.name),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ShadButton.outline(
                // Перебор идёт по отмеченным профилям, поэтому нужен хотя бы
                // один отмеченный — активный профиль тут ни при чём.
                onPressed: c.isAutoSelecting || _profileIds.isEmpty
                    ? null
                    : () {
                        c.updateAutoSelectSettings(_collect());
                        c.autoSelectBest();
                      },
                leading: c.isAutoSelecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: ShadProgress(),
                      )
                    : const Icon(LucideIcons.zap, size: 16),
                child: const Text('Проверить сейчас'),
              ),
              if (c.lastHealthCheckAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Последняя проверка: ${_time(c.lastHealthCheckAt!)} — '
                  '${c.lastHealthCheckOk == true ? 'нода отвечает' : 'нет ответа'}',
                  style: theme.textTheme.muted,
                ),
              ],
              if (c.lastAutoSelectResult != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Последний подбор: ${c.lastAutoSelectResult}',
                  style: theme.textTheme.muted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
