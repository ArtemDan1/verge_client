import 'package:flutter/widgets.dart';

/// Фирменный знак Verge — «галочка-V» из дизайна (Verge Icons).
/// Путь из исходного SVG (viewBox 0 0 1024 1024): M 184 240 L 512 784 L 840 240.
class VergeMark extends StatelessWidget {
  const VergeMark({super.key, this.size = 26, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _VergeMarkPainter(color),
    );
  }
}

class _VergeMarkPainter extends CustomPainter {
  const _VergeMarkPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Масштаб из исходного viewBox 1024 в текущий размер.
    final s = size.width / 1024.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 144 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final path = Path()
      ..moveTo(184 * s, 240 * s)
      ..lineTo(512 * s, 784 * s)
      ..lineTo(840 * s, 240 * s);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_VergeMarkPainter old) => old.color != color;
}

/// Логотип в шапке сайдбара: тёмный плиточный знак + вордмарк «Verge».
class VergeLogo extends StatelessWidget {
  const VergeLogo({super.key, required this.titleColor});

  /// Цвет надписи «Verge» — берётся из темы, чтобы читалось в light/dark.
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    // Знак остаётся брендовым (тёмная плитка + светлая V) в обеих темах,
    // повторяя app-иконку.
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF09090B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF27272A)),
          ),
          alignment: Alignment.center,
          child: const VergeMark(size: 24, color: Color(0xFFFAFAFA)),
        ),
        const SizedBox(width: 12),
        Text(
          'Verge',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            height: 1.1,
            color: titleColor,
          ),
        ),
      ],
    );
  }
}
