import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'sun_widget.dart';

class GardenSky extends StatefulWidget {
  final bool isNight;

  const GardenSky({
    super.key,
    required this.isNight,
  });

  @override
  State<GardenSky> createState() => _GardenSkyState();
}

class _GardenSkyState extends State<GardenSky>
    with SingleTickerProviderStateMixin {
  late AnimationController _driftController;

  @override
  void initState() {
    super.initState();
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120),
    )..repeat();
  }

  @override
  void dispose() {
    _driftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. Twinkling Stars (if night)
            if (widget.isNight)
              _TwinklingStars(width: width, height: height * 0.7),

            // 2. Celestial Body (Sun/Moon)
            Positioned(
              right: 40,
              top: 50,
              child: widget.isNight
                  ? _MoonWidget()
                  : const SunWidget(size: 70),
            ),

            // 3. Drifting Clouds (slow continuous loops)
            AnimatedBuilder(
              animation: _driftController,
              builder: (context, child) {
                final offset1 = _driftController.value * (width + 120) - 120;
                final offset2 = ((_driftController.value + 0.5) % 1.0) * (width + 150) - 150;

                return Stack(
                  children: [
                    // Cloud 1
                    Positioned(
                      left: offset1,
                      top: 40,
                      child: Opacity(
                        opacity: widget.isNight ? 0.15 : 0.6,
                        child: const _CloudShape(width: 100, height: 40),
                      ),
                    ),
                    // Cloud 2
                    Positioned(
                      left: offset2,
                      top: 90,
                      child: Opacity(
                        opacity: widget.isNight ? 0.10 : 0.45,
                        child: const _CloudShape(width: 130, height: 45),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _MoonWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.moonYellow.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _MoonPainter(),
      ),
    );
  }
}

class _MoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    final moonPaint = Paint()
      ..color = AppColors.moonYellow
      ..style = PaintingStyle.fill;

    // Draw beautiful crescent moon
    final path = Path();
    path.addArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, math.pi * 2 * 0.75);
    
    final shadowPath = Path();
    shadowPath.addArc(
      Rect.fromCircle(center: center.translate(radius * 0.35, -radius * 0.1), radius: radius * 0.95),
      -math.pi / 2,
      math.pi * 2,
    );

    final resolvedPath = Path.combine(PathOperation.difference, path, shadowPath);
    canvas.drawPath(resolvedPath, moonPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CloudShape extends StatelessWidget {
  final double width;
  final double height;

  const _CloudShape({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _CloudPainter(),
    );
  }
}

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    final h = size.height;
    final w = size.width;

    // Custom cloud vector representation
    path.moveTo(h * 0.4, h * 0.85);
    path.quadraticBezierTo(h * 0.1, h * 0.85, h * 0.1, h * 0.6);
    path.quadraticBezierTo(h * 0.1, h * 0.35, h * 0.45, h * 0.35);
    path.quadraticBezierTo(w * 0.45, h * 0.1, w * 0.6, h * 0.1);
    path.quadraticBezierTo(w * 0.8, h * 0.1, w * 0.8, h * 0.35);
    path.quadraticBezierTo(w * 0.95, h * 0.35, w * 0.95, h * 0.6);
    path.quadraticBezierTo(w * 0.95, h * 0.85, w * 0.75, h * 0.85);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TwinklingStars extends StatefulWidget {
  final double width;
  final double height;

  const _TwinklingStars({required this.width, required this.height});

  @override
  State<_TwinklingStars> createState() => _TwinklingStarsState();
}

class _TwinklingStarsState extends State<_TwinklingStars>
    with SingleTickerProviderStateMixin {
  late AnimationController _twinkleController;
  final List<Offset> _starOffsets = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _twinkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Seed static star points
    for (int i = 0; i < 20; i++) {
      _starOffsets.add(Offset(
        _random.nextDouble() * widget.width,
        _random.nextDouble() * widget.height,
      ));
    }
  }

  @override
  void dispose() {
    _twinkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_starOffsets.isEmpty) return const SizedBox();

    return AnimatedBuilder(
      animation: _twinkleController,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _StarPainter(
            offsets: _starOffsets,
            progress: _twinkleController.value,
          ),
        );
      },
    );
  }
}

class _StarPainter extends CustomPainter {
  final List<Offset> offsets;
  final double progress;

  _StarPainter({required this.offsets, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < offsets.length; i++) {
      final pos = offsets[i];
      
      // Calculate individual star twinkling factor
      final starProgress = (progress + (i * 0.17)) % 1.0;
      final double starSize = 1.0 + math.sin(starProgress * math.pi * 2) * 1.5;

      paint.color = Colors.white.withOpacity(0.3 + math.sin(starProgress * math.pi * 2) * 0.7);
      canvas.drawCircle(pos, starSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
