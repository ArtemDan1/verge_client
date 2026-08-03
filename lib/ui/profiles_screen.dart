import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:shadcn_ui/shadcn_ui.dart';
import '../app/app_controller.dart';
import '../models/node_config.dart';
import '../models/node_engine.dart';
import '../models/profile.dart';
import '../models/subscription_info.dart';
import '../services/engine_selector.dart';
import 'widgets/engine_badge.dart';
import 'widgets/hero_panel.dart';
import 'widgets/ping_badge.dart';
import 'add_profile_dialog.dart';

class ProfilesScreen extends StatefulWidget {
  final AppController controller;
  const ProfilesScreen({super.key, required this.controller});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  bool _wasRefreshing = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(ProfilesScreen old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    final c = widget.controller;
    // Завершение обновления подписок → уведомление.
    if (_wasRefreshing && !c.isRefreshingAll) {
      _wasRefreshing = false;
      final err = c.refreshError;
      if (err == null) {
        ShadToaster.of(context)
            .show(const ShadToast(description: Text('Подписки обновлены')));
      } else {
        ShadToaster.of(context)
            .show(ShadToast.destructive(description: Text(err)));
        c.clearRefreshError();
      }
    } else if (c.isRefreshingAll) {
      _wasRefreshing = true;
    }
  }

  static String _fmtBytes(int bytes) {
    const units = ['Б', 'КБ', 'МБ', 'ГБ', 'ТБ'];
    var v = bytes.toDouble();
    var i = 0;
    while (v >= 1024 && i < units.length - 1) {
      v /= 1024;
      i++;
    }
    final s = v >= 100 || i == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    return '$s ${units[i]}';
  }

