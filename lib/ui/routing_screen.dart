import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../app/app_controller.dart';
import '../models/routing_profile.dart';
import '../models/routing_rule.dart';
import '../services/geo_catalog.dart';
import '../theme/verge_palette.dart';
import 'widgets/paper.dart';

/// Роутинг: карточки профилей сверху, под ними — правила выбранного.
///
/// Выбор карточки только открывает профиль; активным он становится по
/// кнопке «Использовать». Иначе клик по новому пустому профилю молча менял бы
/// маршрутизацию живого подключения.
class RoutingScreen extends StatefulWidget {
  final AppController controller;
  const RoutingScreen({super.key, required this.controller});

  @override
  State<RoutingScreen> createState() => _RoutingScreenState();
}

class _RoutingScreenState extends State<RoutingScreen> {
  String? _viewId;

  AppController get controller => widget.controller;

  /// Открытый профиль: выбранный пользователем, иначе активный, иначе первый.
  RoutingProfile? get _viewed {
    final all = controller.routingProfiles;
    if (all.isEmpty) return null;
    for (final id in [_viewId, controller.activeRoutingProfileId]) {
      if (id == null) continue;
      for (final p in all) {
        if (p.id == id) return p;
      }
    }
    return all.first;
  }

  Future<void> _add() async {
    final p = await controller.addRoutingProfile('Новый профиль');
    if (mounted) setState(() => _viewId = p.id);
  }

  Future<void> _clone(RoutingProfile p) async {
    final copy = await controller.cloneRoutingProfile(p.id);
    if (mounted) setState(() => _viewId = copy.id);
  }

