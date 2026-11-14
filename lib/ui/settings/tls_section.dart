import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../app/app_controller.dart';
import 'general_section.dart';
import '../../l10n/l10n.dart';

class TlsSection extends StatelessWidget {
  const TlsSection({
    super.key,
    required this.controller,
    required this.fragmentSupported,
  });

  final AppController controller;

  /// Фрагментация — outbound-параметр sing-box (с 1.12.0); Xray его не
  /// читает. Когда активный движок её не поддерживает, поля дизейблятся с
  /// пояснением, а не молча игнорируются при сборке конфига.
  final bool fragmentSupported;

  @override
  Widget build(BuildContext context) {
    final n = controller.networkSettings;
    return SettingsSection(
      title: 'TLS',
      children: [
        SettingsRow(
          label: l10n.skipCertVerify,
          description: l10n.skipCertVerifyDescription,
          trailing: ShadSwitch(
            key: const Key('tls-insecure-switch'),
            value: n.tlsSkipCertVerify,
            onChanged: (v) => controller
                .updateNetworkSettings(n.copyWith(tlsSkipCertVerify: v)),
          ),
        ),
        SettingsRow(
          label: l10n.tlsFragment,
          description: fragmentSupported
              ? l10n.tlsFragmentDescription
              : l10n.tlsFragmentUnsupported,
          trailing: ShadSwitch(
            key: const Key('tls-fragment-switch'),
            value: n.tlsFragmentEnabled,
            onChanged: fragmentSupported
                ? (v) => controller
                    .updateNetworkSettings(n.copyWith(tlsFragmentEnabled: v))
                : null,
          ),
        ),
        if (fragmentSupported && n.tlsFragmentEnabled) ...[
          SettingsRow(
            label: l10n.tlsRecordFragment,
            description:
                l10n.tlsRecordFragmentDescription,
            trailing: ShadSwitch(
              value: n.tlsRecordFragment,
              onChanged: (v) => controller
                  .updateNetworkSettings(n.copyWith(tlsRecordFragment: v)),
            ),
          ),
          SettingsRow(
            label: l10n.fallbackDelay,
            description: l10n.fallbackDelayDescription,
            trailing: SettingsInput(
              initialValue: n.tlsFragmentFallbackDelay,
              placeholder: '500ms',
              onSubmitted: (v) => controller.updateNetworkSettings(
                  n.copyWith(tlsFragmentFallbackDelay: v.trim())),
            ),
          ),
        ],
      ],
    );
  }
}
