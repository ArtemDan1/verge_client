import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../app/app_controller.dart';
import '../services/deep_link.dart';

/// Общая для десктопного и мобильного каркаса реакция на события контроллера:
/// тосты с ошибками и подтверждение импорта подписки по ссылке `verge://`.
mixin ShellEvents<T extends StatefulWidget> on State<T> {
  StreamSubscription<String>? _alertSub;
  StreamSubscription<ImportRequest>? _importSub;

  void listenShellEvents(AppController controller, DeepLinkService deepLink) {
    _alertSub = controller.alerts.listen((msg) {
      if (!mounted) return;
      ShadToaster.of(context).show(ShadToast.destructive(
        description: Text(msg),
      ));
    });
    _importSub = deepLink.imports.listen((req) {
      if (!mounted) return;
      _confirmImport(controller, req);
    });
  }

  void cancelShellEvents() {
    _alertSub?.cancel();
    _importSub?.cancel();
  }

  Future<void> _confirmImport(AppController controller, ImportRequest req) async {
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
      await controller.addProfile(req.name, req.url);
    }
  }
}
