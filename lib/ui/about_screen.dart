import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../app/app_controller.dart';
import '../services/link_opener.dart';
import '../theme/app_theme.dart';
import '../theme/verge_palette.dart';
import 'widgets/paper.dart';
import 'widgets/update_banner.dart';
import 'widgets/verge_logo.dart';

const _repoUrl = 'https://github.com/ArtemDan1/verge_client';

class AboutScreen extends StatelessWidget {
  final AppController controller;
  const AboutScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final palette = VergePalette.of(context);
    final c = controller;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const VergeMark(size: 120),
                const SizedBox(height: 18),
                Text(
                  'Verge',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                    color: theme.colorScheme.foreground,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Прокси-клиент для macOS и Windows на базе sing-box и Xray.',
                  style: theme.textTheme.muted
                      .copyWith(fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ShadButton.outline(
                      size: ShadButtonSize.sm,
                      onPressed: () => openLink(_repoUrl),
                      child: const Text('GitHub'),
                    ),
                    ShadButton.outline(
                      size: ShadButtonSize.sm,
                      onPressed: () => openLink('$_repoUrl/releases'),
                      child: const Text('Что нового'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _UpdateBlock(controller: c),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: palette.panelBorder),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      _VersionRow(
                          label: 'Версия приложения',
                          version: c.platform.appVersion(),
                          first: true),
                      _VersionRow(
                          label: 'sing-box',
                          version: c.platform.singboxVersion()),
                      _VersionRow(
                          label: 'Xray', version: c.platform.xrayVersion()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({
    required this.label,
    required this.version,
    this.first = false,
  });

  final String label;
  final Future<String> version;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: first
            ? null
            : Border(
                top: BorderSide(color: VergePalette.of(context).divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: theme.textTheme.muted.copyWith(fontSize: 14)),
          ),
          FutureBuilder<String>(
            future: version,
            builder: (context, snap) => Text(
              snap.data ?? '…',
              style: monoStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: theme.colorScheme.foreground),
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

    if (info == null) {
      // Wrap, а не Row: в узкой колонке подпись уходила за край экрана —
      // теперь она просто переносится под кнопку.
      return Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ShadButton.outline(
            onPressed: c.isCheckingUpdate
                ? null
                : () async {
                    await c.checkForUpdate();
                    if (mounted) setState(() => _checked = true);
                  },
            leading: c.isCheckingUpdate
                ? const Spinner()
                : const Icon(LucideIcons.refreshCw, size: 16),
            child: Text(
                c.isCheckingUpdate ? 'Проверка…' : 'Проверить обновления'),
          ),
          if (_checked && !c.isCheckingUpdate)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.circleCheck,
                    size: 16, color: VergePalette.of(context).successText),
                const SizedBox(width: 6),
                Text('У вас последняя версия', style: theme.textTheme.muted),
              ],
            ),
        ],
      );
    }

    return UpdateCard(controller: c, inline: true);
  }
}
