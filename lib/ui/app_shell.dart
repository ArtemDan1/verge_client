import 'dart:async';
import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../app/app_controller.dart';
import '../models/connection_info.dart';
import '../services/deep_link.dart';
import 'widgets/sidebar.dart';
import 'widgets/update_banner.dart';
import 'profiles_screen.dart';
import 'settings_screen.dart';
import 'logs_screen.dart';
import 'connections_screen.dart';
import 'routing_screen.dart';
import 'about_screen.dart';

class AppShell extends StatefulWidget {
  final AppController controller;
  final DeepLinkService deepLink;
  const AppShell({super.key, required this.controller, required this.deepLink});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  StreamSubscription<String>? _alertSub;
  StreamSubscription<ImportRequest>? _importSub;

  @override
  void initState() {
    super.initState();
    _alertSub = widget.controller.alerts.listen((msg) {
      if (!mounted) return;
      ShadToaster.of(context).show(ShadToast.destructive(
        description: Text(msg),
      ));
    });
    _importSub = widget.deepLink.imports.listen((req) {
      if (!mounted) return;
      _confirmImport(req);
    });
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    _importSub?.cancel();
    super.dispose();
  }

  Future<void> _confirmImport(ImportRequest req) async {
    final ok = await showShadDialog<bool>(
      context: context,
      builder: (ctx) => ShadDialog(
        title: const Text('Добавить подписку'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          ShadButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Добавить'),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Имя: ${req.name}'),
              const SizedBox(height: 4),
              Text('URL: ${req.url}'),
            ],
          ),
        ),
      ),
    );
    if (ok == true && mounted) {
      await widget.controller.addProfile(req.name, req.url);
    }
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
        return Scaffold(
          body: Column(
            children: [
              UpdateBanner(controller: widget.controller),
              Expanded(
                child: Row(
                  children: [
                    ValueListenableBuilder<List<ConnectionInfo>>(
                      valueListenable: widget.controller.connections,
                      builder: (context, conns, _) =>
                          ValueListenableBuilder<TrafficStats>(
                        valueListenable: widget.controller.traffic,
                        builder: (context, traffic, _) => Sidebar(
                          index: _index,
                          onSelect: (i) => setState(() => _index = i),
                          connectionCount: conns.length,
                          traffic: traffic,
                          hasUpdate: widget.controller.availableUpdate !=
                                  null &&
                              widget.controller.availableUpdate!.version !=
                                  widget.controller.settings.skippedVersion,
                        ),
                      ),
                    ),
                    Expanded(child: screens[_index]),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
