import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../app/app_controller.dart';
import 'general_section.dart' show SettingsSection;

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
    final theme = ShadTheme.of(context);
    return SettingsSection(
      title: 'TLS',
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Пропустить проверку сертификата',
                      style: theme.textTheme.large),
                  Text(
                    'Понижает безопасность: соединение перестаёт защищать от '
                    'подмены сервера. Включать только для отладки',
                    style: theme.textTheme.muted,
                  ),
                ],
              ),
            ),
            ShadSwitch(
              key: const Key('tls-insecure-switch'),
              value: n.tlsSkipCertVerify,
              onChanged: (v) => controller
                  .updateNetworkSettings(n.copyWith(tlsSkipCertVerify: v)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Фрагментация TLS', style: theme.textTheme.large),
                  Text(
                    fragmentSupported
                        ? 'Режет TLS-хендшейк на части, чтобы обойти файрволы '
                            'с плоским matching по ClientHello. Работает '
                            'только под sing-box'
                        : 'Текущий движок фрагментацию не поддерживает',
                    style: theme.textTheme.muted,
                  ),
                ],
              ),
            ),
            ShadSwitch(
              key: const Key('tls-fragment-switch'),
              value: n.tlsFragmentEnabled,
              onChanged: fragmentSupported
                  ? (v) => controller.updateNetworkSettings(
                      n.copyWith(tlsFragmentEnabled: v))
                  : null,
            ),
          ],
        ),
        if (fragmentSupported && n.tlsFragmentEnabled) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Фрагментация по TLS-записям',
                        style: theme.textTheme.large),
                    Text(
                      'Дешевле по производительности — стоит пробовать первым',
                      style: theme.textTheme.muted,
                    ),
                  ],
                ),
              ),
              ShadSwitch(
                value: n.tlsRecordFragment,
                onChanged: (v) => controller
                    .updateNetworkSettings(n.copyWith(tlsRecordFragment: v)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Задержка резервного варианта', style: theme.textTheme.large),
          const SizedBox(height: 8),
          ShadInput(
            initialValue: n.tlsFragmentFallbackDelay,
            placeholder: const Text('500ms'),
            onSubmitted: (v) => controller.updateNetworkSettings(
                n.copyWith(tlsFragmentFallbackDelay: v.trim())),
          ),
        ],
      ],
    );
  }
}
