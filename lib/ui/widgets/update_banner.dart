import 'package:flutter/material.dart' show LinearProgressIndicator;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../app/app_controller.dart';
import '../../services/link_opener.dart';
import '../../theme/app_theme.dart';
import '../../theme/verge_palette.dart';
import 'paper.dart';

/// Карточка о новой версии — всплывает в углу окна, не сдвигая контент.
/// Модального диалога намеренно нет: обновление не должно перегораживать
/// запуск приложения.
///
/// Состояния: доступно → скачивается (полоска и проценты) → запуск
/// установщика; при ошибке — текст ошибки и «Повторить».
class UpdateBanner extends StatelessWidget {
  const UpdateBanner({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final info = controller.updateToOffer;
    // Идущую загрузку не прячем, даже если версию успели скрыть «Позже».
    final busy = controller.updateDownloadProgress != null ||
        controller.isInstallingUpdate;
    final visible = info != null || (busy && controller.availableUpdate != null);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.15), end: Offset.zero)
              .animate(animation),
          child: child,
        ),
      ),
      child: visible
          ? UpdateCard(
              key: const ValueKey('update-card'),
              controller: controller,
            )
          : const SizedBox.shrink(key: ValueKey('none')),
    );
  }
}

/// Карточка обновления: и всплывающая в углу окна, и встроенная в
/// «О приложении» ([inline] — во всю ширину, без «Позже» и тени).
class UpdateCard extends StatelessWidget {
  const UpdateCard({super.key, required this.controller, this.inline = false});

  final AppController controller;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final info = c.availableUpdate!;
    final theme = ShadTheme.of(context);
    final palette = VergePalette.of(context);
    final dark = theme.brightness == Brightness.dark;
    final progress = c.updateDownloadProgress;
    final downloading = progress != null;
    final installing = c.isInstallingUpdate;
    final error = c.updateError;

    return Container(
      width: inline ? null : 360,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: inline
            ? palette.accentSoft
            : dark
                ? palette.surfaceHeader
                : palette.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: inline ? palette.accentSoftBorder : palette.panelBorder),
        boxShadow: inline ? null : [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: dark ? 0.45 : 0.12),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: palette.accentSoftBorder),
                ),
                alignment: Alignment.center,
                child: Icon(LucideIcons.sparkles,
                    size: 18, color: palette.accentText),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Доступна версия ${info.version}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      installing
                          ? 'Запускаем установщик — Verge закроется и '
                              'обновится'
                          : downloading
                              ? 'Загружаем обновление…'
                              : 'Новая версия Verge готова к установке',
                      style: theme.textTheme.muted.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (downloading || installing)
            _Progress(value: installing ? null : progress)
          else ...[
            if (error != null) ...[
              Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: BoxDecoration(
                  color: palette.dangerSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Не удалось скачать: $error',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: palette.dangerText),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                ShadButton(
                  size: ShadButtonSize.sm,
                  backgroundColor: palette.accent,
                  hoverBackgroundColor: palette.accent.withValues(alpha: 0.88),
                  foregroundColor: const Color(0xFFFFFFFF),
                  hoverForegroundColor: const Color(0xFFFFFFFF),
                  onPressed: c.downloadAndInstallUpdate,
                  leading: Icon(
                    error != null ? LucideIcons.rotateCw : LucideIcons.download,
                    size: 15,
                  ),
                  child: Text(error != null ? 'Повторить' : 'Обновить'),
                ),
                if (!inline) ...[
                  const SizedBox(width: 6),
                  ShadButton.ghost(
                    size: ShadButtonSize.sm,
                    onPressed: c.dismissUpdateBanner,
                    child: const Text('Позже'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            // Второстепенные ссылки — отдельной строкой, чтобы основные
            // кнопки не теснились; Wrap — на случай крупного шрифта.
            Wrap(
              spacing: 16,
              children: [
                if (info.releaseUrl.isNotEmpty)
                  ShadButton.link(
                    size: ShadButtonSize.sm,
                    padding: EdgeInsets.zero,
                    foregroundColor: palette.accentText,
                    onPressed: () => openLink(info.releaseUrl),
                    trailing: const Icon(LucideIcons.arrowUpRight, size: 14),
                    child: const Text('Что нового'),
                  ),
                ShadButton.link(
                  size: ShadButtonSize.sm,
                  padding: EdgeInsets.zero,
                  foregroundColor: theme.colorScheme.mutedForeground,
                  onPressed: () => c.skipUpdateVersion(),
                  child: const Text('Пропустить версию'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Полоса загрузки с процентом. [value] == null — неопределённый прогресс
/// (размер файла неизвестен или идёт запуск установщика).
class _Progress extends StatelessWidget {
  const _Progress({required this.value});

  final double? value;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final palette = VergePalette.of(context);
    // 0 приходит до первого чанка — показываем «бегущую» полосу, а не пустую.
    final v = value == null || value == 0 ? null : value!.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            // Плавно доезжаем до нового процента, без рывков по чанкам.
            tween: Tween(end: v ?? 0),
            duration: const Duration(milliseconds: 300),
            builder: (context, animated, _) => LinearProgressIndicator(
              value: v == null ? null : animated,
              minHeight: 6,
              backgroundColor: palette.chip,
              color: palette.accent,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Spinner(size: 13, color: theme.colorScheme.mutedForeground),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value == null ? 'Устанавливаем…' : 'Скачиваем',
                style: theme.textTheme.muted.copyWith(fontSize: 12),
              ),
            ),
            if (v != null)
              Text(
                '${(v * 100).round()}%',
                style: monoStyle(
                    fontSize: 12, color: theme.colorScheme.foreground),
              ),
          ],
        ),
      ],
    );
  }
}
