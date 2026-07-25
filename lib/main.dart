import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'app/app_controller.dart';
import 'models/app_settings.dart';
import 'services/subscription_service.dart';
import 'services/config_builder.dart';
import 'services/geo_asset_installer.dart';
import 'services/geo_updater.dart';
import 'services/hwid.dart';
import 'services/deep_link.dart';
import 'storage/state_repository.dart';
import 'platform/platform_info.dart';
import 'tunnel/macos_process_tunnel.dart';
import 'tunnel/tun_helper_tunnel.dart';
import 'ui/app_shell.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationSupportDirectory();
  final repo = FileStateRepository(File(p.join(dir.path, 'state.json')));
  final hwid = await resolveHwid(repo);
  final geoAssetDir = await GeoAssetInstaller(dir.path).install();
  final controller = AppController(
    subscription: SubscriptionService(hwid: hwid),
    builder: const ConfigBuilder(),
    proxyTunnel: MacOSProcessTunnel(),
    tunTunnel: TunHelperTunnel(),
    repo: repo,
    platform: PlatformInfo(),
    geoAssetDir: geoAssetDir,
    geoUpdater: GeoUpdater(geoAssetDir),
  );
  await controller.init();
  final deepLink = DeepLinkService();
  await deepLink.init();
  runApp(SingboxApp(controller: controller, deepLink: deepLink));
}

class SingboxApp extends StatelessWidget {
  final AppController controller;
  final DeepLinkService deepLink;
  const SingboxApp({super.key, required this.controller, required this.deepLink});

  ThemeMode _mode(AppThemeMode m) => switch (m) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => ShadApp(
        title: 'Verge',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _mode(controller.settings.themeMode),
        home: AppShell(controller: controller, deepLink: deepLink),
        materialThemeBuilder: (context, theme) => theme,
      ),
    );
  }
}
