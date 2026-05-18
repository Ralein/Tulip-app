import 'dart:math' as math;
import 'package:flutter/material.dart';

class TulipPainter extends CustomPainter {
  final Color tulipColor;
  final double swayAngle; // sway angle in radians (e.g. -0.1 to 0.1)
  final double growthProgress; // 0.0 to 1.0 (from sprout to full bloom)
  final double bloomFactor; // 0.0 to 1.0 (how open the petals are)

  TulipPainter({
    required this.tulipColor,
    this.swayAngle = 0.0,
    this.growthProgress = 1.0,
    this.bloomFactor = 0.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (growthProgress <= 0.0) return;

    final double h = size.height * growthProgress;
    final double w = size.width;
    
    // Bottom center of the canvas is the plant root
    final double rootX = w / 2;
    final double rootY = size.height;

    // Sway offsets
    // Calculate sway offset at the top of the stem
    final double swayOffset = math.sin(swayAngle) * (h * 0.4);
    final double flowerX = rootX + swayOffset;
    final double flowerY = rootY - h + (1.0 - growthProgress) * 20;

    // --- 1. DRAW STEM (Bezier Curve) ---
    final stemPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * growthProgress
      ..strokeCap = StrokeCap.round;

    final stemPath = Path();
    stemPath.moveTo(rootX, rootY);
    // Control point matches sway direction for natural organic bending
    final double controlX = rootX + swayOffset * 0.3;
    final double controlY = rootY - h * 0.5;
    stemPath.quadraticBezierTo(controlX, controlY, flowerX, flowerY);
    canvas.drawPath(stemPath, stemPaint);

    // --- 2. DRAW LEAF ---
    if (growthProgress > 0.3) {
      final leafPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            const Color(0xFF2E7D32),
            const Color(0xFF81C784),
          ],
        ).createShader(Rect.fromLTWH(rootX - 20, rootY - h * 0.5, 40, 40))
        ..style = PaintingStyle.fill;

      final leafPath = Path();
      // Draw leaf curving outward from stem
      final double leafStartX = rootX + swayOffset * 0.15;
      final double leafStartY = rootY - h * 0.35;
      leafPath.moveTo(leafStartX, leafStartY);
      
      // Left leaf curving out
      leafPath.quadraticBezierTo(
        leafStartX - 25 * growthProgress, leafStartY - 10,
        leafStartX - 30 * growthProgress, leafStartY - 30 * growthProgress,
      );
      leafPath.quadraticBezierTo(
        leafStartX - 10, leafStartY - 25,
        leafStartX, leafStartY - 15,
      );
      leafPath.close();
      canvas.drawPath(leafPath, leafPaint);
    }

    // --- 3. DRAW TULIP FLOWER ---
    if (growthProgress > 0.5) {
      canvas.save();
      // Translate to flower base and rotate by sway angle
      canvas.translate(flowerX, flowerY);
      canvas.rotate(swayAngle * 0.5);

      final double flowerSize = 24.0 * growthProgress;

      // Color scheme for petal gradients
      final hsl = HSLColor.fromColor(tulipColor);
      final Color darkColor = hsl.withLightness(math.max(0.0, hsl.lightness - 0.15)).toColor();
      final Color lightColor = hsl.withLightness(math.min(1.0, hsl.lightness + 0.15)).toColor();

      // Shader for back petal
      final backPetalPaint = Paint()
        ..shader = RadialGradient(
          colors: [lightColor, darkColor],
          radius: 0.8,
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: flowerSize))
        ..style = PaintingStyle.fill;

      // Shader for left/right foreground petals
      final frontPetalPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lightColor, tulipColor],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: flowerSize))
        ..style = PaintingStyle.fill;

      // --- Draw Center/Back Petal ---
      final centerPath = Path();
      centerPath.moveTo(0, -flowerSize * 0.9);
      centerPath.quadraticBezierTo(flowerSize * 0.3, -flowerSize * 0.4, 0, 0);
      centerPath.quadraticBezierTo(-flowerSize * 0.3, -flowerSize * 0.4, 0, -flowerSize * 0.9);
      canvas.drawPath(centerPath, backPetalPaint);

      // --- Draw Left Petal ---
      final leftPath = Path();
      // The open distance changes based on bloomFactor
      final double openX = flowerSize * (0.3 + bloomFactor * 0.25);
      leftPath.moveTo(-openX, -flowerSize * 0.8);
      leftPath.quadraticBezierTo(-flowerSize * 0.7, -flowerSize * 0.2, 0, 0);
      leftPath.quadraticBezierTo(-flowerSize * 0.1, -flowerSize * 0.4, -openX, -flowerSize * 0.8);
      canvas.drawPath(leftPath, frontPetalPaint);

      // --- Draw Right Petal ---
      final rightPath = Path();
      final double openRightX = flowerSize * (0.3 + bloomFactor * 0.25);
      rightPath.moveTo(openRightX, -flowerSize * 0.8);
      rightPath.quadraticBezierTo(flowerSize * 0.7, -flowerSize * 0.2, 0, 0);
      rightPath.quadraticBezierTo(flowerSize * 0.1, -flowerSize * 0.4, openRightX, -flowerSize * 0.8);
      canvas.drawPath(rightPath, frontPetalPaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant TulipPainter oldDelegate) {
    return oldDelegate.tulipColor != tulipColor ||
        oldDelegate.swayAngle != swayAngle ||
        oldDelegate.growthProgress != growthProgress ||
        oldDelegate.bloomFactor != bloomFactor;
  }
}
