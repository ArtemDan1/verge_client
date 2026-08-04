import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../app/app_controller.dart';
import 'general_section.dart' show SettingsSection;

class DnsSection extends StatelessWidget {
  const DnsSection({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final n = controller.networkSettings;
    final theme = ShadTheme.of(context);
    return SettingsSection(
      title: 'DNS',
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Перехват DNS в TUN', style: theme.textTheme.large),
                  Text(
                    'Заворачивает весь трафик на порт 53 в DNS-движок. Без '
                    'него запросы уходят на DNS провайдера и цензурируются',
                    style: theme.textTheme.muted,
                  ),
                ],
              ),
            ),
            ShadSwitch(
              key: const Key('dns-hijack-switch'),
              value: n.dnsHijack,
              onChanged: (v) =>
                  controller.updateNetworkSettings(n.copyWith(dnsHijack: v)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('DNS для прокси', style: theme.textTheme.large),
        const SizedBox(height: 8),
        ShadInput(
          initialValue: n.proxyDnsServer,
          onSubmitted: (v) => controller.updateNetworkSettings(
              n.copyWith(proxyDnsServer: v.trim())),
        ),
        const SizedBox(height: 24),
        Text('DNS для прямых соединений', style: theme.textTheme.large),
        const SizedBox(height: 8),
        ShadInput(
          initialValue: n.directDnsServer,
          onSubmitted: (v) => controller.updateNetworkSettings(
              n.copyWith(directDnsServer: v.trim())),
        ),
        // Выбор FakeIP и поле TTL убраны: sing-box 1.13 отвергает и legacy-
        // секцию dns.fakeip, и несуществующее поле dns.ttl — с ними туннель
        // просто не поднимался.
      ],
    );
  }
}
