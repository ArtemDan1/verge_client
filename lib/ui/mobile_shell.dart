import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../app/app_controller.dart';
import '../models/connection_info.dart';
import '../services/deep_link.dart';
import '../theme/verge_palette.dart';
import 'connections_screen.dart';
import 'form_factor.dart';
import 'logs_screen.dart';
import 'profiles_screen.dart';
import 'routing_screen.dart';
import 'settings_screen.dart';
import 'shell_events.dart';
import 'widgets/sidebar.dart';
import 'widgets/update_banner.dart';

/// Пункт нижней навигации: раздел из [sidebarItems] под коротким именем —
/// «Соединения» в пять узких колонок не помещается.
class _Tab {
  const _Tab(this.index, this.label);

  /// Индекс раздела в [sidebarItems] — общий с десктопом, чтобы navIndex
  /// значил одно и то же в обоих каркасах.
  final int index;
  final String label;
}

/// Порядок вкладок на телефоне: самое частое — ближе к большому пальцу.
const _tabs = [
  _Tab(0, 'Главная'),
  _Tab(4, 'Роутинг'),
  _Tab(3, 'Сеть'),
  _Tab(2, 'Логи'),
  _Tab(1, 'Настройки'),
];

/// Каркас телефонного интерфейса (Android): разделы те же, что в сайдбаре
/// десктопа, но внизу экрана. «О приложении» открывается отдельной страницей
/// из настроек (openAboutPage).
class MobileShell extends StatefulWidget {
  const MobileShell({
    super.key,
    required this.controller,
    required this.deepLink,
    this.navIndex,
  });

  final AppController controller;
  final DeepLinkService deepLink;
  final ValueNotifier<int>? navIndex;

  @override
  State<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<MobileShell>
    with ShellEvents<MobileShell> {
  late int _index = _initialIndex();

  int _initialIndex() {
    final saved = widget.navIndex?.value ?? 0;
    return _tabs.any((t) => t.index == saved) ? saved : 0;
  }

  @override
  void initState() {
    super.initState();
    listenShellEvents(widget.controller, widget.deepLink);
  }

  @override
  void dispose() {
    cancelShellEvents();
    super.dispose();
  }

  Widget _screen(int index) {
    final c = widget.controller;
    return switch (index) {
      1 => SettingsScreen(controller: c),
      2 => LogsScreen(controller: c),
      3 => ConnectionsScreen(controller: c),
      4 => RoutingScreen(controller: c),
      _ => ProfilesScreen(controller: c),
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = VergePalette.of(context);
    return FormFactor(
      compact: true,
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final c = widget.controller;
          final hasUpdate = c.availableUpdate != null &&
              c.availableUpdate!.version != c.settings.skippedVersion;
          return Scaffold(
            backgroundColor: palette.panel,
            body: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Positioned.fill(child: _screen(_index)),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: UpdateBanner(controller: c),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: ValueListenableBuilder<List<ConnectionInfo>>(
              valueListenable: c.connections,
              builder: (context, conns, _) => _BottomBar(
                selected: _index,
                connectionCount: conns.length,
                settingsBadge: hasUpdate,
                onSelect: (i) => setState(() {
                  _index = i;
                  widget.navIndex?.value = i;
                }),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.selected,
    required this.onSelect,
    required this.connectionCount,
    required this.settingsBadge,
  });

  final int selected;
  final ValueChanged<int> onSelect;
  final int connectionCount;
  final bool settingsBadge;

  @override
  Widget build(BuildContext context) {
    final palette = VergePalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.chrome,
        border: Border(top: BorderSide(color: palette.panelBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              for (final tab in _tabs)
                Expanded(
                  child: _BottomItem(
                    icon: sidebarItems[tab.index].icon,
                    label: tab.label,
                    selected: tab.index == selected,
                    onTap: () => onSelect(tab.index),
                    badge: tab.index == connectionsIndex && connectionCount > 0
                        ? '$connectionCount'
                        : (tab.index == 1 && settingsBadge ? '' : null),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Текст метки над иконкой; пустая строка — просто точка, null — нет метки.
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final palette = VergePalette.of(context);
    final fg = selected ? theme.colorScheme.foreground : palette.navForeground;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 52,
                  height: 28,
                  decoration: BoxDecoration(
                    color: palette.navActive.withValues(alpha: selected ? 1 : 0),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: palette.navActiveRing
                          .withValues(alpha: selected ? 1 : 0),
                    ),
                  ),
                  child: Icon(icon, size: 18, color: fg),
                ),
                if (badge != null)
                  Positioned(
                    right: 4,
                    top: -3,
                    child: _Badge(text: badge!),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final accent = VergePalette.of(context).accent;
    if (text.isEmpty) {
      return Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFFFFFF),
        ),
      ),
    );
  }
}
