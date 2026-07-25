import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/theme/app_colors.dart';
import 'package:singbox_client/ui/widgets/ping_badge.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows loader when pinging', (t) async {
    await t.pumpWidget(_wrap(const PingBadge(loading: true)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows latency with color', (t) async {
    await t.pumpWidget(_wrap(const PingBadge(latencyMs: 80)));
    expect(find.text('80 мс'), findsOneWidget);
    final txt = t.widget<Text>(find.text('80 мс'));
    expect(txt.style?.color, AppColors.pingGood);
  });

  testWidgets('shows timeout', (t) async {
    await t.pumpWidget(_wrap(const PingBadge(timedOut: true)));
    expect(find.text('таймаут'), findsOneWidget);
  });

  testWidgets('empty when no data', (t) async {
    await t.pumpWidget(_wrap(const PingBadge()));
    expect(find.textContaining('мс'), findsNothing);
  });
}
