import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../app/app_controller.dart';
import 'general_section.dart' show SettingsSection;

class NetworkSection extends StatelessWidget {
  const NetworkSection({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final n = controller.networkSettings;
    final theme = ShadTheme.of(context);
    return SettingsSection(
      title: 'Сеть',
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('IPv6', style: theme.textTheme.large),
                  Text(
                    'Выключен по умолчанию: многие серверы ходят только по '
                    'IPv4, и IPv6-соединения зависают вместо отката',
                    style: theme.textTheme.muted,
                  ),
                ],
              ),
            ),
            ShadSwitch(
              key: const Key('ipv6-switch'),
              value: n.ipv6Enabled,
              onChanged: (v) => controller
                  .updateNetworkSettings(n.copyWith(ipv6Enabled: v)),
            ),
          ],
        ),
      ],
    );
  }
}
