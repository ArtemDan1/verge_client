import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../app/app_controller.dart';
import '../../models/app_settings.dart';
import 'general_section.dart';

/// Вкл/выкл и интервал фонового пинга gstatic (бейдж у таймера). Независим
/// от Автовыбора — просто индикатор активного соединения.
class GstaticPingSection extends StatefulWidget {
  const GstaticPingSection({super.key, required this.controller});
  final AppController controller;

  @override
  State<GstaticPingSection> createState() => _GstaticPingSectionState();
}

class _GstaticPingSectionState extends State<GstaticPingSection> {
  // Локальное отображаемое значение во время протаскивания слайдера — чтобы
  // подпись менялась вживую, не дожидаясь commit на onChangeEnd.
  int? _dragging;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final s = c.settings;
    final theme = ShadTheme.of(context);
    final shownInterval = _dragging ?? s.gstaticPingIntervalSeconds;
    return SettingsSection(
      title: 'Пинг активного соединения',
      description: 'Бейдж задержки до gstatic рядом с таймером подключения',
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Показывать пинг', style: theme.textTheme.large),
            ),
            ShadSwitch(
              value: s.gstaticPingEnabled,
              onChanged: (v) =>
                  c.updateSettings(s.copyWith(gstaticPingEnabled: v)),
            ),
          ],
        ),
        if (s.gstaticPingEnabled) ...[
          const SizedBox(height: 16),
          Text('Интервал обновления, $shownInterval с',
              style: theme.textTheme.muted),
          const SizedBox(height: 8),
          ShadSlider(
            initialValue: s.gstaticPingIntervalSeconds.toDouble(),
            min: AppSettings.minGstaticPingIntervalSeconds.toDouble(),
            max: AppSettings.maxGstaticPingIntervalSeconds.toDouble(),
            divisions: (AppSettings.maxGstaticPingIntervalSeconds -
                    AppSettings.minGstaticPingIntervalSeconds) ~/
                5,
            onChanged: (v) => setState(() => _dragging = v.round()),
            onChangeEnd: (v) {
              setState(() => _dragging = null);
              c.updateSettings(
                  s.copyWith(gstaticPingIntervalSeconds: v.round()));
            },
          ),
        ],
      ],
    );
  }
}
