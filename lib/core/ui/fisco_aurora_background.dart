import 'dart:math' as math;
import 'package:flutter/material.dart';

class FiscoAuroraBackground extends StatefulWidget {
  const FiscoAuroraBackground({
    super.key,
    this.child,
    this.intensity = 1.0,
  });

  final Widget? child;
  final double intensity;

  @override
  State<FiscoAuroraBackground> createState() => _FiscoAuroraBackgroundState();
}

class _FiscoAuroraBackgroundState extends State<FiscoAuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value * math.pi * 2;
        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF05080F),
                    Color(0xFF0A1220),
                    Color(0xFF071018),
                  ],
                ),
              ),
            ),
            CustomPaint(
              painter: _AuroraPainter(t: t, intensity: widget.intensity),
              size: Size.infinite,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.28),
                    Colors.black.withValues(alpha: 0.48),
                    Colors.black.withValues(alpha: 0.58),
                  ],
                ),
              ),
            ),
            if (widget.child != null) widget.child!,
          ],
        );
      },
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({required this.t, required this.intensity});
  final double t;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final i = intensity.clamp(0.3, 1.4);

    void blob(Offset c, double r, List<Color> colors) {
      final rect = Rect.fromCircle(center: c, radius: r);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: colors,
          stops: const [0.0, 0.45, 1.0],
        ).createShader(rect);
      canvas.drawCircle(c, r, paint);
    }

    blob(
      Offset(w * (0.22 + 0.08 * math.sin(t)), h * (0.28 + 0.06 * math.cos(t * 0.9))),
      w * 0.42 * i,
      [const Color(0x6622D3C5), const Color(0x221A9E8F), Colors.transparent],
    );
    blob(
      Offset(w * (0.78 + 0.06 * math.cos(t * 1.1)), h * (0.35 + 0.08 * math.sin(t * 0.8))),
      w * 0.38 * i,
      [const Color(0x553B6CFF), const Color(0x221A2A6C), Colors.transparent],
    );
    blob(
      Offset(w * (0.50 + 0.10 * math.sin(t * 0.7)), h * (0.78 + 0.05 * math.cos(t * 1.2))),
      w * 0.48 * i,
      [const Color(0x4400C48A), const Color(0x1800A070), Colors.transparent],
    );

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    for (var k = 0; k < 7; k++) {
      final y = h * (0.15 + k * 0.12) + 6 * math.sin(t + k);
      canvas.drawLine(Offset(0, y), Offset(w, y), linePaint);
    }
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 1;
    const step = 48.0;
    for (double x = 0; x < w; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), grid);
    }
    for (double y = 0; y < h; y += step) {
      canvas.drawLine(Offset(0, y), Offset(w, y), grid);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) =>
      old.t != t || old.intensity != intensity;
}
