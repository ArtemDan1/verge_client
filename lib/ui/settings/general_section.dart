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
              children: padded
                  ? children
                  : [
                      // Строки разделяем линиями сами — строкам не нужно
                      // знать, первые они или нет (часть из них условная).
                      for (var i = 0; i < children.length; i++) ...[
                        if (i > 0)
                          Container(height: 1, color: palette.divider),
                        children[i],
                      ],
                    ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Подпись и пояснение настройки — общие для строк и полей.
class _SettingLabel extends StatelessWidget {
  const _SettingLabel({required this.label, this.description});

  final String label;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.3,
            color: theme.colorScheme.foreground,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 3),
          Text(
            description!,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: theme.colorScheme.mutedForeground,
            ),
          ),
        ],
      ],
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
    this.onTap,
  });

  final String label;
  final String? description;
  final Widget trailing;

  /// Клик по всей строке (например, раскрыть спойлер).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: _SettingLabel(label: label, description: description),
          ),
          const SizedBox(width: 24),
          trailing,
        ],
      ),
    );
    if (onTap == null) return row;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: row,
      ),
    );
  }
}

/// Поле во всю ширину под подписью — для длинных значений (адреса, DNS).
class SettingsField extends StatelessWidget {
  const SettingsField({
    super.key,
    required this.label,
    required this.child,
    this.description,
  });

  final String label;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SettingLabel(label: label, description: description),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );
}

/// Предупреждение внутри группы настроек.
class SettingsNotice extends StatelessWidget {
  const SettingsNotice(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = VergePalette.of(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: palette.dangerSoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(LucideIcons.triangleAlert,
                  size: 15, color: palette.dangerText),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 13, height: 1.4, color: palette.dangerText)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Узкое поле ввода для строки настройки (числа, короткие значения).
class SettingsInput extends StatelessWidget {
  const SettingsInput({
    super.key,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.placeholder,
    this.onSubmitted,
    this.number = false,
    this.width = 120,
    this.inputKey,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;
  final String? placeholder;
  final ValueChanged<String>? onSubmitted;
  final bool number;
  final double width;
  final Key? inputKey;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: ShadInput(
          key: inputKey,
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          focusNode: focusNode,
          placeholder: placeholder == null ? null : Text(placeholder!),
          keyboardType: number ? TextInputType.number : null,
          textAlign: TextAlign.right,
          onSubmitted: onSubmitted,
        ),
      );
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
        padded: false,
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
              label: 'Локальный порт прокси',
              description: 'HTTP + SOCKS на 127.0.0.1',
              trailing: SettingsInput(
                initialValue: '${s.localPort}',
                number: true,
                onSubmitted: (v) {
                  final port = int.tryParse(v.trim());
                  if (port != null && port > 0 && port < 65536) {
                    c.updateSettings(s.copyWith(localPort: port));
                  }
                },
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
