import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../app/app_controller.dart';
import '../../models/app_settings.dart';

/// Заголовок + рамка секции настроек. Общий для всех секций, чтобы экран
/// читался как список карточек, а не как одна длинная колонка.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.description,
  });

  final String title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ShadCard(
        title: Text(title),
        description: description == null ? null : Text(description!),
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Тема, локальный порт прокси, автозапуск.
class GeneralSection extends StatelessWidget {
  const GeneralSection({super.key, required this.controller});

  final AppController controller;

  static String _themeLabel(AppThemeMode m) => switch (m) {
        AppThemeMode.system => 'Системная',
        AppThemeMode.light => 'Светлая',
        AppThemeMode.dark => 'Тёмная',
      };

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final s = c.settings;
    final theme = ShadTheme.of(context);
    return SettingsSection(
      title: 'Общие',
      children: [
        Text('Тема', style: theme.textTheme.large),
        const SizedBox(height: 8),
        ShadSelect<AppThemeMode>(
          minWidth: 240,
          initialValue: s.themeMode,
          options: const [
            ShadOption(value: AppThemeMode.system, child: Text('Системная')),
            ShadOption(value: AppThemeMode.light, child: Text('Светлая')),
            ShadOption(value: AppThemeMode.dark, child: Text('Тёмная')),
          ],
          selectedOptionBuilder: (ctx, v) => Text(_themeLabel(v)),
          onChanged: (v) =>
              v == null ? null : c.updateSettings(s.copyWith(themeMode: v)),
        ),
        const SizedBox(height: 24),
        Text('Локальный порт прокси', style: theme.textTheme.large),
        const SizedBox(height: 8),
        ShadInput(
          initialValue: '${s.localPort}',
          keyboardType: TextInputType.number,
          onSubmitted: (v) {
            final port = int.tryParse(v.trim());
            if (port != null && port > 0 && port < 65536) {
              c.updateSettings(s.copyWith(localPort: port));
            }
          },
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Автозапуск', style: theme.textTheme.large),
                  Text('Подключать последнюю ноду при старте',
                      style: theme.textTheme.muted),
                ],
              ),
            ),
            ShadSwitch(
              value: s.autostart,
              onChanged: (v) => c.updateSettings(s.copyWith(autostart: v)),
            ),
          ],
        ),
      ],
    );
  }
}
