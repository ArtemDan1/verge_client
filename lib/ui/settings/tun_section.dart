import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../app/app_controller.dart';
import '../../models/network_settings.dart';
import 'general_section.dart';

/// Параметры TUN под спойлером: их нынешние значения подобраны эмпирически,
/// и каждое «более разумное» значение уже ломало работу — см. комментарии к
/// полям NetworkSettings.
class TunSection extends StatefulWidget {
  const TunSection({super.key, required this.controller});

  final AppController controller;

  @override
  State<TunSection> createState() => _TunSectionState();
}

class _TunSectionState extends State<TunSection> {
  bool _expanded = false;

  /// Дефолты берём из самой модели, а не дублируем литералами: иначе
  /// «Сбросить» и конструктор разъедутся при первой же правке.
  static const _defaults = NetworkSettings();

  void _reset() {
    final n = widget.controller.networkSettings;
    widget.controller.updateNetworkSettings(n.copyWith(
      tunAddressV4: _defaults.tunAddressV4,
      tunAddressV6: _defaults.tunAddressV6,
      tunMtu: _defaults.tunMtu,
      tunStack: _defaults.tunStack,
      tunStrictRoute: _defaults.tunStrictRoute,
      tunAutoRoute: _defaults.tunAutoRoute,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.controller.networkSettings;
    final theme = ShadTheme.of(context);
    void update(NetworkSettings v) => widget.controller.updateNetworkSettings(v);
    return SettingsSection(
      title: 'TUN',
      children: [
        SettingsRow(
          label: 'Расширенные',
          description: 'Адрес интерфейса, MTU, сетевой стек и маршруты. '
              'Подобраны под большинство сетей — трогать, только если TUN '
              'работает с проблемами',
          onTap: () => setState(() => _expanded = !_expanded),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_expanded) ...[
                ShadButton.outline(
                  size: ShadButtonSize.sm,
                  onPressed: _reset,
                  child: const Text('Сбросить'),
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                size: 18,
                color: theme.colorScheme.mutedForeground,
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          const SettingsNotice(
            'Менять эти значения стоит, только если понимаете последствия. '
            'MTU 9000 обрывает SSH и MySQL, адрес из 172.16.0.0/12 ломает '
            'docker-сети, строгий маршрут перехватывает трафик локальной сети.',
          ),
          SettingsField(
            label: 'Адрес интерфейса',
            child: ShadInput(
              initialValue: n.tunAddressV4,
              onSubmitted: (v) => update(n.copyWith(tunAddressV4: v.trim())),
            ),
          ),
          SettingsRow(
            label: 'MTU',
            description: 'От 576 до 9000',
            trailing: SettingsInput(
              initialValue: '${n.tunMtu}',
              number: true,
              onSubmitted: (v) {
                final mtu = int.tryParse(v.trim());
                if (mtu != null && mtu >= 576 && mtu <= 9000) {
                  update(n.copyWith(tunMtu: mtu));
                }
              },
            ),
          ),
          SettingsRow(
            label: 'Сетевой стек',
            description: 'gvisor — совместимость, system — скорость, '
                'mixed — баланс',
            trailing: SizedBox(
              width: 140,
              child: ShadSelect<TunStack>(
                minWidth: 140,
                initialValue: n.tunStack,
                options: const [
                  ShadOption(value: TunStack.gvisor, child: Text('gvisor')),
                  ShadOption(value: TunStack.system, child: Text('system')),
                  ShadOption(value: TunStack.mixed, child: Text('mixed')),
                ],
                selectedOptionBuilder: (ctx, v) => Text(v.name),
                onChanged: (v) =>
                    v == null ? null : update(n.copyWith(tunStack: v)),
              ),
            ),
          ),
          SettingsRow(
            label: 'Строгий маршрут',
            description: 'Не даёт трафику уйти мимо туннеля',
            trailing: ShadSwitch(
              value: n.tunStrictRoute,
              onChanged: (v) => update(n.copyWith(tunStrictRoute: v)),
            ),
          ),
          SettingsRow(
            label: 'Маршрут по умолчанию',
            description: 'Весь трафик системы идёт в туннель',
            trailing: ShadSwitch(
              value: n.tunAutoRoute,
              onChanged: (v) => update(n.copyWith(tunAutoRoute: v)),
            ),
          ),
        ],
      ],
    );
  }
}
