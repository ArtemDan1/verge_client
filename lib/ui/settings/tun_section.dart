import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../app/app_controller.dart';
import '../../models/network_settings.dart';
import 'general_section.dart' show SettingsSection;

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
    return SettingsSection(
      title: 'TUN',
      children: [
        Row(
          children: [
            ShadButton.ghost(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: const Text('Расширенные'),
            ),
            const Spacer(),
            if (_expanded)
              ShadButton.outline(
                onPressed: _reset,
                child: const Text('Сбросить'),
              ),
          ],
        ),
        if (_expanded) ...[
          const SizedBox(height: 12),
          Text(
            'Менять эти значения стоит, только если понимаете последствия. '
            'MTU 9000 обрывает SSH и MySQL, адрес из 172.16.0.0/12 ломает '
            'docker-сети, строгий маршрут перехватывает трафик локальной сети.',
            style: TextStyle(color: theme.colorScheme.destructive),
          ),
          const SizedBox(height: 16),
          Text('Адрес интерфейса', style: theme.textTheme.large),
          const SizedBox(height: 8),
          ShadInput(
            initialValue: n.tunAddressV4,
            onSubmitted: (v) => widget.controller
                .updateNetworkSettings(n.copyWith(tunAddressV4: v.trim())),
          ),
          const SizedBox(height: 24),
          Text('MTU', style: theme.textTheme.large),
          const SizedBox(height: 8),
          ShadInput(
            initialValue: '${n.tunMtu}',
            keyboardType: TextInputType.number,
            onSubmitted: (v) {
              final mtu = int.tryParse(v.trim());
              if (mtu != null && mtu >= 576 && mtu <= 9000) {
                widget.controller
                    .updateNetworkSettings(n.copyWith(tunMtu: mtu));
              }
            },
          ),
          const SizedBox(height: 24),
          Text('Сетевой стек', style: theme.textTheme.large),
          const SizedBox(height: 8),
          ShadSelect<TunStack>(
            minWidth: 240,
            initialValue: n.tunStack,
            options: const [
              ShadOption(value: TunStack.gvisor, child: Text('gvisor')),
              ShadOption(value: TunStack.system, child: Text('system')),
              ShadOption(value: TunStack.mixed, child: Text('mixed')),
            ],
            selectedOptionBuilder: (ctx, v) => Text(v.name),
            onChanged: (v) => v == null
                ? null
                : widget.controller
                    .updateNetworkSettings(n.copyWith(tunStack: v)),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text('Строгий маршрут', style: theme.textTheme.large),
              ),
              ShadSwitch(
                value: n.tunStrictRoute,
                onChanged: (v) => widget.controller
                    .updateNetworkSettings(n.copyWith(tunStrictRoute: v)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child:
                    Text('Маршрут по умолчанию', style: theme.textTheme.large),
              ),
              ShadSwitch(
                value: n.tunAutoRoute,
                onChanged: (v) => widget.controller
                    .updateNetworkSettings(n.copyWith(tunAutoRoute: v)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
