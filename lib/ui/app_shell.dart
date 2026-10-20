import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/widgets.dart';
import '../app/app_controller.dart';
import '../models/connection_info.dart';
import '../services/deep_link.dart';
import '../theme/verge_palette.dart';
import 'widgets/sidebar.dart';
import 'widgets/update_banner.dart';
import 'profiles_screen.dart';
import 'settings_screen.dart';
import 'logs_screen.dart';
import 'connections_screen.dart';
import 'routing_screen.dart';
import 'about_screen.dart';
import 'shell_events.dart';

class AppShell extends StatefulWidget {
  final AppController controller;
  final DeepLinkService deepLink;

  /// Выбранный раздел, живущий дольше самого AppShell: пока открыто мини-окно
  /// трея, главный экран размонтирован, и без этого после возврата всегда
  /// открывалась бы «Главная».
  final ValueNotifier<int>? navIndex;
  const AppShell({
    super.key,
    required this.controller,
    required this.deepLink,
    this.navIndex,
  });
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with ShellEvents<AppShell> {
  late int _index = widget.navIndex?.value ?? 0;

  @override
  void initState() {
    super.initState();
    listenShellEvents(widget.controller, widget.deepLink);
  }

  @override
  void dispose() {
    cancelShellEvents();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final screens = [
          ProfilesScreen(controller: widget.controller),
          SettingsScreen(controller: widget.controller),
          LogsScreen(controller: widget.controller),
          ConnectionsScreen(controller: widget.controller),
          RoutingScreen(controller: widget.controller),
          AboutScreen(controller: widget.controller),
        ];
        final palette = VergePalette.of(context);
        return Scaffold(
          backgroundColor: palette.chrome,
          body: Stack(
            children: [
              Positioned.fill(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ValueListenableBuilder<List<ConnectionInfo>>(
                      valueListenable: widget.controller.connections,
                      builder: (context, conns, _) =>
                          ValueListenableBuilder<TrafficStats>(
                        valueListenable: widget.controller.traffic,
                        builder: (context, traffic, _) => Sidebar(
                          index: _index,
                          onSelect: (i) => setState(() {
                            _index = i;
                            widget.navIndex?.value = i;
                          }),
                          connectionCount: conns.length,
                          traffic: traffic,
                          hasUpdate: widget.controller.availableUpdate !=
                                  null &&
                              widget.controller.availableUpdate!.version !=
                                  widget.controller.settings.skippedVersion,
                        ),
                      ),
                    ),
                    // Контент — «вставленная» панель поверх фона окна,
                    // как в нативных macOS-приложениях.
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: palette.panel,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: palette.panelBorder),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: screens[_index],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Карточка обновления — поверх контента в углу, не сдвигая его.
              // На «О приложении» свой блок обновления, там её не дублируем.
              if (_index != aboutIndex)
                Positioned(
                  right: 26,
                  bottom: 26,
                  child: UpdateBanner(controller: widget.controller),
                ),
            ],
          ),
        );
      },
    );
  }
}
