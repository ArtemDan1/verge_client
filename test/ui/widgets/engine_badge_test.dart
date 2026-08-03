import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:singbox_client/models/node_engine.dart';
import 'package:singbox_client/ui/widgets/engine_badge.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(ShadApp(home: Scaffold(body: child)));

  testWidgets('Xray → XR', (tester) async {
    await pump(tester, const EngineBadge(engine: NodeEngine.xray));
    expect(find.text('XR'), findsOneWidget);
  });

  testWidgets('sing-box → SB', (tester) async {
    await pump(tester, const EngineBadge(engine: NodeEngine.singbox));
    expect(find.text('SB'), findsOneWidget);
  });

  testWidgets('после отката показывает тултип', (tester) async {
    await pump(tester,
        const EngineBadge(engine: NodeEngine.singbox, fellBack: true));
    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, contains('Xray не запустился'));
  });

  testWidgets('ручной выбор отличается от авто визуально', (tester) async {
    await pump(tester, const Column(children: [
      EngineBadge(engine: NodeEngine.xray, manual: true),
      EngineBadge(engine: NodeEngine.xray),
    ]));
    final boxes = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration as BoxDecoration)
        .toList();
    // Ручной — залитый, авто — контурный.
    expect(boxes[0].color, isNotNull);
    expect(boxes[1].color, anyOf(isNull, equals(Colors.transparent)));
    expect(boxes[1].border, isNotNull);
  });
}
