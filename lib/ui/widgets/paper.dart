import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../theme/app_theme.dart';
import '../../theme/verge_palette.dart';

/// Мелкие общие элементы дизайна «Бумага», которых нет в shadcn.

/// Заголовок экрана с подзаголовком и действиями справа.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final Widget? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: theme.colorScheme.foreground,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                DefaultTextStyle.merge(
                  style: theme.textTheme.muted.copyWith(fontSize: 13),
                  child: subtitle!,
                ),
              ],
            ],
          ),
        ),
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          actions[i],
        ],
      ],
    );
  }
}

/// Внутренние отступы экрана на панели контента.
const kScreenPadding = EdgeInsets.fromLTRB(26, 22, 26, 22);

/// Чип с кодом страны («NL») вместо флага-emoji.
class CountryChip extends StatelessWidget {
  const CountryChip(this.code, {super.key});
  final String code;

  @override
  Widget build(BuildContext context) {
    final palette = VergePalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: palette.chip,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        code,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: palette.chipForeground,
        ),
      ),
    );
  }
}

/// Плитка статистики: подпись сверху, моноширинное значение снизу.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: VergePalette.of(context).surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.muted.copyWith(fontSize: 12)),
          const SizedBox(height: 2),
          SizedBox(
            height: 24,
            child: Align(
              alignment: Alignment.centerLeft,
              child: DefaultTextStyle.merge(
                style: monoStyle(
                    fontSize: 16, color: theme.colorScheme.foreground),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Сегментный переключатель: белая «таблетка» выбранного варианта на
/// приглушённой дорожке. Своя реализация вместо ShadTabs — у тех контент-зона
/// и внутренние отступы, которые в строку фиксированной высоты не влезают.
class Segmented<T> extends StatelessWidget {
  const Segmented({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.height = 38,
  });

  final T value;
  final List<SegmentedOption<T>> options;
  final ValueChanged<T>? onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = VergePalette.of(context);
    final theme = ShadTheme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: dark ? palette.chrome : palette.chip,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: _SegmentButton(
                option: o,
                selected: o.value == value,
                onTap: onChanged == null ? null : () => onChanged!(o.value),
              ),
            ),
        ],
      ),
    );
  }
}

class SegmentedOption<T> {
  const SegmentedOption({required this.value, required this.label, this.icon});
  final T value;
  final String label;
  final IconData? icon;
}

class _SegmentButton<T> extends StatelessWidget {
  const _SegmentButton({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final SegmentedOption<T> option;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final palette = VergePalette.of(context);
    final dark = theme.brightness == Brightness.dark;
    final fg = selected
        ? theme.colorScheme.foreground
        : theme.colorScheme.mutedForeground;
    return Semantics(
      button: true,
      selected: selected,
      child: MouseRegion(
        cursor: onTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            // Прозрачный вариант того же цвета, а не прозрачный чёрный:
            // иначе анимация переключения проходит через серую вспышку.
            decoration: BoxDecoration(
              color: (dark ? palette.navActiveRing : palette.panel)
                  .withValues(alpha: selected ? 1 : 0),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000)
                      .withValues(alpha: selected && !dark ? 0.08 : 0),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (option.icon != null) ...[
                  Icon(option.icon, size: 14, color: fg),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    option.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: fg,
                    ),
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

/// Квадратная кнопка-иконка с обводкой и подсказкой.
class IconAction extends StatelessWidget {
  const IconAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ShadTooltip(
      builder: (_) => Text(tooltip),
      child: ShadButton.outline(
        width: 36,
        height: 36,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Icon(icon, size: 16),
      ),
    );
  }
}
