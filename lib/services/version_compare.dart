/// Сравнивает версии вида "1.2.3", "v1.2.0", "1.0.0+5".
/// -1 если a<b, 0 если равны, 1 если a>b. Недостающие компоненты = 0.
int compareVersions(String a, String b) {
  final pa = _parse(a);
  final pb = _parse(b);
  final len = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < len; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x < y ? -1 : 1;
  }
  return 0;
}

List<int> _parse(String v) {
  var s = v.trim();
  if (s.startsWith('v') || s.startsWith('V')) s = s.substring(1);
  final plus = s.indexOf('+');
  if (plus >= 0) s = s.substring(0, plus);
  return s.split('.').map((p) => int.tryParse(p.trim()) ?? 0).toList();
}