  Future<void> _remove(RoutingProfile p) async {
    await controller.removeRoutingProfile(p.id);
    if (mounted) setState(() => _viewId = null);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final viewed = _viewed;
        return SingleChildScrollView(
          padding: kScreenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreenHeader(
                title: 'Роутинг',
                subtitle: _geoStatus(context),
                actions: [
                  if (controller.canUpdateGeo)
                    ShadButton.outline(
                      onPressed: controller.isUpdatingGeo
                          ? null
                          : () => controller.updateGeoAssets(),
                      leading: controller.isUpdatingGeo
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: ShadProgress(),
                            )
                          : const Icon(LucideIcons.cloudDownload, size: 16),
                      child: const Text('Обновить гео'),
                    ),
                  ShadButton(
                    onPressed: _add,
                    leading: const Icon(LucideIcons.plus, size: 16),
                    child: const Text('Профиль'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                // Три карточки в ряд на обычной ширине окна, две — на узкой.
                builder: (context, box) => _EqualRows(
                  columns: box.maxWidth > 640 ? 3 : 2,
                  gap: 12,
                  children: [
                    for (final p in controller.routingProfiles)
                      _ProfileCard(
                        profile: p,
                        viewed: p.id == viewed?.id,
                        active: p.id == controller.activeRoutingProfileId,
                        onTap: () => setState(() => _viewId = p.id),
                      ),
                  ],
                ),
              ),
              if (viewed != null) ...[
                const SizedBox(height: 26),
                _Editor(
                  controller: controller,
                  profile: viewed,
                  onClone: () => _clone(viewed),
                  onRemove: () => _remove(viewed),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _geoStatus(BuildContext context) {
    if (!controller.canUpdateGeo) {
      return const Text('Что идёт через VPN, что напрямую, а что блокируется');
    }
    final at = controller.geoUpdatedAt;
    final err = controller.geoUpdateError;
    final subtitle =
        err ??
        (at == null
            ? 'ещё не обновлялись — вшитые версии'
            : 'обновлены ${_ago(at)}');
    return Text(
      'Гео-наборы (.srs): $subtitle',
      style: err != null
          ? TextStyle(color: VergePalette.of(context).dangerText)
          : null,
    );
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'только что';
    if (d.inHours < 1) return '${d.inMinutes} мин назад';
    if (d.inDays < 1) return '${d.inHours} ч назад';
    return '${d.inDays} дн назад';
  }
}

/// Число правил профиля во всех группах.
int _ruleCount(RoutingProfile p) =>
    p.allowRules.length +
    p.directRules.length +
    p.proxyRules.length +
    p.blockRules.length;

String _rulesWord(int n) {
  final mod10 = n % 10, mod100 = n % 100;
  if (mod10 == 1 && mod100 != 11) return 'правило';
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return 'правила';
  }
  return 'правил';
}

/// Подпись карточки: чей профиль и что он делает с остальным трафиком.
String _cardSubtitle(RoutingProfile p) {
  final n = _ruleCount(p);
  final rest = p.finalAction == RoutingFinal.direct
      ? 'остальное напрямую'
      : 'остальное через VPN';
  final kind = p.isBuiltIn ? 'Встроенный' : 'Свой';
  return n == 0
      ? '$kind · всё через ${p.finalAction == RoutingFinal.direct ? 'прямое соединение' : 'VPN'}'
      : '$kind · $n ${_rulesWord(n)} · $rest';
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.viewed,
    required this.active,
    required this.onTap,
  });

  final RoutingProfile profile;
  final bool viewed;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final palette = VergePalette.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ring = dark ? palette.accentText : palette.accent;
    final p = profile;
    return Semantics(
      button: true,
      selected: viewed,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.all(viewed ? 15 : 16),
            decoration: BoxDecoration(
              color: viewed ? palette.accentSoft : palette.panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: viewed ? ring : palette.panelBorder,
                width: viewed ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RuleMixBar(profile: p),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        p.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (active) ...[
                      const SizedBox(width: 8),
                      const _ActiveBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (p.isBuiltIn) ...[
                      Icon(
                        LucideIcons.lock,
                        size: 12,
                        color: theme.colorScheme.mutedForeground,
                      ),
                      const SizedBox(width: 5),
                    ],
                    Expanded(
                      child: Text(
                        _cardSubtitle(p),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.muted.copyWith(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: VergePalette.of(context).accent,
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

/// Правила открытого профиля: четыре группы сеткой 2×2 и действие для
/// остального трафика. Встроенные профили — только для чтения.
class _Editor extends StatelessWidget {
  const _Editor({
    required this.controller,
    required this.profile,
    required this.onClone,
    required this.onRemove,
  });

  final AppController controller;
  final RoutingProfile profile;
  final VoidCallback onClone;
  final VoidCallback onRemove;

  void _save(RoutingProfile updated) =>
      controller.updateRoutingProfile(updated);

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final palette = VergePalette.of(context);
    final p = profile;
    final editable = !p.isBuiltIn;
    final active = p.id == controller.activeRoutingProfileId;
    final exceptions = theme.brightness == Brightness.dark
        ? const Color(0xFFA58BF0)
        : const Color(0xFF7C5CD6);

    final groups = [
      _RuleGroup(
        title: 'Через VPN',
        color: palette.accent,
        rules: p.proxyRules,
        editable: editable,
        onChanged: (r) => _save(p.copyWith(proxyRules: r)),
      ),
      _RuleGroup(
        title: 'Напрямую',
        color: palette.success,
        rules: p.directRules,
        editable: editable,
        onChanged: (r) => _save(p.copyWith(directRules: r)),
      ),
      _RuleGroup(
        title: 'Блокировать',
        color: palette.danger,
        rules: p.blockRules,
        editable: editable,
        onChanged: (r) => _save(p.copyWith(blockRules: r)),
      ),
      _RuleGroup(
        title: 'Исключения (важнее блока)',
        color: exceptions,
        rules: p.allowRules,
        editable: editable,
        onChanged: (r) => _save(p.copyWith(allowRules: r)),
        footer: Row(
          children: [
            Expanded(
              child: Text(
                'Исключения идут',
                style: theme.textTheme.muted.copyWith(fontSize: 12),
              ),
            ),
            SizedBox(
              width: 190,
              child: Segmented<RoutingFinal>(
                value: p.allowAction,
                height: 30,
                onChanged: editable
                    ? (v) => _save(p.copyWith(allowAction: v))
                    : null,
                options: const [
                  SegmentedOption(
                    value: RoutingFinal.proxy,
                    label: 'через VPN',
                  ),
                  SegmentedOption(
                    value: RoutingFinal.direct,
                    label: 'напрямую',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (editable)
              _HeaderAction(
                icon: LucideIcons.pencil,
                tooltip: 'Переименовать',
                onPressed: () => _rename(context),
              ),
            _HeaderAction(
              icon: LucideIcons.copy,
              tooltip: 'Дублировать',
              onPressed: onClone,
            ),
            if (editable)
              _HeaderAction(
                icon: LucideIcons.trash2,
                tooltip: 'Удалить',
                color: palette.dangerText,
                onPressed: onRemove,
              ),
            const Spacer(),
            if (!active)
              ShadButton.outline(
                size: ShadButtonSize.sm,
                onPressed: () => controller.selectRoutingProfile(p.id),
                child: const Text('Использовать'),
              ),
          ],
        ),
        if (!editable) ...[
          const SizedBox(height: 6),
          Text(
            'Встроенный профиль не меняется — дублируйте его, чтобы настроить '
            'правила под себя.',
            style: theme.textTheme.muted.copyWith(fontSize: 13),
          ),
        ],
        const SizedBox(height: 12),
        _EqualRows(columns: 2, gap: 10, children: groups),
        const SizedBox(height: 10),
        // Итоговое действие — отдельной строкой под группами: в шапке рядом
        // с именем и кнопками ему не хватало места.
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          decoration: BoxDecoration(
            color: palette.surfaceHeader,
            border: Border.all(color: palette.divider),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Всё, что не попало в правила',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(
                width: 220,
                child: Segmented<RoutingFinal>(
                  value: p.finalAction,
                  height: 32,
                  onChanged:
                      editable ? (v) => _save(p.copyWith(finalAction: v)) : null,
                  options: const [
                    SegmentedOption(
                        value: RoutingFinal.proxy, label: 'через VPN'),
                    SegmentedOption(
                        value: RoutingFinal.direct, label: 'напрямую'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _rename(BuildContext context) async {
    final ctrl = TextEditingController(text: profile.name);
    final name = await showShadDialog<String>(
      context: context,
      builder: (ctx) => ShadDialog(
        title: const Text('Переименовать профиль'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          ShadButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Сохранить'),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: ShadInput(controller: ctrl, autofocus: true),
        ),
      ),
    );
    ctrl.dispose();
    if (name != null && name.isNotEmpty) _save(profile.copyWith(name: name));
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: ShadTooltip(
      builder: (_) => Text(tooltip),
      child: ShadButton.ghost(
        width: 30,
        height: 30,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Icon(icon, size: 15, color: color),
      ),
    ),
  );
}

/// Группа правил: цветной маркер, заголовок, кнопка добавления, чипы.
class _RuleGroup extends StatelessWidget {
  const _RuleGroup({
    required this.title,
    required this.color,
    required this.rules,
    required this.editable,
    required this.onChanged,
    this.footer,
  });

  final String title;
  final Color color;
  final List<RoutingRule> rules;
  final bool editable;
  final ValueChanged<List<RoutingRule>> onChanged;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final palette = VergePalette.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceHeader,
        border: Border.all(color: palette.divider),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (editable)
                _AddRuleButton(onAdd: (r) => onChanged([...rules, r])),
            ],
          ),
          const SizedBox(height: 10),
          if (rules.isEmpty)
            Text('Пусто', style: theme.textTheme.muted.copyWith(fontSize: 12))
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final r in rules)
                  _RuleChip(
                    label: _ruleLabel(r),
                    onDelete: editable
                        ? () => onChanged(rules.where((x) => x != r).toList())
                        : null,
                  ),
              ],
            ),
          if (footer != null) ...[const SizedBox(height: 12), footer!],
        ],
      ),
    );
  }
}

String _ruleLabel(RoutingRule r) {
  if (r.kind == RoutingRuleKind.geo) {
    return geoCategoryByTag(r.value)?.label ?? r.value;
  }
  return r.value;
}

class _RuleChip extends StatelessWidget {
  const _RuleChip({required this.label, this.onDelete});

  final String label;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final palette = VergePalette.of(context);
    return Container(
      height: 26,
      padding: EdgeInsets.only(left: 10, right: onDelete == null ? 10 : 4),
      decoration: BoxDecoration(
        color: palette.panel,
        border: Border.all(color: palette.panelBorder),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          if (onDelete != null) ...[
            const SizedBox(width: 2),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onDelete,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Icon(
                    LucideIcons.x,
                    size: 12,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// «+» в шапке группы: меню «Гео-категория» / «Домен или IP».
class _AddRuleButton extends StatefulWidget {
  const _AddRuleButton({required this.onAdd});
  final ValueChanged<RoutingRule> onAdd;

  @override
  State<_AddRuleButton> createState() => _AddRuleButtonState();
}

class _AddRuleButtonState extends State<_AddRuleButton> {
  final _menu = ShadPopoverController();

  @override
  void dispose() {
    _menu.dispose();
    super.dispose();
  }

  Future<void> _addGeo() async {
    _menu.hide();
    final cat = await showShadDialog<GeoCategory>(
      context: context,
      builder: (ctx) => ShadDialog(
        title: const Text('Выбрать категорию'),
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final cat in geoCatalog)
                ShadButton.ghost(
                  mainAxisAlignment: MainAxisAlignment.start,
                  onPressed: () => Navigator.of(ctx).pop(cat),
                  child: Text(cat.label),
                ),
            ],
          ),
        ),
      ),
    );
    if (cat != null) {
      widget.onAdd(RoutingRule(kind: RoutingRuleKind.geo, value: cat.tag));
    }
  }

  Future<void> _addText() async {
    _menu.hide();
    final ctrl = TextEditingController();
    final entry = await showShadDialog<String>(
      context: context,
      builder: (ctx) => ShadDialog(
        title: const Text('Домен или IP/CIDR'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          ShadButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Добавить'),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: ShadInput(
            controller: ctrl,
            autofocus: true,
            placeholder: const Text('example.com или 1.2.3.0/24'),
          ),
        ),
      ),
    );
    ctrl.dispose();
    if (entry == null || entry.isEmpty) return;
    final kind = entry.contains('/') || RegExp(r'^\d+\.').hasMatch(entry)
        ? RoutingRuleKind.ip
        : RoutingRuleKind.domain;
    widget.onAdd(RoutingRule(kind: kind, value: entry));
  }

  @override
  Widget build(BuildContext context) {
    return ShadContextMenu(
      controller: _menu,
      anchor: const ShadAnchor(
        childAlignment: Alignment.bottomRight,
        overlayAlignment: Alignment.topRight,
      ),
      items: [
        ShadContextMenuItem(
          leading: const Icon(LucideIcons.globe, size: 16),
          onPressed: _addGeo,
          child: const Text('Гео-категория'),
        ),
        ShadContextMenuItem(
          leading: const Icon(LucideIcons.atSign, size: 16),
          onPressed: _addText,
          child: const Text('Домен или IP'),
        ),
      ],
      child: ShadTooltip(
        builder: (_) => const Text('Добавить правило'),
        child: ShadButton.outline(
          width: 26,
          height: 26,
          padding: EdgeInsets.zero,
          onPressed: _menu.toggle,
          child: const Icon(LucideIcons.plus, size: 13),
        ),
      ),
    );
  }
}

/// Полоска соотношения правил профиля: прокси · напрямую · блок. У профиля
/// без правил она целиком цвета итогового действия.
class _RuleMixBar extends StatelessWidget {
  const _RuleMixBar({required this.profile});
  final RoutingProfile profile;

  @override
  Widget build(BuildContext context) {
    final palette = VergePalette.of(context);
    final proxy = palette.accent;
    final direct = palette.success;
    final block = palette.danger;
    final p = profile;
    final parts = <(int, Color)>[
      (p.proxyRules.length, proxy),
      (p.directRules.length + p.allowRules.length, direct),
      (p.blockRules.length, block),
    ].where((e) => e.$1 > 0).toList();
    if (parts.isEmpty) {
      parts.add((1, p.finalAction == RoutingFinal.direct ? direct : proxy));
    }
    return SizedBox(
      height: 8,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < parts.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              flex: parts[i].$1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: parts[i].$2,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Сетка, в которой карточки одной строки равны по высоте самой высокой:
/// Wrap выравнивал их только по верху, и соседние блоки «прыгали».
class _EqualRows extends StatelessWidget {
  const _EqualRows({
    required this.columns,
    required this.gap,
    required this.children,
  });

  final int columns;
  final double gap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var start = 0; start < children.length; start += columns) {
      final cells = children.sublist(
          start, (start + columns).clamp(0, children.length));
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < columns; i++) ...[
              if (i > 0) SizedBox(width: gap),
              // Пустые ячейки последней строки держат ширину колонок.
              Expanded(
                child: i < cells.length ? cells[i] : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          rows[i],
        ],
      ],
    );
  }
}
