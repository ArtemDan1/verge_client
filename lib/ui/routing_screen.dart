import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show MaterialPageRoute;
import 'package:shadcn_ui/shadcn_ui.dart';
import '../app/app_controller.dart';
import '../models/routing_profile.dart';
import '../models/routing_rule.dart';
import '../services/geo_catalog.dart';
import '../theme/verge_palette.dart';
import 'settings/general_section.dart' show SettingsSection;
import 'widgets/paper.dart';

class RoutingScreen extends StatelessWidget {
  final AppController controller;
  const RoutingScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Padding(
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
                            width: 16, height: 16, child: ShadProgress())
                        : const Icon(LucideIcons.cloudDownload, size: 16),
                    child: const Text('Обновить гео'),
                  ),
                ShadButton(
                  onPressed: () =>
                      controller.addRoutingProfile('Новый профиль'),
                  leading: const Icon(LucideIcons.plus, size: 16),
                  child: const Text('Профиль'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: SingleChildScrollView(
                child: LayoutBuilder(
                  builder: (context, box) {
                    // Три карточки в ряд на обычной ширине окна, две — на узкой.
                    final cols = box.maxWidth > 640 ? 3 : 2;
                    const gap = 12.0;
                    final w = (box.maxWidth - gap * (cols - 1)) / cols;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (final p in controller.routingProfiles)
                          SizedBox(width: w, child: _profileCard(context, p)),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _geoStatus(BuildContext context) {
    if (!controller.canUpdateGeo) {
      return const Text('Что идёт через VPN, что напрямую, а что блокируется');
    }
    final at = controller.geoUpdatedAt;
    final err = controller.geoUpdateError;
    final subtitle = err ??
        (at == null
            ? 'ещё не обновлялись — вшитые версии'
            : 'обновлены ${_ago(at)}');
    return Text('Гео-наборы (.srs): $subtitle',
        style: err != null
            ? TextStyle(color: VergePalette.of(context).dangerText)
            : null);
  }

  Widget _profileCard(BuildContext context, RoutingProfile p) {
    final theme = ShadTheme.of(context);
    final palette = VergePalette.of(context);
    final dark = theme.brightness == Brightness.dark;
    final active = p.id == controller.activeRoutingProfileId;
    final selectedBorder = dark ? palette.accentText : palette.accent;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => controller.selectRoutingProfile(p.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.all(active ? 15 : 16),
          decoration: BoxDecoration(
            color: active ? palette.accentSoft : palette.panel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? selectedBorder : palette.panelBorder,
              width: active ? 2 : 1,
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
                    child: Text(p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                  if (active) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(
                        color: palette.accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text('активен',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFFFFFF))),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(_summary(p),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.muted.copyWith(fontSize: 12)),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (p.isBuiltIn) ...[
                    Icon(LucideIcons.lock,
                        size: 14, color: theme.colorScheme.mutedForeground),
                    const SizedBox(width: 6),
                    Text('Встроенный',
                        style: theme.textTheme.muted.copyWith(fontSize: 12)),
                  ],
                  const Spacer(),
                  _cardAction(
                    icon: LucideIcons.copy,
                    tooltip: 'Дублировать',
                    onPressed: () => controller.cloneRoutingProfile(p.id),
                  ),
                  if (!p.isBuiltIn) ...[
                    _cardAction(
                      icon: LucideIcons.pencil,
                      tooltip: 'Редактировать',
                      onPressed: () => _openEditor(context, p),
                    ),
                    _cardAction(
                      icon: LucideIcons.trash2,
                      tooltip: 'Удалить',
                      color: palette.dangerText,
                      onPressed: () => controller.removeRoutingProfile(p.id),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) =>
      ShadTooltip(
        builder: (_) => Text(tooltip),
        child: ShadButton.ghost(
          width: 30,
          height: 30,
          padding: EdgeInsets.zero,
          onPressed: onPressed,
          child: Icon(icon, size: 15, color: color),
        ),
      );

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'только что';
    if (d.inHours < 1) return '${d.inMinutes} мин назад';
    if (d.inDays < 1) return '${d.inHours} ч назад';
    return '${d.inDays} дн назад';
  }

  String _summary(RoutingProfile p) {
    final a = p.allowRules.length;
    final allow = a > 0 ? 'исключений $a · ' : '';
    final rest = p.finalAction == RoutingFinal.direct
        ? 'остальное напрямую'
        : 'остальное через прокси';
    return '$allowнапрямую ${p.directRules.length} · '
        'прокси ${p.proxyRules.length} · '
        'блок ${p.blockRules.length} · $rest';
  }

  void _openEditor(BuildContext context, RoutingProfile p) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _RoutingEditor(controller: controller, profileId: p.id),
    ));
  }
}

class _RoutingEditor extends StatelessWidget {
  final AppController controller;
  final String profileId;
  const _RoutingEditor({required this.controller, required this.profileId});

  RoutingProfile get _p =>
      controller.routingProfiles.firstWhere((p) => p.id == profileId);

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final p = _p;
        return Container(
          color: theme.colorScheme.background,
          child: SafeArea(
            child: Padding(
              padding: kScreenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      ShadButton.ghost(
                        onPressed: () => Navigator.of(context).pop(),
                        leading: const Icon(LucideIcons.arrowLeft, size: 16),
                        child: const Text('Назад'),
                      ),
                      const SizedBox(width: 8),
                      Text(p.name,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _bucketCard(
                            context,
                            theme,
                            title: 'Исключения (перекрывают Block)',
                            rules: p.allowRules,
                            save: (rules) => controller.updateRoutingProfile(
                                p.copyWith(allowRules: rules)),
                            trailingSwitch: _SwitchRow(
                              label: 'Исключения через прокси',
                              value: p.allowAction == RoutingFinal.proxy,
                              onChanged: (v) => controller.updateRoutingProfile(
                                  p.copyWith(
                                      allowAction: v
                                          ? RoutingFinal.proxy
                                          : RoutingFinal.direct)),
                            ),
                          ),
                          _bucketCard(
                            context,
                            theme,
                            title: 'Direct (напрямую)',
                            rules: p.directRules,
                            save: (rules) => controller.updateRoutingProfile(
                                p.copyWith(directRules: rules)),
                          ),
                          _bucketCard(
                            context,
                            theme,
                            title: 'Proxy (через прокси)',
                            rules: p.proxyRules,
                            save: (rules) => controller.updateRoutingProfile(
                                p.copyWith(proxyRules: rules)),
                          ),
                          _bucketCard(
                            context,
                            theme,
                            title: 'Block (заблокировать)',
                            rules: p.blockRules,
                            save: (rules) => controller.updateRoutingProfile(
                                p.copyWith(blockRules: rules)),
                          ),
                          SettingsSection(
                            title: 'Остальное напрямую',
                            description: 'final=direct',
                            children: [
                              _SwitchRow(
                                label: 'Остальное напрямую',
                                value: p.finalAction == RoutingFinal.direct,
                                onChanged: (v) =>
                                    controller.updateRoutingProfile(p.copyWith(
                                        finalAction: v
                                            ? RoutingFinal.direct
                                            : RoutingFinal.proxy)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _bucketCard(
    BuildContext context,
    ShadThemeData theme, {
    required String title,
    required List<RoutingRule> rules,
    required void Function(List<RoutingRule>) save,
    Widget? trailingSwitch,
  }) {
    return SettingsSection(
      title: title,
      children: [
        if (trailingSwitch != null) ...[
          trailingSwitch,
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...rules.map((r) => _ruleChip(theme, _ruleLabel(r),
                () => save(rules.where((x) => x != r).toList()))),
            ShadButton.outline(
              size: ShadButtonSize.sm,
              leading: const Icon(LucideIcons.plus, size: 14),
              onPressed: () async {
                final cat = await _pickGeo(context, theme);
                if (cat != null) {
                  save([
                    ...rules,
                    RoutingRule(kind: RoutingRuleKind.geo, value: cat.tag)
                  ]);
                }
              },
              child: const Text('гео'),
            ),
            ShadButton.outline(
              size: ShadButtonSize.sm,
              leading: const Icon(LucideIcons.plus, size: 14),
              onPressed: () async {
                final entry = await _askText(context, theme);
                if (entry != null && entry.isNotEmpty) {
                  final kind = entry.contains('/') ||
                          RegExp(r'^\d+\.').hasMatch(entry)
                      ? RoutingRuleKind.ip
                      : RoutingRuleKind.domain;
                  save([...rules, RoutingRule(kind: kind, value: entry)]);
                }
              },
              child: const Text('домен/IP'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _ruleChip(ShadThemeData theme, String label, VoidCallback onDelete) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 6, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.small),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: Icon(LucideIcons.x,
                size: 14, color: theme.colorScheme.mutedForeground),
          ),
        ],
      ),
    );
  }

  String _ruleLabel(RoutingRule r) {
    if (r.kind == RoutingRuleKind.geo) {
      return geoCategoryByTag(r.value)?.label ?? r.value;
    }
    return r.value;
  }

  Future<GeoCategory?> _pickGeo(BuildContext context, ShadThemeData theme) {
    return showShadDialog<GeoCategory>(
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
  }

  Future<String?> _askText(BuildContext context, ShadThemeData theme) {
    final ctrl = TextEditingController();
    return showShadDialog<String>(
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
            placeholder: const Text('example.com или 1.2.3.0/24'),
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Row(
      children: [
        Expanded(child: Text(label, style: theme.textTheme.muted)),
        ShadSwitch(value: value, onChanged: onChanged),
      ],
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
