import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:singbox_client/ui/widgets/json_editor.dart';

void main() {
  test('prettyPrintJson форматирует с отступом 2', () {
    expect(prettyPrintJson('{"a":1}'), '{\n  "a": 1\n}');
  });

  test('prettyPrintJson возвращает null на битом JSON', () {
    expect(prettyPrintJson('{"a":'), isNull);
  });

  test('jsonErrorMessage содержит позицию', () {
    final e = () {
      try {
        prettyPrintJsonOrThrow('{"a":');
        return null;
      } on FormatException catch (e) {
        return e;
      }
    }();
    expect(jsonErrorMessage(e!), contains('символ'));
  });

  testWidgets('JsonEditor отдаёт изменённый текст', (tester) async {
    var last = '';
    await tester.pumpWidget(ShadApp(
      home: JsonEditor(
        initialText: '{"a": 1}',
        onChanged: (v) => last = v,
      ),
    ));
    await tester.enterText(find.byType(JsonEditor), '{"b": 2}');
    await tester.pump();
    expect(last, '{"b": 2}');
  });
}
