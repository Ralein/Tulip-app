import 'dart:math' as math;
import 'package:flutter/material.dart';

class SunWidget extends StatefulWidget {
  final double size;

  const SunWidget({
    super.key,
    this.size = 80.0,
  });

  @override
  State<SunWidget> createState() => _SunWidgetState();
}

class _SunWidgetState extends State<SunWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _SunPainter(
            rotation: _controller.value * math.pi * 2,
            glow: 0.9 + math.sin(_controller.value * math.pi * 6) * 0.1,
          ),
        );
      },
    );
  }
}

class _SunPainter extends CustomPainter {
  final double rotation;
  final double glow;

  _SunPainter({
    required this.rotation,
    required this.glow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.28 * glow;

    // 1. Draw glowing outer halo
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF59D).withOpacity(0.4),
          const Color(0xFFFFD54F).withOpacity(0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 2.2))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 2.2, glowPaint);

    // 2. Draw Sun center
    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF9C4), // Golden core
          const Color(0xFFFFD54F), // Amber
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, sunPaint);

    // 3. Draw Rays (rotating)
    final rayPaint = Paint()
      ..color = const Color(0xFFFFD54F).withOpacity(0.7)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final int numRays = 8;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    for (int i = 0; i < numRays; i++) {
      final angle = (i * 2 * math.pi) / numRays;
      final startRadius = radius + 6.0;
      final endRadius = radius + 15.0;

      final startOffset = Offset(math.cos(angle) * startRadius, math.sin(angle) * startRadius);
      final endOffset = Offset(math.cos(angle) * endRadius, math.sin(angle) * endRadius);

      canvas.drawLine(startOffset, endOffset, rayPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
