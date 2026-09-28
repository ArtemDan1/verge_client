import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../app/app_controller.dart';
import '../theme/verge_palette.dart';
import 'settings/dns_section.dart';
import 'settings/general_section.dart';
import 'settings/gstatic_ping_section.dart';
import 'settings/network_section.dart';
import 'settings/tls_section.dart';
import 'settings/tun_section.dart';
import 'widgets/paper.dart';

class SettingsScreen extends StatelessWidget {
  final AppController controller;
  const SettingsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final palette = VergePalette.of(context);
    return SingleChildScrollView(
      padding: kScreenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHeader(title: 'Настройки'),
          const SizedBox(height: 18),
          // Настройки применяются при сборке конфига, а живой туннель собран
          // на старых. Перезапускать его молча нельзя — пользователь может
          // быть в середине важного соединения.
          if (controller.isConnected)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              decoration: BoxDecoration(
                color: palette.warningSoft,
                border: Border.all(color: palette.warningBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.info,
                      size: 16, color: palette.warningText),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Изменения сетевых настроек применятся после '
                      'переподключения',
                      style: TextStyle(
                          fontSize: 13, color: palette.warningText),
                    ),
                  ),
                  ShadButton(
                    size: ShadButtonSize.sm,
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
