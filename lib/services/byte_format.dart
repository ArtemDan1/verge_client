const _units = ['B', 'KB', 'MB', 'GB', 'TB'];

/// Человекочитаемый объём. Байты — без дробной части (иначе «512.0 B»
/// выглядит шумно), начиная с KB — один знак, как в Karing.
String formatBytes(int bytes) {
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < _units.length - 1) {
    value /= 1024;
    unit++;
  }
  if (unit == 0) return '${value.toInt()} B';
  return '${value.toStringAsFixed(1)} ${_units[unit]}';
}

String formatSpeed(int bytesPerSecond) => '${formatBytes(bytesPerSecond)}/s';

/// H:MM:SS. Часы без ведущего нуля — счётчик в карточке узкий.
String formatDuration(Duration d) {
  final total = d.isNegative ? 0 : d.inSeconds;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
