import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/platform/process_names.dart';

void main() {
  test('имена процессов соответствуют платформе', () {
    if (Platform.isWindows) {
      expect(xrayProcessName, 'xray.exe');
      expect(singboxTestProcessName, 'sing-box-test.exe');
    } else {
      expect(xrayProcessName, 'xray');
      expect(singboxTestProcessName, 'sing-box-test');
    }
  });
}
