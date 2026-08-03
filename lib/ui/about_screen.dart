import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show SelectableText;
import 'package:shadcn_ui/shadcn_ui.dart';
import '../app/app_controller.dart';

class AboutScreen extends StatelessWidget {
  final AppController controller;
  const AboutScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final c = controller;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('О приложении', style: theme.textTheme.large),
          const SizedBox(height: 12),
          ShadCard(
            title: const Text('Verge'),
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<String>(
                    future: c.platform.appVersion(),
                    builder: (context, snap) =>
                        Text('Версия приложения: ${snap.data ?? '…'}'),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<String>(
                    future: c.platform.singboxVersion(),
                    builder: (context, snap) =>
                        Text('Версия sing-box: ${snap.data ?? '…'}'),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<String>(
                    future: c.platform.xrayVersion(),
                    builder: (context, snap) =>
                        Text('Версия Xray: ${snap.data ?? '…'}'),
                  ),
                  const SizedBox(height: 12),
                  _UpdateBlock(controller: c),
                  const SizedBox(height: 12),
                  const SelectableText(
                      'https://github.com/ArtemDan1/verge_client'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateBlock extends StatefulWidget {
  const _UpdateBlock({required this.controller});
  final AppController controller;
  @override
  State<_UpdateBlock> createState() => _UpdateBlockState();
}

class _UpdateBlockState extends State<_UpdateBlock> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final theme = ShadTheme.of(context);
    final info = c.availableUpdate;
    final downloading = c.updateDownloadProgress != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (info != null) ...[
          Text('Доступна версия ${info.version}', style: theme.textTheme.large),
          const SizedBox(height: 8),
          ShadButton(
            onPressed: downloading ? null : c.downloadAndInstallUpdate,
            leading: const Icon(LucideIcons.download, size: 16),
            child: Text(downloading
                ? 'Загрузка ${((c.updateDownloadProgress ?? 0) * 100).round()}%'
                : 'Скачать и установить'),
          ),
        ] else ...[
          if (_checked && !c.isCheckingUpdate)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child:
                  Text('У вас последняя версия', style: theme.textTheme.muted),
            ),
          ShadButton.outline(
            onPressed: c.isCheckingUpdate
                ? null
                : () async {
                    await c.checkForUpdate();
                    if (mounted) setState(() => _checked = true);
                  },
            leading: const Icon(LucideIcons.refreshCw, size: 16),
            child: Text(
                c.isCheckingUpdate ? 'Проверка…' : 'Проверить обновления'),
          ),
        ],
      ],
    );
  }
}
