import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/connection_info.dart';
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
  SidebarItem('Настройки', LucideIcons.settings),
  SidebarItem('Логи', LucideIcons.scrollText),
  SidebarItem('Соединения', LucideIcons.arrowLeftRight),
  SidebarItem('Роутинг', LucideIcons.route),
];

const aboutItem = SidebarItem('О приложении', LucideIcons.info);
// Индекс вычисляется, чтобы добавление пункта не ломало навигацию.
final aboutIndex = sidebarItems.length;
final connectionsIndex =
    sidebarItems.indexWhere((e) => e.label == 'Соединения');

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.index,
    required this.onSelect,
    required this.connectionCount,
    required this.traffic,
  });
  final int index;
  final ValueChanged<int> onSelect;
  final int connectionCount;
  final TrafficStats traffic;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Container(
      width: 224,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: theme.colorScheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
            child: VergeLogo(titleColor: theme.colorScheme.foreground),
          ),
          for (var i = 0; i < sidebarItems.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _navButton(theme, i, sidebarItems[i],
                  badge: i == connectionsIndex ? connectionCount : null),
            ),
          const Spacer(),
          TrafficWidget(stats: traffic),
          _navButton(theme, aboutIndex, aboutItem),
        ],
      ),
    );
  }

  Widget _navButton(ShadThemeData theme, int i, SidebarItem item, {int? badge}) {
    return ShadButton.ghost(
      onPressed: () => onSelect(i),
      backgroundColor: i == index ? theme.colorScheme.accent : null,
      mainAxisAlignment: MainAxisAlignment.start,
      // Иконка внутри child, а не в leading: разные глифы Lucide имеют разную
      // ширину, из-за чего подписи «прыгали» по горизонтали. Фиксированный бокс
      // выравнивает старт текста для всех пунктов.
      child: Row(
        // min: ShadButton отдаёт child неограниченную ширину, Expanded здесь падает.
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            child: Icon(item.icon, size: 16),
          ),
          const SizedBox(width: 8),
          // Flexible+ellipsis: длинные подписи (напр. «О приложении») не вызывают
          // overflow при узком сайдбаре.
          Flexible(
            child: Text(item.label, overflow: TextOverflow.ellipsis, maxLines: 1),
          ),
          // Badge скрыт при нуле — при выключенном VPN он был бы шумом.
          if (badge != null && badge > 0) ...[
            const SizedBox(width: 6),
            ShadBadge(child: Text('$badge')),
          ],
        ],
      ),
    );
  }
}
