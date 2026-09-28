import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show CircularProgressIndicator;
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:shadcn_ui/shadcn_ui.dart';
import '../app/app_controller.dart';
import '../models/node_config.dart';
import '../models/node_engine.dart';
import '../models/profile.dart';
import '../models/subscription_info.dart';
import '../services/engine_selector.dart';
import '../services/link_opener.dart';
import '../services/node_display.dart';
import '../theme/app_theme.dart';
import '../theme/verge_palette.dart';
import 'auto_select_dialog.dart';
import 'widgets/engine_badge.dart';
import 'widgets/hero_panel.dart';
import 'widgets/paper.dart';
import 'add_profile_dialog.dart';
import 'edit_node_dialog.dart';

/// Диалог переименования профиля. После него имя считается ручным и больше
/// не перетирается profile-title из подписки.
void _showRenameDialog(BuildContext context, AppController c, Profile p) {
  final controller = TextEditingController(text: p.name);
  showShadDialog(
    context: context,
    builder: (ctx) => ShadDialog(
      title: const Text('Переименовать профиль'),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Отмена'),
        ),
        ShadButton(
          onPressed: () {
            c.renameProfile(p.id, controller.text);
            Navigator.of(ctx).pop();
          },
          child: const Text('Сохранить'),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: ShadInput(controller: controller, autofocus: true),
      ),
    ),
  ).then((_) => controller.dispose());
}

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
    // Любое изменение состояния контроллера может влиять на отображение
    // профилей (интервал, имя, ноды) — перестраиваемся.
    setState(() {});
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

  /// Ячейка задержки ноды: полоска + число, клик — перезамер.
  Widget _latencyCell(AppController c, NodeConfig node) {
    void reping() => c.pingNode(node);
    if (c.isPinging(node)) return const _LatencyCell.loading();
    final res = c.pingFor(node);
    if (res == null) return _LatencyCell(onTap: reping);
    if (res.latencyMs != null) {
      return _LatencyCell(latencyMs: res.latencyMs, onTap: reping);
    }
    return _LatencyCell(
        failure: res.timedOut ? 'таймаут' : 'ошибка', onTap: reping);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final theme = ShadTheme.of(context);

    return Padding(
      padding: kScreenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Фиксированная верхняя секция ---
          Row(
            children: [
              const Spacer(),
              IconAction(
                icon: LucideIcons.activity,
                tooltip: 'Пинг всех',
                onPressed: c.pingAll,
              ),
              const SizedBox(width: 8),
              IconAction(
                icon: LucideIcons.refreshCw,
                tooltip: 'Обновить подписки',
                onPressed: c.isRefreshingAll ? null : c.refreshAllProfiles,
              ),
              const SizedBox(width: 8),
              ShadButton(
                onPressed: () => showAddProfileDialog(context, c),
                leading: const Icon(LucideIcons.plus, size: 16),
                child: const Text('Добавить подписку'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          HeroPanel(controller: c),
          const SizedBox(height: 18),
          Row(
            children: [
              Text('Серверы',
                  style: theme.textTheme.large.copyWith(fontSize: 16)),
              const Spacer(),
              // Перебор занимает секунды и молча меняет выбранную ноду —
              // без индикатора он неотличим от неработающей кнопки.
              if (c.isAutoSelecting) ...[
                Text('Подбираем ноду…', style: theme.textTheme.muted),
                const SizedBox(width: 8),
              ],
              // Включённый автовыбор подсвечен кобальтом: состояние фичи
              // видно, не открывая диалог.
              _AutoSelectButton(controller: c),
            ],
          ),
          const SizedBox(height: 10),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final p in c.profiles)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ProfileCard(
                                header: _profileHeader(c, theme, p),
                                body: _profileBody(context, c, theme, p),
                                id: p.id,
                              ),
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
    final announce = p.subscriptionMeta?.announce;
    // Мета одной строкой: кол-во нод · трафик · срок.
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
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    const _ActiveBadge(),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                meta.join(' · '),
                style: theme.textTheme.muted.copyWith(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
              if (announce != null && announce.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(announce,
                    style: theme.textTheme.muted.copyWith(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
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
    if (nodes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text('В подписке нет серверов', style: theme.textTheme.muted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _NodeTableHeader(),
        for (var i = 0; i < nodes.length; i++)
          _NodeRow(
            node: nodes[i],
            selected:
                profileId == c.activeProfileId && p.selectedNodeIndex == i,
            onTap: () => c.selectNode(profileId, i),
            onPing: () => c.pingNode(nodes[i]),
            latency: _latencyCell(c, nodes[i]),
            choice: p.engineChoiceFor(nodes[i]),
            engine: _engineFor(c, p, nodes[i]),
            fellBack: _fellBack(c, p, nodes[i]),
            onEngineChoice: (choice) =>
                c.setNodeEngineChoice(profileId, nodes[i], choice),
            onEdit: () => showEditNodeDialog(
              context,
              c,
              profileId,
              i,
              nodes[i],
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

/// Карточка профиля: шапка (раскрывает список) и таблица нод.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.id,
    required this.header,
    required this.body,
  });

  final String id;
  final Widget header;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final palette = VergePalette.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.panel,
        border: Border.all(color: palette.panelBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ShadAccordion<String>.multiple(
        children: [
          ShadAccordionItem<String>(
            value: id,
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            underlineTitleOnHover: false,
            separator: const SizedBox.shrink(),
            title: header,
            child: body,
          ),
        ],
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    final palette = VergePalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: palette.accent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'активен',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFFFFFFFF),
        ),
      ),
    );
  }
}

// Колонки таблицы нод — общие для шапки и строк, чтобы стояли ровно.
const _kRadioWidth = 30.0;
const _kEngineWidth = 44.0;
const _kLatencyWidth = 136.0;
const _kMenuWidth = 32.0;

class _NodeTableHeader extends StatelessWidget {
  const _NodeTableHeader();

  @override
  Widget build(BuildContext context) {
    final style = ShadTheme.of(context).textTheme.muted.copyWith(fontSize: 12);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(color: VergePalette.of(context).divider)),
      ),
      child: Row(
        children: [
          const SizedBox(width: _kRadioWidth),
          Expanded(flex: 16, child: Text('Сервер', style: style)),
          Expanded(flex: 11, child: Text('Протокол', style: style)),
          SizedBox(width: _kEngineWidth, child: Text('Движок', style: style)),
          const SizedBox(width: 12),
          SizedBox(
              width: _kLatencyWidth, child: Text('Задержка', style: style)),
          const SizedBox(width: _kMenuWidth),
        ],
      ),
    );
  }
}

/// Строка ноды: радио выбора, код страны и имя (под ним адрес), протокол,
/// движок, задержка полоской и числом, меню.
class _NodeRow extends StatefulWidget {
  const _NodeRow({
    required this.node,
    required this.selected,
    required this.onTap,
    required this.onPing,
    required this.latency,
    required this.choice,
    required this.engine,
    required this.fellBack,
    required this.onEngineChoice,
    required this.onEdit,
  });

  final NodeConfig node;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onPing;
  final Widget latency;

  /// Что выбрал пользователь; auto — движок определяет автоматика.
  final EngineChoice choice;

  /// Что показываем в бейдже: план для неактивных нод, факт для активной.
  final NodeEngine engine;
  final bool fellBack;
  final ValueChanged<EngineChoice> onEngineChoice;
  final VoidCallback onEdit;

  @override
  State<_NodeRow> createState() => _NodeRowState();
}

class _NodeRowState extends State<_NodeRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final palette = VergePalette.of(context);
    final dark = theme.brightness == Brightness.dark;
    final node = widget.node;
    final selected = widget.selected;
    final name = splitCountryFlag(node.name);
    final radioOn = dark ? palette.accentText : palette.accent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
          decoration: BoxDecoration(
            color: selected
                ? palette.accentSoft
                : _hovered
                    ? palette.surfaceHeader
                    : palette.panel,
            border: Border(top: BorderSide(color: palette.divider)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: _kRadioWidth,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? radioOn : palette.radioOff,
                        width: selected ? 5 : 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 16,
                child: Row(
                  children: [
                    if (name.code != null) ...[
                      CountryChip(name.code!),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${node.host}:${node.port}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.muted.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 11,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    nodeProtocolLabel(node),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.muted.copyWith(fontSize: 13),
                  ),
                ),
              ),
              SizedBox(
                width: _kEngineWidth,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: EngineBadge(
                    engine: widget.engine,
                    manual: widget.choice != EngineChoice.auto,
                    fellBack: widget.fellBack,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(width: _kLatencyWidth, child: widget.latency),
              SizedBox(
                width: _kMenuWidth,
                child: _NodeMenu(
                  choice: widget.choice,
                  autoEngine:
                      preferXray(node) ? NodeEngine.xray : NodeEngine.singbox,
                  onEngineChoice: widget.onEngineChoice,
                  onPing: widget.onPing,
                  onEdit: widget.onEdit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Задержка ноды: полоска длиной по шкале до 500 мс и число цветом порога.
/// Без замера — приглушённое «—», по которому можно кликнуть.
class _LatencyCell extends StatelessWidget {
  const _LatencyCell({this.latencyMs, this.failure, this.onTap})
      : loading = false;
  const _LatencyCell.loading()
      : latencyMs = null,
        failure = null,
        onTap = null,
        loading = true;

  final int? latencyMs;
  final String? failure;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final palette = VergePalette.of(context);
    final theme = ShadTheme.of(context);
    final ms = latencyMs;
    final Widget content;
    if (loading) {
      content = const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else {
      final fraction = ms != null
          ? (ms / 500).clamp(0.06, 1.0)
          : failure != null
              ? 1.0
              : 0.0;
      final barColor = ms != null
          ? palette.latencyBar(ms)
          : failure != null
              ? palette.panelBorder
              : palette.chip;
      final label = ms != null ? '$ms мс' : (failure ?? '—');
      final labelColor = ms != null
          ? palette.latencyText(ms)
          : failure != null
              ? palette.dangerText
              : theme.colorScheme.mutedForeground;
      content = Row(
        children: [
          Container(
            width: 56,
            height: 6,
            decoration: BoxDecoration(
              color: palette.chip,
              borderRadius: BorderRadius.circular(3),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fraction.toDouble(),
              child: Container(
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: monoStyle(fontSize: 12, color: labelColor),
            ),
          ),
        ],
      );
    }
    return MouseRegion(
      cursor:
          onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Align(alignment: Alignment.centerLeft, child: content),
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
    required this.onEdit,
  });

  final EngineChoice choice;

  /// Что выбрала бы автоматика — показываем в подписи пункта «Авто».
  final NodeEngine autoEngine;
  final ValueChanged<EngineChoice> onEngineChoice;
  final VoidCallback onPing;
  final VoidCallback onEdit;

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
          leading: const Icon(LucideIcons.pencil, size: 16),
          onPressed: () => act(widget.onEdit),
          child: const Text('Редактировать'),
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
        if (p.subscriptionMeta?.webPageUrl != null)
          ShadContextMenuItem(
            leading: const Icon(LucideIcons.externalLink, size: 16),
            onPressed: () =>
                act(() => openLink(p.subscriptionMeta!.webPageUrl!)),
            child: const Text('Личный кабинет'),
          ),
        if (p.subscriptionMeta?.supportUrl != null)
          ShadContextMenuItem(
            leading: const Icon(LucideIcons.lifeBuoy, size: 16),
            onPressed: () =>
                act(() => openLink(p.subscriptionMeta!.supportUrl!)),
            child: const Text('Поддержка'),
          ),
        ShadContextMenuItem(
          leading: const Icon(LucideIcons.timer, size: 16),
          onPressed: () => act(() => _editRefreshInterval(context, c, p)),
          trailing: Text(_refreshLabel(p), style: theme.textTheme.muted),
          child: const Text('Автообновление'),
        ),
        ShadContextMenuItem(
          leading: const Icon(LucideIcons.pencil, size: 16),
          onPressed: () => act(() => _showRenameDialog(context, c, p)),
          child: const Text('Переименовать'),
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

/// Кнопка автовыбора. Залита, когда фича включена и есть отмеченные
/// профили, — иначе включённое состояние никак не отличить от выключенного.
class _AutoSelectButton extends StatelessWidget {
  const _AutoSelectButton({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final on = c.autoSelect.isActive;
    final leading = c.isAutoSelecting
        ? const SizedBox(width: 14, height: 14, child: ShadProgress())
        : const Icon(LucideIcons.zap, size: 14);
    final label = Text(on ? 'Автовыбор: вкл' : 'Автовыбор');
    void open() => showAutoSelectDialog(context, c);
    return on
        ? ShadButton(
            size: ShadButtonSize.sm,
            onPressed: open,
            leading: leading,
            child: label,
          )
        : ShadButton.outline(
            size: ShadButtonSize.sm,
            onPressed: open,
            leading: leading,
            child: label,
          );
  }
}

/// Полупрозрачные градиенты сверху/снизу прокручиваемой области — визуальный
/// намёк, что секция скроллится. Не перехватывает жесты (IgnorePointer).
///
/// Фейд гаснет там, где скроллить уже некуда: в самом верху нет верхнего, в
/// самом низу — нижнего, а если контент вовсе не прокручивается, нет обоих.
/// Прозрачность считается из запаса прокрутки, поэтому переход плавный сам по
/// себе и отдельная анимация не нужна.
class _ScrollFadeShadow extends StatefulWidget {
  const _ScrollFadeShadow({required this.child, required this.color});
  final Widget child;
  final Color color;

  @override
  State<_ScrollFadeShadow> createState() => _ScrollFadeShadowState();
}

class _ScrollFadeShadowState extends State<_ScrollFadeShadow> {
  static const _height = 14.0;

  double _top = 0;
  double _bottom = 0;

  void _apply(ScrollMetrics m) {
    final top = (m.extentBefore / _height).clamp(0.0, 1.0);
    final bottom = (m.extentAfter / _height).clamp(0.0, 1.0);
    if (top == _top && bottom == _bottom) return;
    setState(() {
      _top = top;
      _bottom = bottom;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    Widget fade(double opacity, Alignment begin, Alignment end) => IgnorePointer(
          child: Opacity(
            opacity: opacity,
            child: Container(
              height: _height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: begin,
                  end: end,
                  colors: [color, color.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        );
    // Два слушателя: ScrollUpdateNotification ловит саму прокрутку, а
    // ScrollMetricsNotification — изменение размеров контента (профиль
    // раскрыли/добавили), в том числе первую раскладку. Второй не является
    // ScrollNotification, поэтому одним NotificationListener не обойтись.
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) {
        _apply(n.metrics);
        return false;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          _apply(n.metrics);
          return false;
        },
        child: Stack(
          children: [
            Positioned.fill(child: widget.child),
            Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: fade(_top, Alignment.topCenter, Alignment.bottomCenter)),
            Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child:
                    fade(_bottom, Alignment.bottomCenter, Alignment.topCenter)),
          ],
        ),
      ),
    );
  }
}

/// Человекочитаемое состояние автообновления профиля. Единица измерения —
/// часы: провайдеры присылают интервал именно в часах, и минуты здесь дают
/// ложную точность.
String _refreshLabel(Profile p) {
  final own = p.refreshIntervalMinutesOverride;
  if (own != null && own > 0) return 'Своё: ${_asHours(own)} ч';
  final hours = p.subscriptionMeta?.updateIntervalHours;
  if (hours != null && hours > 0) return 'По подписке: $hours ч';
  return 'Выключено';
}

/// Хранение в минутах, показ в часах. Округляем вверх, чтобы интервал,
/// записанный старой версией приложения, не превратился в «0 ч».
int _asHours(int minutes) => (minutes / 60).ceil().clamp(1, 1 << 30);

/// Диалог выбора интервала в часах. Пустое поле = снять оверрайд.
Future<void> _editRefreshInterval(
    BuildContext context, AppController c, Profile p) async {
  final own = p.refreshIntervalMinutesOverride;
  final ctrl = TextEditingController(
    text: (own != null && own > 0) ? '${_asHours(own)}' : '',
  );
  final result = await showShadDialog<String?>(
    context: context,
    builder: (ctx) => ShadDialog(
      title: const Text('Интервал автообновления'),
      constraints: const BoxConstraints(maxWidth: 380),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(ctx).pop(null),
          child: const Text('Отмена'),
        ),
        ShadButton(
          onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
          child: const Text('Сохранить'),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShadInput(
            controller: ctrl,
            placeholder: const Text('Часы'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          Text(
            p.subscriptionMeta?.updateIntervalHours != null
                ? 'Пусто — использовать интервал из подписки '
                    '(${p.subscriptionMeta!.updateIntervalHours} ч)'
                : 'Пусто — не обновлять автоматически',
            style: ShadTheme.of(ctx).textTheme.muted,
          ),
        ],
      ),
    ),
  );
  if (result == null) return;
  final hours = result.isEmpty ? null : int.tryParse(result);
  // Мусор в поле трактуем как «не менять»: молча ставить null было бы хуже.
  if (result.isNotEmpty && (hours == null || hours < 1)) return;
  await c.setProfileRefreshInterval(p.id, hours == null ? null : hours * 60);
}
