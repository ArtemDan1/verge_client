import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../app/app_controller.dart';
import 'general_section.dart';

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
          label: 'Пропустить проверку сертификата',
          description: 'Понижает безопасность: соединение перестаёт защищать '
              'от подмены сервера. Включать только для отладки',
          trailing: ShadSwitch(
            key: const Key('tls-insecure-switch'),
            value: n.tlsSkipCertVerify,
            onChanged: (v) => controller
                .updateNetworkSettings(n.copyWith(tlsSkipCertVerify: v)),
          ),
        ),
        SettingsRow(
          label: 'Фрагментация TLS',
          description: fragmentSupported
              ? 'Режет TLS-хендшейк на части, чтобы обойти файрволы с плоским '
                  'matching по ClientHello. Работает только под sing-box'
              : 'Текущий движок фрагментацию не поддерживает',
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
            label: 'Фрагментация по TLS-записям',
            description:
                'Дешевле по производительности — стоит пробовать первым',
            trailing: ShadSwitch(
              value: n.tlsRecordFragment,
              onChanged: (v) => controller
                  .updateNetworkSettings(n.copyWith(tlsRecordFragment: v)),
            ),
          ),
          SettingsRow(
            label: 'Задержка резервного варианта',
            description: 'Сколько ждать ответа, прежде чем пробовать без '
                'фрагментации',
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
