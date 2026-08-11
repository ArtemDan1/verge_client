import 'dart:io';

/// Имена процессов для правил `find_process` в sing-box.
///
/// Windows возвращает имя исполняемого файла с расширением, macOS — без него.
/// Правила строятся один раз при сборке конфига, поэтому константы вычисляются
/// на старте и дальше не меняются.
final String xrayProcessName = Platform.isWindows ? 'xray.exe' : 'xray';
final String singboxTestProcessName =
    Platform.isWindows ? 'sing-box-test.exe' : 'sing-box-test';
