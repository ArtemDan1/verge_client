import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app_controller.dart';

/// Сочетание клавиш глобальной горячей клавиши.
///
/// Хранится строкой `ctrl+alt+shift+meta+V` (модификаторы в этом порядке,
/// клавиша последней). Клавиша — физическая, а не символ: на русской
/// раскладке Ctrl+Alt+V остаётся тем же сочетанием, а не превращается в «М».
/// `meta` — Cmd на macOS и Win на Windows.
@immutable
class HotkeySpec {
  const HotkeySpec({
    required this.key,
    this.ctrl = false,
    this.alt = false,
    this.shift = false,
    this.meta = false,
  });

  /// `A`–`Z`, `0`–`9`, `F1`–`F12` или `Space`.
  final String key;
  final bool ctrl;
  final bool alt;
  final bool shift;
  final bool meta;

  /// Физические клавиши, которые можно назначить, и их имена в спецификации.
  static final Map<PhysicalKeyboardKey, String> keys = {
    for (var i = 0; i < 26; i++) _letters[i]: String.fromCharCode(0x41 + i),
    for (var i = 0; i < 10; i++) _digits[i]: '$i',
    for (var i = 0; i < 12; i++) _functionKeys[i]: 'F${i + 1}',
    PhysicalKeyboardKey.space: 'Space',
  };

  static const _letters = [
    PhysicalKeyboardKey.keyA,
    PhysicalKeyboardKey.keyB,
    PhysicalKeyboardKey.keyC,
    PhysicalKeyboardKey.keyD,
    PhysicalKeyboardKey.keyE,
    PhysicalKeyboardKey.keyF,
    PhysicalKeyboardKey.keyG,
    PhysicalKeyboardKey.keyH,
    PhysicalKeyboardKey.keyI,
    PhysicalKeyboardKey.keyJ,
    PhysicalKeyboardKey.keyK,
    PhysicalKeyboardKey.keyL,
    PhysicalKeyboardKey.keyM,
    PhysicalKeyboardKey.keyN,
    PhysicalKeyboardKey.keyO,
    PhysicalKeyboardKey.keyP,
    PhysicalKeyboardKey.keyQ,
    PhysicalKeyboardKey.keyR,
    PhysicalKeyboardKey.keyS,
    PhysicalKeyboardKey.keyT,
    PhysicalKeyboardKey.keyU,
    PhysicalKeyboardKey.keyV,
    PhysicalKeyboardKey.keyW,
    PhysicalKeyboardKey.keyX,
    PhysicalKeyboardKey.keyY,
    PhysicalKeyboardKey.keyZ,
  ];
  static const _digits = [
    PhysicalKeyboardKey.digit0,
    PhysicalKeyboardKey.digit1,
    PhysicalKeyboardKey.digit2,
    PhysicalKeyboardKey.digit3,
    PhysicalKeyboardKey.digit4,
    PhysicalKeyboardKey.digit5,
    PhysicalKeyboardKey.digit6,
    PhysicalKeyboardKey.digit7,
    PhysicalKeyboardKey.digit8,
    PhysicalKeyboardKey.digit9,
  ];
  static const _functionKeys = [
    PhysicalKeyboardKey.f1,
    PhysicalKeyboardKey.f2,
    PhysicalKeyboardKey.f3,
    PhysicalKeyboardKey.f4,
    PhysicalKeyboardKey.f5,
    PhysicalKeyboardKey.f6,
    PhysicalKeyboardKey.f7,
    PhysicalKeyboardKey.f8,
    PhysicalKeyboardKey.f9,
    PhysicalKeyboardKey.f10,
    PhysicalKeyboardKey.f11,
    PhysicalKeyboardKey.f12,
  ];

  /// Разбор строки из настроек; null — пусто или мусор.
  static HotkeySpec? tryParse(String value) {
    final parts = value.split('+').map((p) => p.trim()).toList();
    if (parts.length < 2) return null;
    final key = parts.removeLast();
    if (!keys.containsValue(key)) return null;
    final mods = parts.map((p) => p.toLowerCase()).toSet();
    if (mods.any((m) => !const {'ctrl', 'alt', 'shift', 'meta'}.contains(m))) {
      return null;
    }
    final spec = HotkeySpec(
      key: key,
      ctrl: mods.contains('ctrl'),
      alt: mods.contains('alt'),
      shift: mods.contains('shift'),
      meta: mods.contains('meta'),
    );
    return spec.isValid ? spec : null;
  }