  String? _trafficLine(SubscriptionInfo? info) {
    if (info == null) return null;
    final used = info.used;
    final total = info.total;
    final parts = <String>[];
    if (used != null && total != null && total > 0) {
      parts.add('Использовано ${_fmtBytes(used)} из ${_fmtBytes(total)}');
      final rem = info.remaining;
      if (rem != null) parts.add('осталось ${_fmtBytes(rem)}');
    } else if (used != null) {
      parts.add('Использовано ${_fmtBytes(used)}');
    }
    final exp = info.expire;
    if (exp != null) {
      parts.add(
          'до ${exp.day.toString().padLeft(2, '0')}.${exp.month.toString().padLeft(2, '0')}.${exp.year}');
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  Widget _pingBadge(AppController c, NodeConfig node) {
    if (c.isPinging(node)) return const PingBadge(loading: true);
    final res = c.pingFor(node);
    if (res == null) return const PingBadge();
    if (res.latencyMs != null) return PingBadge(latencyMs: res.latencyMs);
    return PingBadge(timedOut: res.timedOut, error: !res.timedOut);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final theme = ShadTheme.of(context);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Фиксированная верхняя секция ---
          Row(
            children: [
              ShadButton(
                onPressed: () => showAddProfileDialog(context, c),
                leading: const Icon(LucideIcons.plus, size: 16),
                child: const Text('Добавить'),
              ),
              const Spacer(),
              ShadButton.outline(
                onPressed: c.isRefreshingAll ? null : c.refreshAllProfiles,
                leading: const Icon(LucideIcons.refreshCw, size: 16),
                child: const Text('Обновить подписки'),
              ),
              const SizedBox(width: 8),
              ShadButton.outline(
                onPressed: c.pingAll,
                leading: const Icon(LucideIcons.radar, size: 16),
                child: const Text('Пинг всех'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          HeroPanel(controller: c),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Профили', style: theme.textTheme.large),
          ),
          const SizedBox(height: 6),
          // --- Прокручиваемая секция профилей ---
          Expanded(
            child: c.profiles.isEmpty
                ? Center(
                    child: Text('Нет подписок. Добавьте первую.',
                        style: theme.textTheme.muted),
                  )
                : _ScrollFadeShadow(
                    color: theme.colorScheme.background,
                    child: SingleChildScrollView(
                      child: ShadAccordion<String>.multiple(
                        children: [
                          for (final p in c.profiles)
                            ShadAccordionItem<String>(
                              value: p.id,
                              title: _profileHeader(c, theme, p),
                              child: _profileBody(context, c, theme, p),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _profileHeader(AppController c, ShadThemeData theme, Profile p) {
    final isActive = p.id == c.activeProfileId;
    // Мета одной строкой: кол-во нод · трафик · срок (как в макете).
    final meta = <String>['${p.nodes.length} нод'];
    final traffic = _trafficLine(p.subscriptionInfo);
    if (traffic != null) meta.add(traffic);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(p.name,
                        style: theme.textTheme.large,
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    const ShadBadge(child: Text('активен')),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                meta.join(' · '),
                style: theme.textTheme.muted,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // «...»-меню действий профиля. Останавливаем всплытие тапа, чтобы
        // клик по кнопке не сворачивал/раскрывал аккордеон.
        const SizedBox(width: 8),
        _ProfileMenu(controller: c, profile: p),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _profileBody(
      BuildContext context, AppController c, ShadThemeData theme, Profile p) {
    final nodes = p.nodes;
    final profileId = p.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < nodes.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == nodes.length - 1 ? 0 : 8),
            child: _NodeRow(
              node: nodes[i],
              selected: profileId == c.activeProfileId &&
                  p.selectedNodeIndex == i,
              onTap: () => c.selectNode(profileId, i),
              onPing: () => c.pingNode(nodes[i]),
              pingBadge: _pingBadge(c, nodes[i]),
              choice: p.engineChoiceFor(nodes[i]),
              engine: _engineFor(c, p, nodes[i]),
              fellBack: _fellBack(c, p, nodes[i]),
              onEngineChoice: (choice) =>
                  c.setNodeEngineChoice(profileId, nodes[i], choice),
            ),
          ),
      ],
    );
  }

  /// Активная ли это нода на живом подключении. Только у неё бейдж показывает
  /// ФАКТ (движок, на котором реально работаем), у остальных — план.
  bool _isLiveNode(AppController c, Profile p, NodeConfig node) {
    final active = c.selectedNode;
    return active != null &&
        p.id == c.activeProfileId &&
        nodeEngineKey(active) == nodeEngineKey(node) &&
        c.activeEngine != null;
  }

  NodeEngine _engineFor(AppController c, Profile p, NodeConfig node) =>
      _isLiveNode(c, p, node)
          ? c.activeEngine!
          : resolveEngine(node, p.engineChoiceFor(node));

  /// Планировали Xray, а работаем на sing-box — сработал автофолбэк.
  bool _fellBack(AppController c, Profile p, NodeConfig node) =>
      _isLiveNode(c, p, node) &&
      resolveEngine(node, p.engineChoiceFor(node)) == NodeEngine.xray &&
      c.activeEngine == NodeEngine.singbox;
}

/// Строка ноды: тёмный кружок-галочка у активной, имя жирным, под ним
/// протокол·хост:порт, справа — пинг и кнопка перепинговки.
class _NodeRow extends StatelessWidget {
  const _NodeRow({
    required this.node,
    required this.selected,
    required this.onTap,
    required this.onPing,
    required this.pingBadge,
    required this.choice,
    required this.engine,
    required this.fellBack,
    required this.onEngineChoice,
  });

  final NodeConfig node;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onPing;
  final Widget pingBadge;

  /// Что выбрал пользователь; auto — движок определяет автоматика.
  final EngineChoice choice;

  /// Что показываем в бейдже: план для неактивных нод, факт для активной.
  final NodeEngine engine;
  final bool fellBack;
  final ValueChanged<EngineChoice> onEngineChoice;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: ShadCard(
        backgroundColor: theme.colorScheme.muted,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Кружок-индикатор выбора: залитый тёмным с белой галочкой у
            // активной ноды, пустой контур — у остальных.
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? theme.colorScheme.primary : null,
                border: selected
                    ? null
                    : Border.all(color: theme.colorScheme.border, width: 1.5),
              ),
              alignment: Alignment.center,
              child: selected
                  ? Icon(LucideIcons.check,
                      size: 15, color: theme.colorScheme.primaryForeground)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(node.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 1),
                  Text(
                    '${node.protocol.name} · ${node.host}:${node.port}',
                    style: theme.textTheme.muted,
                  ),
                ],
              ),
            ),
            pingBadge,
            const SizedBox(width: 6),
            EngineBadge(
              engine: engine,
              manual: choice != EngineChoice.auto,
              fellBack: fellBack,
            ),
            const SizedBox(width: 2),
            _NodeMenu(
              choice: choice,
              autoEngine:
                  preferXray(node) ? NodeEngine.xray : NodeEngine.singbox,
              onEngineChoice: onEngineChoice,
              onPing: onPing,
            ),
          ],
        ),
      ),
    );
  }
}

/// Меню ноды: выбор движка и пинг. Точка роста для будущих настроек ноды.
class _NodeMenu extends StatefulWidget {
  const _NodeMenu({
    required this.choice,
    required this.autoEngine,
    required this.onEngineChoice,
    required this.onPing,
  });

  final EngineChoice choice;

  /// Что выбрала бы автоматика — показываем в подписи пункта «Авто».
  final NodeEngine autoEngine;
  final ValueChanged<EngineChoice> onEngineChoice;
  final VoidCallback onPing;

  @override
  State<_NodeMenu> createState() => _NodeMenuState();
}

class _NodeMenuState extends State<_NodeMenu> {
  final _menu = ShadPopoverController();

  @override
  void dispose() {
    _menu.dispose();
    super.dispose();
  }

  String get _autoLabel =>
      'Авто (${widget.autoEngine == NodeEngine.xray ? 'Xray' : 'sing-box'})';

  @override
  Widget build(BuildContext context) {
    void act(VoidCallback f) {
      _menu.hide();
      f();
    }

    ShadContextMenuItem engineItem(String label, EngineChoice value) =>
        ShadContextMenuItem(
          leading: Icon(
            LucideIcons.check,
            size: 16,
            // Галочку держим всегда, но у невыбранных прячем прозрачностью:
            // так пункты меню не «прыгают» по горизонтали.
            color: widget.choice == value ? null : const Color(0x00000000),
          ),
          onPressed: () => act(() => widget.onEngineChoice(value)),
          child: Text(label),
        );

    return ShadContextMenu(
      controller: _menu,
      anchor: const ShadAnchor(
        childAlignment: Alignment.bottomRight,
        overlayAlignment: Alignment.topRight,
      ),
      items: [
        engineItem(_autoLabel, EngineChoice.auto),
        engineItem('Xray', EngineChoice.xray),
        engineItem('sing-box', EngineChoice.singbox),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: ShadSeparator.horizontal(margin: EdgeInsets.zero),
        ),
        ShadContextMenuItem(
          leading: const Icon(LucideIcons.radar, size: 16),
          onPressed: () => act(widget.onPing),
          child: const Text('Пинг'),
        ),
      ],
      child: ShadButton.ghost(
        width: 32,
        height: 32,
        padding: EdgeInsets.zero,
        onPressed: _menu.toggle,
        child: const Icon(LucideIcons.ellipsis, size: 18),
      ),
    );
  }
}

/// «...»-меню действий профиля (Обновить · Пинг · Подписка · Удалить),
/// открывается кнопкой в шапке карточки, не задевая аккордеон.
class _ProfileMenu extends StatefulWidget {
  const _ProfileMenu({required this.controller, required this.profile});
  final AppController controller;
  final Profile profile;

