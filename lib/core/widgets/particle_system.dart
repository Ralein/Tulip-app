import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class PetalParticle {
  double x;
  double y;
  double speedY;
  double speedX;
  double size;
  double angle;
  double spinSpeed;
  double opacity;
  Color color;

  PetalParticle({
    required this.x,
    required this.y,
    required this.speedY,
    required this.speedX,
    required this.size,
    required this.angle,
    required this.spinSpeed,
    required this.opacity,
    required this.color,
  });
}

class ParticleSystemWidget extends StatefulWidget {
  final Color particleColor;
  final int maxParticles;

  const ParticleSystemWidget({
    super.key,
    this.particleColor = const Color(0xFFFFBBD0), // Tulip Pink Petal
    this.maxParticles = 25,
  });

  @override
  State<ParticleSystemWidget> createState() => _ParticleSystemWidgetState();
}

class _ParticleSystemWidgetState extends State<ParticleSystemWidget>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<PetalParticle> _particles = [];
  final math.Random _random = math.Random();
  Size _screenSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_screenSize == Size.zero) return;

    setState(() {
      // Spawn particles if needed
      if (_particles.length < widget.maxParticles && _random.nextDouble() < 0.05) {
        _spawnParticle(atTop: true);
      }

      // Update particle positions
      for (int i = _particles.length - 1; i >= 0; i--) {
        final p = _particles[i];
        p.y += p.speedY;
        p.x += p.speedX + math.sin(p.y / 30) * 0.5; // Natural swaying
        p.angle += p.spinSpeed;

        // Reset if offscreen
        if (p.y > _screenSize.height + 20 || p.x < -20 || p.x > _screenSize.width + 20) {
          if (_particles.length > widget.maxParticles) {
            _particles.removeAt(i);
          } else {
            _resetParticle(p);
          }
        }
      }
    });
  }

  void _spawnParticle({required bool atTop}) {
    final x = _random.nextDouble() * _screenSize.width;
    final y = atTop ? -20.0 : _random.nextDouble() * _screenSize.height;
    
    // Choose varying shades of pink/gold
    final colors = [
      widget.particleColor,
      widget.particleColor.withOpacity(0.8),
      const Color(0xFFF8BBD0), // Soft Pink
      const Color(0xFFFFF59D).withOpacity(0.5), // Subtle Gold sparkle
    ];

    _particles.add(PetalParticle(
      x: x,
      y: y,
      speedY: 0.8 + _random.nextDouble() * 1.5,
      speedX: -0.5 + _random.nextDouble() * 1.0,
      size: 6.0 + _random.nextDouble() * 12.0,
      angle: _random.nextDouble() * math.pi * 2,
      spinSpeed: 0.01 + _random.nextDouble() * 0.03,
      opacity: 0.3 + _random.nextDouble() * 0.6,
      color: colors[_random.nextInt(colors.length)],
    ));
  }

  void _resetParticle(PetalParticle p) {
    p.x = _random.nextDouble() * _screenSize.width;
    p.y = -20.0;
    p.speedY = 0.8 + _random.nextDouble() * 1.5;
    p.speedX = -0.5 + _random.nextDouble() * 1.0;
    p.size = 6.0 + _random.nextDouble() * 12.0;
    p.angle = _random.nextDouble() * math.pi * 2;
    p.spinSpeed = 0.01 + _random.nextDouble() * 0.03;
    p.opacity = 0.3 + _random.nextDouble() * 0.6;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_screenSize.width != constraints.maxWidth ||
            _screenSize.height != constraints.maxHeight) {
          _screenSize = Size(constraints.maxWidth, constraints.maxHeight);
          // Initial population
          if (_particles.isEmpty) {
            for (int i = 0; i < widget.maxParticles ~/ 2; i++) {
              _spawnParticle(atTop: false);
            }
          }
        }

        return CustomPaint(
          size: Size.infinite,
          painter: _ParticlePainter(_particles),
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<PetalParticle> particles;

  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(p.opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.angle);

      // Draw custom leaf/petal shape (oval with tapered end)
      final path = Path();
      path.moveTo(0, -p.size / 2);
      path.quadraticBezierTo(p.size * 0.4, -p.size * 0.2, p.size * 0.2, p.size / 2);
      path.quadraticBezierTo(0, p.size * 0.3, -p.size * 0.2, p.size / 2);
      path.quadraticBezierTo(-p.size * 0.4, -p.size * 0.2, 0, -p.size / 2);
      path.close();

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
