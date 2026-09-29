import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/app/tray_popover_controller.dart';
import 'package:singbox_client/app/window_control_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('window/control');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;
  late DateTime now;

  setUp(() {
    calls = [];
    now = DateTime(2026, 9, 28, 12);
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  TrayPopoverController build() => TrayPopoverController(
        WindowControlChannel(channel),
        waitForFrame: () async {},
        now: () => now,
      );

  /// Имитирует вызов из нативной части (мини-окно закрылось само).
  Future<void> nativeDismiss() => messenger.handlePlatformMessage(
        'window/control',
        const StandardMethodCodec()
            .encodeMethodCall(const MethodCall('popoverDismissed')),
        (_) {},
      );

  test('клик по значку открывает мини-окно нужного размера', () async {
    final p = build();
    await p.toggle(420);
    expect(p.isOpen, isTrue);
    expect(calls.single.method, 'showPopover');
    expect(calls.single.arguments,
        {'width': TrayPopoverController.width, 'height': 420.0});
  });

  test('повторный клик закрывает, не открывая главное окно', () async {
    final p = build();
    await p.toggle(420);
    await p.toggle(420);
    expect(p.isOpen, isFalse);
    expect(calls.last.method, 'hidePopover');
    expect(calls.last.arguments, {'openMain': false});
  });

  test('«Открыть Verge» из мини-окна возвращает главное окно', () async {
    final p = build();
    await p.toggle(420);
    await p.openMain();
    expect(p.isOpen, isFalse);
    expect(calls.last.arguments, {'openMain': true});
  });

  test('«Открыть Verge» без мини-окна просто показывает окно', () async {
    final p = build();
    await p.openMain();
    expect(calls.single.method, 'show');
  });

  test('закрытие нативной стороной переключает интерфейс обратно', () async {
    final p = build();
    await p.toggle(420);
    await nativeDismiss();
    expect(p.isOpen, isFalse);
  });

  test('клик по значку сразу после закрытия по фокусу не открывает заново',
      () async {
    final p = build();
    await p.toggle(420);
    // Клик по значку: сначала окно теряет фокус и закрывается, затем
    // приходит сам клик.
    await nativeDismiss();
    now = now.add(const Duration(milliseconds: 100));
    await p.toggle(420);
    expect(p.isOpen, isFalse);

    // Через секунду клик снова открывает.
    now = now.add(const Duration(seconds: 1));
    await p.toggle(420);
    expect(p.isOpen, isTrue);
  });
}
