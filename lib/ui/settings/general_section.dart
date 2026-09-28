import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../app/app_controller.dart';
import '../../models/app_settings.dart';
import '../../theme/verge_palette.dart';

/// Внутри вкладки настроек заголовок секции совпадает с подписью вкладки,
/// поэтому экран вкладок прячет его через эту область.
class SettingsTabScope extends InheritedWidget {
  const SettingsTabScope({super.key, required super.child});

  static bool hidesTitles(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsTabScope>() != null;

  @override
  bool updateShouldNotify(SettingsTabScope oldWidget) => false;
}

/// Группа настроек: подпись над карточкой, внутри — строки.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    required this.children,
    this.title,
    this.description,
    this.padded = true,
  });

  final String? title;
  final String? description;
  final List<Widget> children;

  /// false — строки сами задают отступы и разделители ([SettingsRow]).
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final text = ShadTheme.of(context).textTheme;
    final palette = VergePalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: text.muted.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (description != null) ...[
            Text(description!, style: text.muted.copyWith(fontSize: 13)),
            const SizedBox(height: 8),
          ],
          Container(
            clipBehavior: Clip.antiAlias,
            padding: padded ? const EdgeInsets.all(16) : EdgeInsets.zero,
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

/// Строка настройки: подпись и пояснение слева, контрол справа.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    required this.trailing,
    this.description,
    this.first = false,
  });

  final String label;
  final String? description;
  final Widget trailing;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: first
            ? null
            : Border(
                top: BorderSide(color: VergePalette.of(context).divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(description!,
                      style: theme.textTheme.muted.copyWith(fontSize: 13)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          trailing,
        ],
      ),
    );
  }
}

/// Секция одной вкладки настроек (TUN, DNS, TLS…). Заголовок показывается
/// только вне вкладок.
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
  Widget build(BuildContext context) => SettingsGroup(
        title: SettingsTabScope.hidesTitles(context) ? null : title,
        description: description,
        children: children,
      );
}

/// Вкладка «Общие»: тема, запуск, локальный порт.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(
          title: 'Тема',
          children: [
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
                      onTap: () =>
                          c.updateSettings(s.copyWith(themeMode: m)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        SettingsGroup(
          title: 'Запуск',
          padded: false,
          children: [
            SettingsRow(
              first: true,
              label: 'Автозапуск',
              description: 'Подключать последнюю ноду при старте',
              trailing: ShadSwitch(
                value: s.autostart,
                onChanged: (v) => c.updateSettings(s.copyWith(autostart: v)),
              ),
            ),
          ],
        ),
        SettingsGroup(
          title: 'Прокси',
          padded: false,
          children: [
            SettingsRow(
              first: true,
              label: 'Локальный порт прокси',
              description: 'HTTP + SOCKS на 127.0.0.1',
              trailing: SizedBox(
                width: 110,
                child: ShadInput(
                  initialValue: '${s.localPort}',
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  onSubmitted: (v) {
                    final port = int.tryParse(v.trim());
                    if (port != null && port > 0 && port < 65536) {
                      c.updateSettings(s.copyWith(localPort: port));
                    }
                  },
                ),
              ),
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
