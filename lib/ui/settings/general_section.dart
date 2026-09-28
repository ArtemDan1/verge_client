import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../app/app_controller.dart';
import '../../models/app_settings.dart';
import '../../theme/verge_palette.dart';

/// Заголовок + рамка секции настроек. Общий для всех секций, чтобы экран
/// читался как список карточек, а не как одна длинная колонка.
///
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
    final theme = ShadTheme.of(context);
    final palette = VergePalette.of(context);
    final text = theme.textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: text.muted.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: 2),
            Text(description!, style: text.muted.copyWith(fontSize: 12)),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.panel,
              border: Border.all(color: palette.panelBorder),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// Тема, локальный порт прокси, автозапуск.
class GeneralSection extends StatelessWidget {
  const GeneralSection({super.key, required this.controller});

  final AppController controller;

  static String _themeLabel(AppThemeMode m) => switch (m) {
        AppThemeMode.system => 'Как в системе',
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
        Text('Тема', style: theme.textTheme.small),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final m in const [
              AppThemeMode.light,
              AppThemeMode.dark,
              AppThemeMode.system,
            ]) ...[
              if (m != AppThemeMode.light) const SizedBox(width: 10),
              Expanded(
                child: _ThemeCard(
                  mode: m,
                  label: _themeLabel(m),
                  selected: s.themeMode == m,
                  onTap: () => c.updateSettings(s.copyWith(themeMode: m)),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        Text('Локальный порт прокси', style: theme.textTheme.small),
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
                  Text('Автозапуск', style: theme.textTheme.small),
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

/// Карточка выбора темы с миниатюрой окна: сайдбар + панель контента.
class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.mode,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final AppThemeMode mode;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final palette = VergePalette.of(context);
    const l = VergePalette.light;
    const d = VergePalette.dark;
    Widget half(Color chrome, Color panel, int flex) => Expanded(
          flex: flex,
          child: Row(
            children: [
              Expanded(flex: 3, child: Container(color: chrome)),
              Expanded(flex: 7, child: Container(color: panel)),
            ],
          ),
        );
    final preview = switch (mode) {
      AppThemeMode.light => [half(l.chrome, l.panel, 1)],
      AppThemeMode.dark => [half(d.chrome, d.panel, 1)],
      AppThemeMode.system => [
          Expanded(child: Container(color: l.chrome)),
          Expanded(child: Container(color: d.panel)),
        ],
    };
    return Semantics(
      button: true,
      selected: selected,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.all(selected ? 9 : 10),
            decoration: BoxDecoration(
              color: palette.panel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? (theme.brightness == Brightness.dark
                        ? palette.accentText
                        : palette.accent)
                    : palette.panelBorder,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 56,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: palette.panelBorder),
                  ),
                  child: Row(children: preview),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: theme.colorScheme.foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
