import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/services/device_info.dart';

void main() {
  group('parseOsVersion', () {
    test('macOS', () {
      expect(parseOsVersion('Version 15.6 (Build 24G84)'), '15.6');
    });
    test('Windows — с номером сборки', () {
      expect(parseOsVersion('"Windows 11 Pro" 10.0 (Build 26100)'), '10.0.26100');
    });
    test('без версии → пусто', () {
      expect(parseOsVersion('unknown'), '');
    });
  });

  group('parseMacModel', () {
    test('имя + идентификатор', () {
      const json = '{"SPHardwareDataType":[{"machine_name":"MacBook Air",'
          '"machine_model":"MacBookAir10,1"}]}';
      expect(parseMacModel(json), 'MacBook Air (MacBookAir10,1)');
    });
    test('только идентификатор', () {
      expect(parseMacModel('{"SPHardwareDataType":[{"machine_model":"Mac14,2"}]}'),
          'Mac14,2');
    });
    test('мусор / null → пусто', () {
      expect(parseMacModel('not json'), '');
      expect(parseMacModel(null), '');
    });
  });

  test('windowsModel склеивает и выкидывает OEM-заглушки', () {
    expect(windowsModel('LENOVO', '20XW0026RT'), 'LENOVO 20XW0026RT');
    expect(windowsModel('To be filled by O.E.M.', 'B450M DS3H'), 'B450M DS3H');
    expect(windowsModel('', ''), '');
  });

  group('DeviceInfo.headers', () {
    test('пустые поля не отправляются', () {
      expect(const DeviceInfo(os: 'Windows').headers, {'x-device-os': 'Windows'});
    });
    test('не-ASCII вычищается, длина ограничена', () {
      final h = DeviceInfo(os: 'macOS', model: 'Мак ${'x' * 100}').headers;
      expect(h['x-device-model'], 'x' * 64);
    });
  });
}
