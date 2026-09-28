import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../app/app_controller.dart';
import 'general_section.dart';

class NetworkSection extends StatelessWidget {
  const NetworkSection({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final n = controller.networkSettings;
    return SettingsSection(
      title: 'Сеть',
      children: [
        SettingsRow(
          label: 'IPv6',
          description: 'Выключен по умолчанию: многие серверы ходят только по '
              'IPv4, и IPv6-соединения зависают вместо отката',
          trailing: ShadSwitch(
            key: const Key('ipv6-switch'),
            value: n.ipv6Enabled,
            onChanged: (v) =>
                controller.updateNetworkSettings(n.copyWith(ipv6Enabled: v)),
          ),
        ),
      ],
    );
  }
}
