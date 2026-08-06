import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../app/app_controller.dart';
import 'settings/dns_section.dart';
import 'settings/general_section.dart';
import 'settings/gstatic_ping_section.dart';
import 'settings/network_section.dart';
import 'settings/tls_section.dart';
import 'settings/tun_section.dart';

class SettingsScreen extends StatelessWidget {
  final AppController controller;
  const SettingsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Настройки', style: theme.textTheme.large),
          const SizedBox(height: 16),
          // Настройки применяются при сборке конфига, а живой туннель собран
          // на старых. Перезапускать его молча нельзя — пользователь может
          // быть в середине важного соединения.
          if (controller.isConnected)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Изменения сетевых настроек применятся после '
                      'переподключения',
                      style: theme.textTheme.muted,
                    ),
                  ),
                  ShadButton.outline(
                    onPressed: () => controller.reconnect(),
                    child: const Text('Переподключить'),
                  ),
                ],
              ),
            ),
          GeneralSection(controller: controller),
          GstaticPingSection(controller: controller),
          NetworkSection(controller: controller),
          DnsSection(controller: controller),
          TunSection(controller: controller),
          // Фрагментация — outbound-параметр sing-box (с 1.12.0); в Xray её
          // нет (потребовала бы отдельный freedom-outbound с dialerProxy),
          // но основной движок приложения — sing-box, поэтому поддерживается.
          TlsSection(controller: controller, fragmentSupported: true),
        ],
      ),
    );
  }
}
