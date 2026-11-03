import 'dart:convert';

/// Описание устройства для панелей подписок (Remnawave и др.): по заголовкам
/// x-device-os / x-ver-os / x-device-model они показывают устройство в списке
/// HWID-устройств пользователя. Без них там «неизвестное устройство».
class DeviceInfo {
  final String os;
  final String osVersion;
  final String model;
  const DeviceInfo({required this.os, this.osVersion = '', this.model = ''});

  Map<String, String> get headers {
    final os = _clean(this.os), ver = _clean(osVersion), model = _clean(this.model);
    return {
      if (os.isNotEmpty) 'x-device-os': os,
      if (ver.isNotEmpty) 'x-ver-os': ver,
      if (model.isNotEmpty) 'x-device-model': model,
    };
  }

  /// В HTTP-заголовке допустим только печатный ASCII; длину режем, чтобы
  /// мусор из реестра/system_profiler не раздувал запрос.
  static String _clean(String s) {
    final ascii = s.replaceAll(RegExp(r'[^\x20-\x7E]'), '').trim();
    return ascii.length > 64 ? ascii.substring(0, 64).trim() : ascii;
  }
}

/// «Version 15.6 (Build 24G84)» → «15.6»;
/// «"Windows 11 Pro" 10.0 (Build 26100)» → «10.0.26100».
String parseOsVersion(String raw) {
  final base = RegExp(r'(\d+(?:\.\d+)+)').firstMatch(raw)?.group(1) ?? '';
  if (base.isEmpty) return '';
  final build = RegExp(r'Build (\d+)\)').firstMatch(raw)?.group(1);
  return build != null ? '$base.$build' : base;
}

/// Из JSON `system_profiler SPHardwareDataType -json`:
/// «MacBook Air (MacBookAir10,1)». Голый идентификатор вроде «Mac14,2»
/// человеку ничего не говорит, а одно имя не различает поколения.
String parseMacModel(String? json) {
  if (json == null) return '';
  try {
    final items = (jsonDecode(json) as Map)['SPHardwareDataType'] as List;
    final hw = items.first as Map;
    final name = (hw['machine_name'] as String?)?.trim() ?? '';
    final id = (hw['machine_model'] as String?)?.trim() ?? '';
    if (name.isEmpty) return id;
    return id.isEmpty ? name : '$name ($id)';
  } catch (_) {
    return '';
  }
}

/// Производитель + модель из BIOS-ветки реестра Windows. OEM-заглушки
/// («To be filled by O.E.M.» и т. п.) выбрасываем: лучше ничего, чем это.
String windowsModel(String manufacturer, String product) {
  const junk = {
    'to be filled by o.e.m.', 'system product name', 'system manufacturer',
    'default string', 'not applicable', 'none',
  };
  return [manufacturer.trim(), product.trim()]
      .where((s) => s.isNotEmpty && !junk.contains(s.toLowerCase()))
      .join(' ');
}
