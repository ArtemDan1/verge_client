import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/app/hotkey.dart';

void main() {
  group('HotkeySpec', () {
    test('строка туда и обратно', () {
      const spec = HotkeySpec(key: 'V', ctrl: true, alt: true);
      expect(spec.toString(), 'ctrl+alt+V');
      expect(HotkeySpec.tryParse('ctrl+alt+V'), spec);
      expect(HotkeySpec.tryParse('alt+ctrl+V'), spec);
    });

    test('мусор и пустое не разбираются', () {
      expect(HotkeySpec.tryParse(''), isNull);
      expect(HotkeySpec.tryParse('V'), isNull);
      expect(HotkeySpec.tryParse('ctrl+Escape'), isNull);
      expect(HotkeySpec.tryParse('hyper+V'), isNull);
    });

    test('без Ctrl/Alt/Cmd допускаются только F-клавиши', () {
      expect(HotkeySpec.tryParse('shift+V'), isNull);
      expect(HotkeySpec.tryParse('shift+F'), isNull);
      expect(HotkeySpec.tryParse('shift+F9'), isNotNull);
      expect(const HotkeySpec(key: 'F5').isValid, isTrue);
    });

    test('клавиша из нажатия — физическая, модификаторы любой стороны', () {
      final spec = HotkeySpec.fromKey(PhysicalKeyboardKey.keyV, {
        LogicalKeyboardKey.controlRight,
        LogicalKeyboardKey.altLeft,
      });
      expect(spec, const HotkeySpec(key: 'V', ctrl: true, alt: true));
      expect(
        HotkeySpec.fromKey(PhysicalKeyboardKey.shiftLeft, {
          LogicalKeyboardKey.shiftLeft,
        }),
        isNull,
      );
    });

    test('подпись по платформе', () {
      const spec = HotkeySpec(key: 'V', ctrl: true, shift: true, meta: true);
      expect(spec.label(platform: TargetPlatform.macOS), '⌃⇧⌘V');
      expect(spec.label(platform: TargetPlatform.windows), 'Ctrl+Shift+Win+V');
    });
  });
}
