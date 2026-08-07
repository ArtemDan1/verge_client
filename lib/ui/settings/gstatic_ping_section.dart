import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../app/app_controller.dart';
import '../../models/app_settings.dart';
import 'general_section.dart';

/// Вкл/выкл, интервал и адрес фонового пинга активного соединения (бейдж у
/// таймера). Независим от Автовыбора — просто индикатор активного соединения.
class GstaticPingSection extends StatefulWidget {
  const GstaticPingSection({super.key, required this.controller});
  final AppController controller;

  @override
  State<GstaticPingSection> createState() => _GstaticPingSectionState();
}

class _GstaticPingSectionState extends State<GstaticPingSection> {
  late final TextEditingController _interval;
  late final TextEditingController _url;
  final _intervalFocus = FocusNode();
  final _urlFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final s = widget.controller.settings;
    _interval =
        TextEditingController(text: '${s.gstaticPingIntervalSeconds}');
    _url = TextEditingController(text: s.gstaticPingUrl);
    // Коммит и по потере фокуса, а не только по Enter: уход на другой экран
    // забирает фокус, и без этого набранное значение просто терялось.
    _intervalFocus.addListener(() {
      if (!_intervalFocus.hasFocus) _commitInterval(_interval.text);
    });
    _urlFocus.addListener(() {
      if (!_urlFocus.hasFocus) _commitUrl(_url.text);
    });
  }

  @override
  void dispose() {
    // Секцию сносят раньше, чем слушатели успеют сработать (смена экрана
    // размонтирует виджет) — фиксируем набранное здесь же.
    _commitInterval(_interval.text);
    _commitUrl(_url.text);
    _intervalFocus.dispose();
    _urlFocus.dispose();
    _interval.dispose();
    _url.dispose();
    super.dispose();
  }

  void _commitInterval(String raw) {
    final s = widget.controller.settings;
    final parsed = int.tryParse(raw.trim());
    // Мусор и значения вне диапазона откатываем к сохранённому: молча
    // подставлять дефолт хуже, чем оставить как было.
    if (parsed == null || parsed < AppSettings.minGstaticPingIntervalSeconds) {
      _interval.text = '${s.gstaticPingIntervalSeconds}';
      return;
    }
    final value = AppSettings.clampGstaticPingInterval(parsed);
    if (value != parsed) _interval.text = '$value';
    if (value == s.gstaticPingIntervalSeconds) return;
    widget.controller
        .updateSettings(s.copyWith(gstaticPingIntervalSeconds: value));
  }

  void _commitUrl(String raw) {
    final s = widget.controller.settings;
    final value = raw.trim();
    final uri = Uri.tryParse(value);
    if (value.isEmpty || uri == null || !uri.hasScheme || uri.host.isEmpty) {
      _url.text = s.gstaticPingUrl;
      return;
    }
    if (value == s.gstaticPingUrl) return;
    widget.controller.updateSettings(s.copyWith(gstaticPingUrl: value));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final s = c.settings;
    final theme = ShadTheme.of(context);
    return SettingsSection(
      title: 'Пинг активного соединения',
      description: 'Бейдж задержки рядом с таймером подключения',
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
          const SizedBox(height: 20),
          Text('Интервал обновления, с', style: theme.textTheme.large),
          const SizedBox(height: 8),
          ShadInput(
            key: const Key('gstaticPingInterval'),
            controller: _interval,
            focusNode: _intervalFocus,
            keyboardType: TextInputType.number,
            onSubmitted: _commitInterval,
          ),
          const SizedBox(height: 4),
          Text(
            'От ${AppSettings.minGstaticPingIntervalSeconds} до '
            '${AppSettings.maxGstaticPingIntervalSeconds} с, '
            'по умолчанию ${AppSettings.defaultGstaticPingIntervalSeconds}',
            style: theme.textTheme.muted,
          ),
          const SizedBox(height: 20),
          Text('Адрес проверки', style: theme.textTheme.large),
          const SizedBox(height: 8),
          ShadInput(
            key: const Key('gstaticPingUrl'),
            controller: _url,
            onSubmitted: _commitUrl,
          ),
          const SizedBox(height: 4),
          Text(
            'В TUN-режиме до этого адреса проверяется наличие интернета мимо '
            'туннеля; в Proxy — задержка через локальный прокси',
            style: theme.textTheme.muted,
          ),
        ],
      ],
    );
  }
}
