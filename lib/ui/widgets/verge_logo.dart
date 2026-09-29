import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Фирменный знак Verge «Бумага»: плитка, чернильная V и кобальтовая
/// черта-основание. Геометрия из исходного SVG (viewBox 0 0 1024 1024,
/// assets/branding/verge-app-icon-*.svg).
class VergeMark extends StatelessWidget {
  const VergeMark({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = ShadTheme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      size: Size.square(size),
      painter: _VergeMarkPainter(
        tile: dark ? const Color(0xFF26241F) : const Color(0xFFFBFAF7),
        border: dark ? const Color(0xFF3A3832) : const Color(0xFFDEDBD2),
        ink: dark ? const Color(0xFFEDEBE5) : const Color(0xFF1C1B18),
        bar: dark ? const Color(0xFF5C80FF) : const Color(0xFF2E5BFF),
      ),
    );
  }
}

class _VergeMarkPainter extends CustomPainter {
  const _VergeMarkPainter({
    required this.tile,
    required this.border,
    required this.ink,
    required this.bar,
  });

  final Color tile;
  final Color border;
  final Color ink;
  final Color bar;

  @override
  void paint(Canvas canvas, Size size) {
    // Масштаб из исходного viewBox 1024 в текущий размер.
    final s = size.width / 1024.0;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(230 * s));
    canvas.drawRRect(rrect, Paint()..color = tile);
    // На мелких размерах обводку утолщаем, иначе она пропадает.
    final borderWidth = (24 * s).clamp(1.0, double.infinity);
    canvas.drawRRect(
      rrect.deflate(borderWidth / 2),
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );

    final v = Path()
      ..moveTo(224 * s, 260 * s)
      ..lineTo(512 * s, 740 * s)
      ..lineTo(800 * s, 260 * s);
    canvas.drawPath(
      v,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 136 * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(304 * s, 832 * s, 416 * s, 64 * s),
        Radius.circular(32 * s),
      ),
      Paint()..color = bar,
    );
  }

  @override
  bool shouldRepaint(_VergeMarkPainter old) =>
      old.tile != tile ||
      old.border != border ||
      old.ink != ink ||
      old.bar != bar;
}

/// Логотип в шапке сайдбара: знак + вордмарк «Verge».
class VergeLogo extends StatelessWidget {
  const VergeLogo({super.key, required this.titleColor});

  /// Цвет надписи «Verge» — берётся из темы, чтобы читалось в light/dark.
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const VergeMark(size: 32),
        const SizedBox(width: 10),
        Text(
          'Verge',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            height: 1.1,
            color: titleColor,
          ),
        ),
      ],
    );
  }
}
