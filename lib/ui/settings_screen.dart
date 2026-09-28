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

/// Вкладки экрана настроек — в порядке показа.
const settingsTabs = ['Общие', 'TUN', 'DNS', 'TLS', 'Сеть', 'Пинг'];

class SettingsScreen extends StatefulWidget {
  final AppController controller;
  const SettingsScreen({super.key, required this.controller});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _tab = 0;

  Widget _content() {
    final c = widget.controller;
    return switch (_tab) {
      0 => GeneralSection(controller: c),
      1 => TunSection(controller: c),
      2 => DnsSection(controller: c),
      // Фрагментация — outbound-параметр sing-box (с 1.12.0); в Xray её
      // нет (потребовала бы отдельный freedom-outbound с dialerProxy),
      // но основной движок приложения — sing-box, поэтому поддерживается.
      3 => TlsSection(controller: c, fragmentSupported: true),
      4 => NetworkSection(controller: c),
      _ => GstaticPingSection(controller: c),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final palette = VergePalette.of(context);
    return Padding(
      padding: kScreenPadding.copyWith(bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            title: 'Настройки',
            // Настройки применяются при сборке конфига, а живой туннель
            // собран на старых. Перезапускать его молча нельзя —
            // пользователь может быть в середине важного соединения.
            actions: [
              if (c.isConnected) ...[
                Text(
                  'Изменения применятся после переподключения',
                  style: TextStyle(fontSize: 13, color: palette.warningText),
                ),
                ShadButton(
                  size: ShadButtonSize.sm,
                  onPressed: () => c.reconnect(),
                  child: const Text('Переподключить'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          _TabBar(
            selected: _tab,
            onSelect: (i) => setState(() => _tab = i),
          ),
          Expanded(
            child: SingleChildScrollView(
              key: PageStorageKey('settings-tab-$_tab'),
              padding: const EdgeInsets.only(top: 18, bottom: 22),
              child: SettingsTabScope(child: _content()),
            ),
          ),
        ],
      ),
    );
  }
}

/// Вкладки с подчёркиванием активной — как в макете.
class _TabBar extends StatelessWidget {
  const _TabBar({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final palette = VergePalette.of(context);
    final underline = theme.brightness == Brightness.dark
        ? palette.accentText
        : palette.accent;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.panelBorder)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < settingsTabs.length; i++)
            Semantics(
              button: true,
              selected: i == selected,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect(i),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: i == selected
                              ? underline
                              : underline.withValues(alpha: 0),
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      settingsTabs[i],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            i == selected ? FontWeight.w600 : FontWeight.w500,
                        color: i == selected
                            ? theme.colorScheme.foreground
                            : theme.colorScheme.mutedForeground,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