  /// Сочетание из нажатой клавиши и зажатых модификаторов; null — клавишу
  /// назначить нельзя (модификатор сам по себе, стрелки и т.п.).
  static HotkeySpec? fromKey(
    PhysicalKeyboardKey physical,
    Set<LogicalKeyboardKey> pressed,
  ) {
    final key = keys[physical];
    if (key == null) return null;
    bool any(Set<LogicalKeyboardKey> set) => pressed.any(set.contains);
    return HotkeySpec(
      key: key,
      ctrl: any(
        LogicalKeyboardKey.expandSynonyms({LogicalKeyboardKey.control}),
      ),
      alt: any(LogicalKeyboardKey.expandSynonyms({LogicalKeyboardKey.alt})),
      shift: any(LogicalKeyboardKey.expandSynonyms({LogicalKeyboardKey.shift})),
      meta: any(LogicalKeyboardKey.expandSynonyms({LogicalKeyboardKey.meta})),
    );
  }

  /// Глобальное сочетание без Ctrl/Alt/Cmd перехватывало бы обычный ввод
  /// во всех приложениях — такие не принимаем. Исключение — F-клавиши: для
  /// набора текста они не нужны.
  bool get isValid => ctrl || alt || meta || RegExp(r'^F\d+$').hasMatch(key);

  @override
  String toString() => [
    if (ctrl) 'ctrl',
    if (alt) 'alt',
    if (shift) 'shift',
    if (meta) 'meta',
    key,
  ].join('+');

  /// Подпись для интерфейса в привычной для платформы записи.
  String label({TargetPlatform? platform}) {
    final mac = (platform ?? defaultTargetPlatform) == TargetPlatform.macOS;
    if (mac) {
      return [
        if (ctrl) '⌃',
        if (alt) '⌥',
        if (shift) '⇧',
        if (meta) '⌘',
        key,
      ].join();
    }
    return [
      if (ctrl) 'Ctrl',
      if (alt) 'Alt',
      if (shift) 'Shift',
      if (meta) 'Win',
      key,
    ].join('+');
  }

  Map<String, Object> toArguments() => {
    'key': key,
    'ctrl': ctrl,
    'alt': alt,
    'shift': shift,
    'meta': meta,
  };

  @override
  bool operator ==(Object other) =>
      other is HotkeySpec &&
      other.key == key &&
      other.ctrl == ctrl &&
      other.alt == alt &&
      other.shift == shift &&
      other.meta == meta;

  @override
  int get hashCode => Object.hash(key, ctrl, alt, shift, meta);
}

/// Нативная регистрация глобальной горячей клавиши: на macOS — Carbon
/// RegisterEventHotKey (не требует разрешения «Универсальный доступ»), на
/// Windows — RegisterHotKey.
class HotkeyChannel {
  HotkeyChannel([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel('verge/hotkey');

  final MethodChannel _channel;

  /// Назначить сочетание вместо прежнего. false — система его не отдала
  /// (занято другим приложением).
  Future<bool> register(HotkeySpec spec) async =>
      await _channel.invokeMethod<bool>('register', spec.toArguments()) ??
      false;

  Future<void> unregister() => _channel.invokeMethod('unregister');

  void onPressed(VoidCallback callback) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'pressed') callback();
      return null;
    });
  }
}

/// Держит глобальную горячую клавишу в соответствии с настройками и по
/// нажатию подключает или отключает VPN. Если система сочетание не отдала,
/// сообщает контроллеру — настройки покажут предупреждение.
class HotkeyService {
  HotkeyService(this._controller, [HotkeyChannel? channel])
    : _channel = channel ?? HotkeyChannel();

  final AppController _controller;
  final HotkeyChannel _channel;
  String? _applied;
  Future<void> _pending = Future.value();

  Future<void> init() async {
    _channel.onPressed(() => _controller.toggleConnection().ignore());
    _controller.addListener(_sync);
    _sync();
    await _pending;
  }

  void _sync() {
    final value = _controller.settings.toggleHotkey;
    if (value == _applied) return;
    _applied = value;
    // Последовательно: быстрые смены сочетания не должны обгонять друг друга.
    _pending = _pending.then((_) => _apply(value));
  }

  Future<void> _apply(String value) async {
    final spec = HotkeySpec.tryParse(value);
    var failed = false;
    try {
      if (spec == null) {
        await _channel.unregister();
      } else {
        failed = !await _channel.register(spec);
      }
    } on MissingPluginException {
      // Платформа без нативной части (тесты, Linux) — тихо ничего не делаем.
    } on PlatformException {
      failed = spec != null;
    }
    _controller.setHotkeyFailed(failed);
  }

  void dispose() => _controller.removeListener(_sync);
}
