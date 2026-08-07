import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/theme/app_colors.dart';
import 'package:singbox_client/ui/widgets/ping_badge.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

Color? _fillOf(WidgetTester t, Finder container) {
  final box = t.widget<AnimatedContainer>(container);
  return (box.decoration as BoxDecoration?)?.color;
}

void main() {
  testWidgets('shows loader when pinging', (t) async {
    await t.pumpWidget(_wrap(const PingBadge(loading: true)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows latency as filled chip colored by threshold', (t) async {
    await t.pumpWidget(_wrap(const PingBadge(latencyMs: 80)));
    expect(find.text('80 мс'), findsOneWidget);
    expect(_fillOf(t, find.byKey(const Key('pingBadgeChip'))),
        AppColors.pingGood);
  });

  testWidgets('shows node timeout as danger chip', (t) async {
    await t.pumpWidget(_wrap(const PingBadge(timedOut: true)));
    expect(find.text('таймаут'), findsOneWidget);
    expect(_fillOf(t, find.byKey(const Key('pingBadgeChip'))),
        AppColors.pingBad);
  });

  testWidgets('shows node error as danger chip', (t) async {
    await t.pumpWidget(_wrap(const PingBadge(error: true)));
    expect(find.text('ошибка'), findsOneWidget);
    expect(_fillOf(t, find.byKey(const Key('pingBadgeChip'))),
        AppColors.pingBad);
  });

  testWidgets(
      'noInternet takes priority over latencyMs and shows "нет интернета"',
      (t) async {
    await t
        .pumpWidget(_wrap(const PingBadge(latencyMs: 80, noInternet: true)));
    expect(find.text('нет интернета'), findsOneWidget);
    expect(find.text('80 мс'), findsNothing);
    expect(_fillOf(t, find.byKey(const Key('pingBadgeChip'))),
        AppColors.pingBad);
  });

  // Без интернета «таймаут» до ноды ничего не объясняет: показываем причину
  // верхнего уровня.
  testWidgets('noInternet takes priority over node timeout', (t) async {
    await t.pumpWidget(
        _wrap(const PingBadge(timedOut: true, noInternet: true)));
    expect(find.text('нет интернета'), findsOneWidget);
    expect(find.text('таймаут'), findsNothing);
  });

  testWidgets('кликабельный чип подсвечивается при наведении', (t) async {
    await t.pumpWidget(_wrap(PingBadge(latencyMs: 80, onTap: () {})));
    final chip = find.byKey(const Key('pingBadgeChip'));
    final plain = _fillOf(t, chip);

    final gesture =
        await t.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(t.getCenter(chip));
    await t.pumpAndSettle();

    expect(_fillOf(t, chip), isNot(plain));
  });

  testWidgets('без onTap наведение ничего не меняет', (t) async {
    await t.pumpWidget(_wrap(const PingBadge(latencyMs: 80)));
    final chip = find.byKey(const Key('pingBadgeChip'));
    final plain = _fillOf(t, chip);

    final gesture = await t.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(t.getCenter(chip));
    await t.pumpAndSettle();

    expect(_fillOf(t, chip), plain);
  });

  testWidgets('empty when no data', (t) async {
    await t.pumpWidget(_wrap(const PingBadge()));
    expect(find.textContaining('мс'), findsNothing);
    expect(find.byKey(const Key('pingBadgeChip')), findsNothing);
  });
}
