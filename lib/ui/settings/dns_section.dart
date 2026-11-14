import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../app/app_controller.dart';
import 'general_section.dart';
import '../../l10n/l10n.dart';

class DnsSection extends StatelessWidget {
  const DnsSection({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final n = controller.networkSettings;
    return SettingsSection(
      title: 'DNS',
      children: [
        SettingsRow(
          label: l10n.dnsHijack,
          description: l10n.dnsHijackDescription,
          trailing: ShadSwitch(
            key: const Key('dns-hijack-switch'),
            value: n.dnsHijack,
            onChanged: (v) =>
                controller.updateNetworkSettings(n.copyWith(dnsHijack: v)),
          ),
        ),
        SettingsField(
          label: l10n.dnsProxy,
          description: l10n.dnsProxyDescription,
          child: ShadInput(
            initialValue: n.proxyDnsServer,
            onSubmitted: (v) => controller.updateNetworkSettings(
                n.copyWith(proxyDnsServer: v.trim())),
          ),
        ),
        SettingsField(
          label: l10n.dnsDirect,
          description: l10n.dnsDirectDescription,
          child: ShadInput(
            initialValue: n.directDnsServer,
            onSubmitted: (v) => controller.updateNetworkSettings(
                n.copyWith(directDnsServer: v.trim())),
          ),
        ),
        // Выбор FakeIP и поле TTL убраны: sing-box 1.13 отвергает и legacy-
        // секцию dns.fakeip, и несуществующее поле dns.ttl — с ними туннель
        // просто не поднимался.
      ],
    );
  }
}
