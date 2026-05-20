import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../features/garden/presentation/providers/garden_state_provider.dart';

enum ParticleType { petal, rain, firefly, windyLeaf }

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
  ParticleType type;

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
    required this.type,
  });
}

class ParticleSystemWidget extends StatefulWidget {
  final Color particleColor;
  final int maxParticles;
  final GardenWeather weather;

  const ParticleSystemWidget({
    super.key,
    this.particleColor = const Color(0xFFFFBBD0), // Tulip Pink Petal
    this.maxParticles = 35,
    this.weather = GardenWeather.sunny,
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

  @override
  void didUpdateWidget(covariant ParticleSystemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the weather changed, gently clear and transition active particles!
    if (oldWidget.weather != widget.weather) {
      _particles.clear();
      if (_screenSize != Size.zero) {
        for (int i = 0; i < widget.maxParticles ~/ 2; i++) {
          _spawnParticle(atTop: false);
        }
      }
    }
  }

  void _onTick(Duration elapsed) {
    if (_screenSize == Size.zero) return;

    setState(() {
      // Spawn particles if needed
      if (_particles.length < widget.maxParticles && _random.nextDouble() < 0.12) {
        _spawnParticle(atTop: true);
      }

      // Update particle positions
      for (int i = _particles.length - 1; i >= 0; i--) {
        final p = _particles[i];
        
        // Dynamic animation properties based on particle/weather types
        if (p.type == ParticleType.rain) {
          p.y += p.speedY;
          p.x += p.speedX;
        } else if (p.type == ParticleType.firefly) {
          // Floating UP gently, with sinewave horizontal sways
          p.y += p.speedY;
          p.x += p.speedX + math.sin(p.y / 25) * 0.5 + math.cos(p.y / 10) * 0.2;
          // Flickering opacity
          p.opacity = math.max(0.1, math.min(1.0, p.opacity + (_random.nextDouble() * 0.15 - 0.075)));
        } else if (p.type == ParticleType.windyLeaf) {
          // Rapid diagonal wind drift
          p.y += p.speedY;
          p.x += p.speedX + math.sin(p.y / 20) * 1.8 + math.cos(p.y / 8) * 0.5;
          p.angle += p.spinSpeed;
        } else {
          // Standard sunny drifting petals with 3D-like organic tumble
          p.y += p.speedY;
          p.x += p.speedX + math.sin(p.y / 35) * 0.8 + math.cos(p.y / 15) * 0.4;
          p.angle += p.spinSpeed;
        }

        // Reset or remove if offscreen/out of bounds
        final isOffscreen = p.type == ParticleType.firefly
            ? (p.y < -20 || p.x < -20 || p.x > _screenSize.width + 20)
            : (p.y > _screenSize.height + 20 || p.x < -20 || p.x > _screenSize.width + 20);

        if (isOffscreen) {
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
    final y = atTop 
        ? (widget.weather == GardenWeather.starry ? _screenSize.height + 10.0 : -20.0) 
        : _random.nextDouble() * _screenSize.height;

    final particle = _createParticleForWeather(x, y);
    _particles.add(particle);
  }

  void _resetParticle(PetalParticle p) {
    p.x = _random.nextDouble() * _screenSize.width;
    p.y = widget.weather == GardenWeather.starry ? _screenSize.height + 10.0 : -20.0;
    
    final template = _createParticleForWeather(p.x, p.y);
    p.speedY = template.speedY;
    p.speedX = template.speedX;
    p.size = template.size;
    p.angle = template.angle;
    p.spinSpeed = template.spinSpeed;
    p.opacity = template.opacity;
    p.color = template.color;
    p.type = template.type;
  }

  PetalParticle _createParticleForWeather(double x, double y) {
    switch (widget.weather) {
      case GardenWeather.rainy:
        return PetalParticle(
          x: x,
          y: y,
          speedY: 6.0 + _random.nextDouble() * 4.0, // Quick rainfall
          speedX: -0.5 + _random.nextDouble() * 0.5,
          size: 10.0 + _random.nextDouble() * 10.0, // Length of rain streak
          angle: 0.05,
          spinSpeed: 0.0,
          opacity: 0.2 + _random.nextDouble() * 0.3,
          color: const Color(0xFFB3E5FC), // Translucent rain blue
          type: ParticleType.rain,
        );
      case GardenWeather.starry:
        // Fireflies floating UP
        return PetalParticle(
          x: x,
          y: y,
          speedY: -0.4 - _random.nextDouble() * 0.8, // Float upwards
          speedX: -0.3 + _random.nextDouble() * 0.6,
          size: 3.0 + _random.nextDouble() * 4.0,
          angle: 0.0,
          spinSpeed: 0.0,
          opacity: 0.4 + _random.nextDouble() * 0.6,
          color: const Color(0xFFC5E1A5), // Firefly neon green-yellow
          type: ParticleType.firefly,
        );
      case GardenWeather.windy:
        // Swirling gold/green autumn leaves
        final leafColors = [
          const Color(0xFFFFB74D), // Golden orange
          const Color(0xFFFFD54F), // Bright gold
          const Color(0xFF81C784), // Pale green
        ];
        return PetalParticle(
          x: x,
          y: y,
          speedY: 1.5 + _random.nextDouble() * 2.0,
          speedX: 2.0 + _random.nextDouble() * 3.0, // Blowing horizontally
          size: 8.0 + _random.nextDouble() * 10.0,
          angle: _random.nextDouble() * math.pi * 2,
          spinSpeed: 0.04 + _random.nextDouble() * 0.05,
          opacity: 0.4 + _random.nextDouble() * 0.5,
          color: leafColors[_random.nextInt(leafColors.length)],
          type: ParticleType.windyLeaf,
        );
      case GardenWeather.sunny:
        // Soft pink petals drifting down
        final colors = [
          widget.particleColor,
          widget.particleColor.withValues(alpha: 0.8),
          const Color(0xFFF8BBD0), // Soft Pink
          const Color(0xFFFFF59D).withValues(alpha: 0.5), // Soft gold sparkle
        ];
        return PetalParticle(
          x: x,
          y: y,
          speedY: 0.8 + _random.nextDouble() * 1.5,
          speedX: -0.5 + _random.nextDouble() * 1.0,
          size: 6.0 + _random.nextDouble() * 12.0,
          angle: _random.nextDouble() * math.pi * 2,
          spinSpeed: 0.01 + _random.nextDouble() * 0.03,
          opacity: 0.3 + _random.nextDouble() * 0.6,
          color: colors[_random.nextInt(colors.length)],
          type: ParticleType.petal,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_screenSize.width != constraints.maxWidth ||
            _screenSize.height != constraints.maxHeight) {
          _screenSize = Size(constraints.maxWidth, constraints.maxHeight);
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
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.angle);

      if (p.type == ParticleType.rain) {
        // Draw thin raindrop streak lines
        final rainPaint = Paint()
          ..color = p.color.withValues(alpha: p.opacity.clamp(0.0, 1.0))
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset.zero, Offset(0, p.size), rainPaint);
      } else if (p.type == ParticleType.firefly) {
        // Draw glowing circular spark particles
        final glowPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white,
              p.color.withValues(alpha: p.opacity.clamp(0.0, 1.0)),
              p.color.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: p.size * 2))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset.zero, p.size * 2, glowPaint);
      } else {
        // 3D Tumble simulation using Y-axis scale based on angle
        final tumbleScale = 0.3 + 0.7 * (math.sin(p.angle * 2.5).abs());
        canvas.scale(1.0, tumbleScale);

        // Draw custom leaf/petal shape (oval with tapered end)
        final path = Path();
        path.moveTo(0, -p.size / 2);
        path.quadraticBezierTo(p.size * 0.4, -p.size * 0.2, p.size * 0.2, p.size / 2);
        path.quadraticBezierTo(0, p.size * 0.3, -p.size * 0.2, p.size / 2);
        path.quadraticBezierTo(-p.size * 0.4, -p.size * 0.2, 0, -p.size / 2);
        path.close();

        // 3D volume gradient for petals
        final petalPaint = Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.2, -0.2),
            radius: 0.8,
            colors: [
              Colors.white.withValues(alpha: p.opacity * 0.8),
              p.color.withValues(alpha: p.opacity.clamp(0.0, 1.0)),
              p.color.withValues(alpha: (p.opacity * 0.6).clamp(0.0, 1.0)),
            ],
          ).createShader(path.getBounds())
          ..style = PaintingStyle.fill;

        canvas.drawPath(path, petalPaint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
