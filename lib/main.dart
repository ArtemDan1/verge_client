import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'app/app_controller.dart';
import 'app/tray_popover_controller.dart';
import 'app/tray_service.dart';
import 'app/window_control_channel.dart';
import 'models/app_settings.dart';
import 'services/subscription_service.dart';
import 'services/config_builder.dart';
import 'services/geo_asset_installer.dart';
import 'services/geo_updater.dart';
import 'services/hwid.dart';
import 'services/deep_link.dart';
import 'services/update_service.dart';
import 'storage/state_repository.dart';
import 'platform/platform_info.dart';
import 'tunnel/android_vpn_tunnel.dart';
import 'tunnel/macos_process_tunnel.dart';
import 'tunnel/tun_helper_tunnel.dart';
import 'tunnel/tunnel_controller.dart';
import 'ui/app_shell.dart';
import 'ui/mobile_shell.dart';
import 'ui/tray_popover.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationSupportDirectory();
  final repo = FileStateRepository(File(p.join(dir.path, 'state.json')));
  final hwid = await resolveHwid(repo);
  final geoAssetDir = await GeoAssetInstaller(dir.path).install();
  final platform = PlatformInfo();
  // Android: только VPN (VpnService), ни системного прокси, ни трея.
  final mobile = Platform.isAndroid;
  final TunnelController proxyTunnel;
  final TunnelController tunTunnel;
  UpdateService? updateService;
  if (mobile) {
    proxyTunnel = UnsupportedTunnel('На Android доступен только VPN-режим');
    tunTunnel = AndroidVpnTunnel();
    // В релизе по APK на каждый ABI — берём свой.
    updateService = UpdateService(
      assetSuffix: 'android-${await platform.deviceAbi()}.apk',
      downloadFileName: 'Verge-update.apk',
    );
  } else {
    proxyTunnel = MacOSProcessTunnel();
    tunTunnel = TunHelperTunnel();
  }
  final controller = AppController(
    subscription: SubscriptionService(hwid: hwid),
    builder: const ConfigBuilder(),
    proxyTunnel: proxyTunnel,
    tunTunnel: tunTunnel,
    repo: repo,
    platform: platform,
    geoAssetDir: geoAssetDir,
    geoUpdater: GeoUpdater(geoAssetDir),
    updateService: updateService,
    tunOnly: mobile,
  );
  await controller.init();
  TrayPopoverController? popover;
  if (!mobile) {
    popover = TrayPopoverController(WindowControlChannel());
    await TrayService(controller, popover).init();
  }
  final deepLink = DeepLinkService();
  await deepLink.init();
  runApp(SingboxApp(
    controller: controller,
    deepLink: deepLink,
    popover: popover,
    mobile: mobile,
  ));
}

class SingboxApp extends StatefulWidget {
  final AppController controller;
  final DeepLinkService deepLink;

  /// Мини-окно трея; null там, где трея нет (Android).
  final TrayPopoverController? popover;

  /// Телефонный интерфейс: нижняя навигация вместо сайдбара.
  final bool mobile;
  const SingboxApp({
    super.key,
    required this.controller,
    required this.deepLink,
    this.popover,
    this.mobile = false,
  });

  @override
  State<SingboxApp> createState() => _SingboxAppState();
}

class _SingboxAppState extends State<SingboxApp> {
  final _navIndex = ValueNotifier<int>(0);

  @override
  void dispose() {
    _navIndex.dispose();
    super.dispose();
  }

  ThemeMode _mode(AppThemeMode m) => switch (m) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      };

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final popover = widget.popover;
    return AnimatedBuilder(
      animation: Listenable.merge([controller, ?popover]),
      builder: (context, _) => ShadApp(
        title: 'Verge',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _mode(controller.settings.themeMode),
        // Мини-окно трея рисуется в том же окне, что и главный экран: пока
        // оно открыто, нативная сторона ужимает окно до его размеров.
        home: widget.mobile
            ? MobileShell(
                controller: controller,
                deepLink: widget.deepLink,
                navIndex: _navIndex,
              )
            : popover != null && popover.isOpen
                ? TrayPopover(controller: controller, popover: popover)
                : AppShell(
                    controller: controller,
                    deepLink: widget.deepLink,
                    navIndex: _navIndex,
                  ),
        // Emoji-фолбэк нужен и здесь, а не только в ShadThemeData: обычные
        // Text без стиля (например, имена нод — Text(p.name)) берут стиль из
        // DefaultTextStyle, который Material строит из своей textTheme, и до
        // ShadTextTheme не доходят. Без этой строки флаги стран в именах нод
        // на Windows так и остаются буквами.
        materialThemeBuilder: (context, theme) => theme.copyWith(
          textTheme: theme.textTheme.apply(
            fontFamily: kUiFontFamily,
            fontFamilyFallback: kEmojiFontFallback,
          ),
        ),
      ),
    );
  }
}
