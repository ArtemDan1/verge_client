import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../app/app_controller.dart';
import '../../app/hotkey.dart';
import '../../models/app_settings.dart';
import '../../theme/verge_palette.dart';
import '../../l10n/l10n.dart';

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
                        if (i > 0) Container(height: 1, color: palette.divider),
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
              child: Icon(
                LucideIcons.triangleAlert,
                size: 15,
                color: palette.dangerText,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: palette.dangerText,
                ),
              ),
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

/// Вкладка «Общие»: тема, язык, запуск, горячая клавиша, локальный порт.
class GeneralSection extends StatelessWidget {
  const GeneralSection({super.key, required this.controller});

  final AppController controller;

  static String _themeLabel(AppThemeMode m) => switch (m) {
    AppThemeMode.system => l10n.themeSystem,
    AppThemeMode.light => l10n.themeLight,
    AppThemeMode.dark => l10n.themeDark,
  };

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final s = c.settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(
          title: l10n.theme,
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
                      onTap: () => c.updateSettings(s.copyWith(themeMode: m)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        SettingsGroup(
          title: l10n.language,
          padded: false,
          children: [
            SettingsRow(
              label: l10n.interfaceLanguage,
              trailing: SizedBox(
                width: 200,
                child: ShadSelect<String>(
                  key: const Key('language-select'),
                  initialValue: s.language,
                  options: [
                    ShadOption(
                      value: AppSettings.systemLanguage,
                      child: Text(l10n.languageSystem),
                    ),
                    for (final e in appLanguages.entries)
                      ShadOption(value: e.key, child: Text(e.value)),
                  ],
                  selectedOptionBuilder: (ctx, value) => Text(
                    value == AppSettings.systemLanguage
                        ? l10n.languageSystem
                        : appLanguages[value] ?? value,
                  ),
                  onChanged: (v) {
                    if (v != null) c.updateSettings(s.copyWith(language: v));
                  },
                ),
              ),
            ),
          ],
        ),
        SettingsGroup(
          title: l10n.startup,
          padded: false,
          children: [
            SettingsRow(
              label: l10n.autostart,
              description: l10n.autostartDescription,
              trailing: ShadSwitch(
                value: s.autostart,
                onChanged: (v) => c.updateSettings(s.copyWith(autostart: v)),
              ),
            ),
          ],
        ),
        SettingsGroup(
          title: l10n.hotkeys,
          padded: false,
          children: [
            SettingsRow(
              label: l10n.toggleHotkey,
              description: c.hotkeyFailed
                  ? l10n.hotkeyTaken
                  : l10n.toggleHotkeyDescription,
              trailing: HotkeyRecorder(
                value: HotkeySpec.tryParse(s.toggleHotkey),
                onChanged: (spec) => c.updateSettings(
                  s.copyWith(toggleHotkey: spec?.toString() ?? ''),
                ),
              ),
            ),
          ],
        ),
        SettingsGroup(
          title: l10n.kindProxy,
          padded: false,
          children: [
            SettingsRow(
              label: l10n.localProxyPort,
              description: l10n.localProxyPortDescription,
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

/// Поле записи сочетания клавиш: клик — ждём нажатия, Esc — отмена,
/// крестик — снять сочетание.
class HotkeyRecorder extends StatefulWidget {
  const HotkeyRecorder({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final HotkeySpec? value;
  final ValueChanged<HotkeySpec?> onChanged;

  @override
  State<HotkeyRecorder> createState() => _HotkeyRecorderState();
}

class _HotkeyRecorderState extends State<HotkeyRecorder> {
  final _focus = FocusNode(debugLabel: 'hotkey-recorder');
  bool _recording = false;
  bool _needsModifier = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _recording = true;
      _needsModifier = false;
    });
    _focus.requestFocus();
  }

  void _stop() {
    if (!mounted) return;
    setState(() => _recording = false);
    _focus.unfocus();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_recording) return KeyEventResult.ignored;
    if (event is KeyUpEvent) return KeyEventResult.handled;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _stop();
      return KeyEventResult.handled;
    }
    final spec = HotkeySpec.fromKey(
      event.physicalKey,
      HardwareKeyboard.instance.logicalKeysPressed,
    );
    // Модификатор сам по себе или клавиша, которую назначить нельзя, —
    // ждём дальше.
    if (spec == null) return KeyEventResult.handled;
    if (!spec.isValid) {
      setState(() => _needsModifier = true);
      return KeyEventResult.handled;
    }
    _stop();
    widget.onChanged(spec);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final palette = VergePalette.of(context);
    final value = widget.value;
    final String text;
    if (_recording) {
      text = _needsModifier ? l10n.hotkeyNeedsModifier : l10n.hotkeyPress;
    } else {
      text = value?.label() ?? l10n.hotkeyNotSet;
    }
    return Focus(
      focusNode: _focus,
      onKeyEvent: _onKey,
      onFocusChange: (has) {
        if (!has && _recording) _stop();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShadButton.outline(
            key: const Key('hotkey-recorder'),
            size: ShadButtonSize.sm,
            onPressed: _recording ? _stop : _start,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 96),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: value != null && !_recording
                      ? 'JetBrains Mono'
                      : null,
                  color: _recording
                      ? (_needsModifier
                            ? palette.dangerText
                            : theme.colorScheme.mutedForeground)
                      : null,
                ),
              ),
            ),
          ),
          if (value != null && !_recording) ...[
            const SizedBox(width: 6),
            ShadTooltip(
              builder: (_) => Text(l10n.hotkeyClear),
              child: ShadButton.ghost(
                key: const Key('hotkey-clear'),
                size: ShadButtonSize.sm,
                width: 32,
                padding: EdgeInsets.zero,
                onPressed: () => widget.onChanged(null),
                child: const Icon(LucideIcons.x, size: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