  @override
  State<_ProfileMenu> createState() => _ProfileMenuState();
}

class _ProfileMenuState extends State<_ProfileMenu> {
  final _menu = ShadPopoverController();

  @override
  void dispose() {
    _menu.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final p = widget.profile;
    final theme = ShadTheme.of(context);

    void act(VoidCallback f) {
      _menu.hide();
      f();
    }

    return ShadContextMenu(
      controller: _menu,
      anchor: const ShadAnchor(
        childAlignment: Alignment.bottomRight,
        overlayAlignment: Alignment.topRight,
      ),
      items: [
        ShadContextMenuItem(
          leading: const Icon(LucideIcons.refreshCw, size: 16),
          onPressed: () => act(() => c.refreshProfile(p.id)),
          child: const Text('Обновить'),
        ),
        ShadContextMenuItem(
          leading: const Icon(LucideIcons.radar, size: 16),
          onPressed: () => act(() => c.pingProfile(p.id)),
          child: const Text('Пинг'),
        ),
        ShadContextMenuItem(
          leading: const Icon(LucideIcons.link, size: 16),
          onPressed: () => act(() async {
            await Clipboard.setData(ClipboardData(text: p.url));
            if (!context.mounted) return;
            ShadToaster.of(context).show(
              const ShadToast(
                  description: Text('Ссылка на подписку скопирована')),
            );
          }),
          child: const Text('Подписка'),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: ShadSeparator.horizontal(margin: EdgeInsets.zero),
        ),
        ShadContextMenuItem(
          leading: Icon(LucideIcons.trash2,
              size: 16, color: theme.colorScheme.destructive),
          onPressed: () => act(() => c.removeProfile(p.id)),
          child: Text('Удалить',
              style: TextStyle(color: theme.colorScheme.destructive)),
        ),
      ],
      child: ShadButton.ghost(
        width: 32,
        height: 32,
        padding: EdgeInsets.zero,
        onPressed: _menu.toggle,
        child: const Icon(LucideIcons.ellipsis, size: 18),
      ),
    );
  }
}

/// Полупрозрачные градиенты сверху/снизу прокручиваемой области — визуальный
/// намёк, что секция скроллится. Не перехватывает жесты (IgnorePointer).
class _ScrollFadeShadow extends StatelessWidget {
  const _ScrollFadeShadow({required this.child, required this.color});
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    Widget fade(Alignment begin, Alignment end) => IgnorePointer(
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: begin,
                end: end,
                colors: [color, color.withValues(alpha: 0)],
              ),
            ),
          ),
        );
    return Stack(
      children: [
        Positioned.fill(child: child),
        Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: fade(Alignment.topCenter, Alignment.bottomCenter)),
        Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: fade(Alignment.bottomCenter, Alignment.topCenter)),
      ],
    );
  }
}
