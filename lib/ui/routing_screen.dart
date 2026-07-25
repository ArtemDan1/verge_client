import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show MaterialPageRoute;
import 'package:shadcn_ui/shadcn_ui.dart';
import '../app/app_controller.dart';
import '../models/routing_profile.dart';
import '../models/routing_rule.dart';
import '../services/geo_catalog.dart';

class RoutingScreen extends StatelessWidget {
  final AppController controller;
  const RoutingScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Роутинг', style: theme.textTheme.large),
                const Spacer(),
                if (controller.canUpdateGeo)
                  ShadButton.outline(
                    onPressed: controller.isUpdatingGeo
                        ? null
                        : () => controller.updateGeoAssets(),
                    leading: controller.isUpdatingGeo
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: ShadProgress())
                        : const Icon(LucideIcons.cloudDownload, size: 16),
                    child: const Text('Обновить гео'),
                  ),
                const SizedBox(width: 8),
                ShadButton(
                  onPressed: () =>
                      controller.addRoutingProfile('Новый профиль'),
                  leading: const Icon(LucideIcons.plus, size: 16),
                  child: const Text('Профиль'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _geoStatus(theme),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final p in controller.routingProfiles)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _profileRow(context, theme, p),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _geoStatus(ShadThemeData theme) {
    if (!controller.canUpdateGeo) return const SizedBox.shrink();
    final at = controller.geoUpdatedAt;
    final err = controller.geoUpdateError;
    final subtitle = err ??
        (at == null
            ? 'ещё не обновлялись — вшитые версии'
            : 'обновлены ${_ago(at)}');
    return Row(
      children: [
        const Icon(LucideIcons.globe, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text('Гео-наборы (.srs): $subtitle',
              style: theme.textTheme.muted.copyWith(
                  color: err != null ? theme.colorScheme.destructive : null)),
        ),
      ],
    );
  }

  Widget _profileRow(BuildContext context, ShadThemeData theme, RoutingProfile p) {
    final active = p.id == controller.activeRoutingProfileId;
    return GestureDetector(
      onTap: () => controller.selectRoutingProfile(p.id),
      child: ShadCard(
        backgroundColor: active ? theme.colorScheme.accent : null,
        child: Row(
          children: [
            Icon(active ? LucideIcons.circleCheck : LucideIcons.circle,
                size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name),
                  Text(_summary(p), style: theme.textTheme.muted),
                ],
              ),
            ),
            if (p.isBuiltIn)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(LucideIcons.lock, size: 16),
              ),
            ShadButton.ghost(
              onPressed: () => controller.cloneRoutingProfile(p.id),
              leading: const Icon(LucideIcons.copy, size: 16),
            ),
            if (!p.isBuiltIn)
              ShadButton.ghost(
                onPressed: () => _openEditor(context, p),
                leading: const Icon(LucideIcons.pencil, size: 16),
              ),
            if (!p.isBuiltIn)
              ShadButton.ghost(
                onPressed: () => controller.removeRoutingProfile(p.id),
                leading: Icon(LucideIcons.trash2,
                    size: 16, color: theme.colorScheme.destructive),
              ),
          ],
        ),
      ),
    );
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'только что';
    if (d.inHours < 1) return '${d.inMinutes} мин назад';
    if (d.inDays < 1) return '${d.inHours} ч назад';
    return '${d.inDays} дн назад';
  }

  String _summary(RoutingProfile p) {
    final d = p.directRules.length, x = p.proxyRules.length, b = p.blockRules.length;
    return 'direct $d · proxy $x · block $b · final ${p.finalAction.name}';
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
              padding: const EdgeInsets.all(16),
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
                      Text(p.name, style: theme.textTheme.h4),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _bucket(context, theme, 'Direct (напрямую)',
                              p.directRules,
                              (rules) => controller.updateRoutingProfile(
                                  p.copyWith(directRules: rules))),
                          _bucket(context, theme, 'Proxy (через прокси)',
                              p.proxyRules,
                              (rules) => controller.updateRoutingProfile(
                                  p.copyWith(proxyRules: rules))),
                          _bucket(context, theme, 'Block (заблокировать)',
                              p.blockRules,
                              (rules) => controller.updateRoutingProfile(
                                  p.copyWith(blockRules: rules))),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                    'Остальное напрямую (final=direct)',
                                    style: theme.textTheme.large),
                              ),
                              ShadSwitch(
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

  Widget _bucket(BuildContext context, ShadThemeData theme, String title,
      List<RoutingRule> rules, void Function(List<RoutingRule>) save) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.large),
          const SizedBox(height: 8),
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
                    save([
                      ...rules,
                      RoutingRule(kind: kind, value: entry)
                    ]);
                  }
                },
                child: const Text('домен/IP'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ruleChip(ShadThemeData theme, String label, VoidCallback onDelete) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 6, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
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
