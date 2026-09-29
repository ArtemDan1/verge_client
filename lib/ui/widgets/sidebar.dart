import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/connection_info.dart';
import '../../theme/verge_palette.dart';
import 'traffic_widget.dart';
import 'verge_logo.dart';

class SidebarItem {
  const SidebarItem(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Пункты сайдбара. «О приложении» вынесен в самый низ отдельно,
/// поэтому здесь только верхняя группа.
const sidebarItems = <SidebarItem>[
  SidebarItem('Главная', LucideIcons.house),
  SidebarItem('Настройки', LucideIcons.slidersVertical),
  SidebarItem('Логи', LucideIcons.fileText),
  SidebarItem('Соединения', LucideIcons.arrowLeftRight),
  SidebarItem('Роутинг', LucideIcons.route),
];

const aboutItem = SidebarItem('О приложении', LucideIcons.info);
// Индекс вычисляется, чтобы добавление пункта не ломало навигацию.
final aboutIndex = sidebarItems.length;
final connectionsIndex =
    sidebarItems.indexWhere((e) => e.label == 'Соединения');

/// Сайдбар в тон фону окна: сам он «бумага», а контент лежит на отдельной
/// панели справа (см. AppShell).
class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.index,
    required this.onSelect,
    required this.connectionCount,
    required this.traffic,
    required this.hasUpdate,
  });
  final int index;
  final ValueChanged<int> onSelect;
  final int connectionCount;
  final TrafficStats traffic;
  final bool hasUpdate;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Container(
      width: 232,
      color: VergePalette.of(context).chrome,
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 20),
            child: VergeLogo(titleColor: theme.colorScheme.foreground),
          ),
          for (var i = 0; i < sidebarItems.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: _NavItem(
                item: sidebarItems[i],
                selected: i == index,
                onTap: () => onSelect(i),
                trailing: i == connectionsIndex && connectionCount > 0
                    // Счётчик скрыт при нуле — при выключенном VPN он шум.
                    ? Text('$connectionCount',
                        style: theme.textTheme.muted.copyWith(fontSize: 12))
                    : null,
              ),
            ),
          const Spacer(),
          TrafficWidget(stats: traffic),
          const SizedBox(height: 6),
          _NavItem(
            item: aboutItem,
            selected: index == aboutIndex,
            onTap: () => onSelect(aboutIndex),
            // Метка, а не число: обновление всегда одно, важен сам факт.
            trailing: hasUpdate ? const _NewBadge(key: Key('update-dot')) : null,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final SidebarItem item;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final palette = VergePalette.of(context);
    final selected = widget.selected;
    final fg = selected ? theme.colorScheme.foreground : palette.navForeground;
    // Все состояния — оттенки одного цвета: AnimatedContainer интерполирует
    // между ними, и переход через прозрачный ЧЁРНЫЙ давал тёмную вспышку
    // на середине анимации при наведении.
    final bg = selected
        ? palette.navActive
        : palette.navActive.withValues(alpha: _hovered ? 0.6 : 0);
    return Semantics(
      button: true,
      selected: selected,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: palette.navActiveRing
                    .withValues(alpha: selected ? 1 : 0),
              ),
              // Тень всегда в списке, меняется только прозрачность — иначе
              // лерп null↔тень тоже даёт скачок.
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1C1B18).withValues(
                      alpha: selected && theme.brightness == Brightness.light
                          ? 0.08
                          : 0),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(widget.item.icon, size: 17, color: fg),
                const SizedBox(width: 12),
                // Flexible+ellipsis: длинные подписи не вызывают overflow.
                Expanded(
                  child: Text(
                    widget.item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: fg,
                    ),
                  ),
                ),
                if (widget.trailing != null) ...[
                  const SizedBox(width: 6),
                  widget.trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: VergePalette.of(context).accent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'новое',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFFFFFFFF),
        ),
      ),
    );
  }
}
