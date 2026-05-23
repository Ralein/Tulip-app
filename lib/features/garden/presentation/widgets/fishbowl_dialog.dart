import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/breathing_widget.dart';
import '../../../../core/widgets/glassmorphic_card.dart';

class Fish3D {
  double x, y, z;
  double vx, vy, vz;
  double speed;
  Color color;
  double wigglePhase;
  double wiggleSpeed;

  Fish3D({
    required this.x,
    required this.y,
    required this.z,
    required this.vx,
    required this.vy,
    required this.vz,
    required this.speed,
    required this.color,
  })  : wigglePhase = math.Random().nextDouble() * math.pi * 2,
        wiggleSpeed = 0.15 + math.Random().nextDouble() * 0.2;
}

class FoodFlake3D {
  double x, y, z;
  double vy;
  double scale;

  FoodFlake3D({
    required this.x,
    required this.y,
    required this.z,
    required this.vy,
  }) : scale = 3.0 + math.Random().nextDouble() * 3.0;
}

class FishbowlDialog extends StatefulWidget {
  const FishbowlDialog({super.key});

  @override
  State<FishbowlDialog> createState() => _FishbowlDialogState();
}

class _FishbowlDialogState extends State<FishbowlDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _tickerController;
  bool _isAquariumTab = true;

  // Aquarium Data
  final List<Fish3D> _fish = [];
  final List<FoodFlake3D> _food = [];
  double _rippleRadius = 0.0;
  Offset? _rippleCenter;

  // Procedural Plant Data
  double _growth = 0.5; // ranges from 0.1 to 1.0

  @override
  void initState() {
    super.initState();

    // 60FPS animation ticker
    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updatePhysics);
    _tickerController.repeat();

    // Seed initial 3 happy fishies
    _addFishy(color: AppColors.sunGold);
    _addFishy(color: AppColors.tulipPinkLight);
    _addFishy(color: AppColors.skyBlue);
  }

  @override
  void dispose() {
    _tickerController.dispose();
    super.dispose();
  }

  void _addFishy({Color? color}) {
    if (_fish.length >= 8) return; // Keep performance smooth

    final rand = math.Random();
    // Start near center of the sphere of radius 80
    final theta = rand.nextDouble() * math.pi * 2;
    final phi = math.acos((rand.nextDouble() * 2) - 1);
    final r = rand.nextDouble() * 40;

    final x = r * math.sin(phi) * math.cos(theta);
    final y = r * math.sin(phi) * math.sin(theta);
    final z = r * math.cos(phi);

    // Random velocity vector
    double vx = rand.nextDouble() - 0.5;
    double vy = rand.nextDouble() - 0.5;
    double vz = rand.nextDouble() - 0.5;
    final len = math.sqrt(vx * vx + vy * vy + vz * vz);
    if (len > 0) {
      vx /= len;
      vy /= len;
      vz /= len;
    }

    final fishColors = [
      AppColors.sunGold,
      AppColors.tulipPinkLight,
      AppColors.skyBlue,
      const Color(0xFFFFB6C1), // Pastel Pink
      const Color(0xFFFF6F00), // Bright Orange Koi
      const Color(0xFFE040FB), // Glowing Purple
    ];

    _fish.add(
      Fish3D(
        x: x,
        y: y,
        z: z,
        vx: vx,
        vy: vy,
        vz: vz,
        speed: 1.0 + rand.nextDouble() * 1.5,
        color: color ?? fishColors[rand.nextInt(fishColors.length)],
      ),
    );
  }

  void _removeFishy() {
    if (_fish.isNotEmpty) {
      _fish.removeLast();
    }
  }

  void _dropFood() {
    final rand = math.Random();
    // Drop 3 food flakes near the top surface of the bowl (around Y = -50)
    for (int i = 0; i < 3; i++) {
      _food.add(
        FoodFlake3D(
          x: (rand.nextDouble() - 0.5) * 80,
          y: -50 - rand.nextDouble() * 15,
          z: (rand.nextDouble() - 0.5) * 80,
          vy: 0.3 + rand.nextDouble() * 0.4,
        ),
      );
    }
  }

  void _tapGlass(Offset localPos, Size cardSize) {
    // Translate screen touch coords relative to the fishbowl center
    final center = Offset(cardSize.width / 2, 130);
    final translatedX = localPos.dx - center.dx;
    final translatedY = localPos.dy - center.dy;

    setState(() {
      _rippleCenter = Offset(translatedX, translatedY);
      _rippleRadius = 1.0;
    });

    // Scare the fish!
    for (var f in _fish) {
      final dx = f.x - translatedX;
      final dy = f.y - translatedY;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist < 100) {
        // Scare impulse pushing away from tap point
        f.vx += (dx / (dist > 0 ? dist : 1)) * 1.8;
        f.vy += (dy / (dist > 0 ? dist : 1)) * 1.8;
        // Normalize velocity
        final vlen = math.sqrt(f.vx * f.vx + f.vy * f.vy + f.vz * f.vz);
        if (vlen > 0) {
          f.vx /= vlen;
          f.vy /= vlen;
          f.vz /= vlen;
        }
      }
    }
  }

  void _updatePhysics() {
    if (!mounted) return;
    setState(() {
      // 1. Ripple animation
      if (_rippleCenter != null) {
        _rippleRadius += 4.5;
        if (_rippleRadius > 160) {
          _rippleCenter = null;
          _rippleRadius = 0.0;
        }
      }

      // 2. Food flake sinking
      for (int i = _food.length - 1; i >= 0; i--) {
        final f = _food[i];
        f.y += f.vy;
        // Dissolve at bottom of sphere (around Y = 70) or when eaten
        if (f.y > 70) {
          _food.removeAt(i);
        }
      }

      // 3. 3D Fish vectors
      const double sphereRadius = 80.0;
      for (var f in _fish) {
        // Chasing food AI steering
        if (_food.isNotEmpty) {
          var closestFlakeIndex = -1;
          var closestDist = 9999.0;
          for (int i = 0; i < _food.length; i++) {
            final flake = _food[i];
            final dist = math.sqrt(
              (flake.x - f.x) * (flake.x - f.x) +
              (flake.y - f.y) * (flake.y - f.y) +
              (flake.z - f.z) * (flake.z - f.z)
            );
            if (dist < closestDist) {
              closestDist = dist;
              closestFlakeIndex = i;
            }
          }

          if (closestFlakeIndex != -1 && closestDist < 120) {
            final flake = _food[closestFlakeIndex];
            final dx = flake.x - f.x;
            final dy = flake.y - f.y;
            final dz = flake.z - f.z;
            final len = math.sqrt(dx * dx + dy * dy + dz * dz);
            if (len > 0) {
              // Blend current velocity with target heading (25% steering correction)
              f.vx = f.vx * 0.75 + (dx / len) * 0.25;
              f.vy = f.vy * 0.75 + (dy / len) * 0.25;
              f.vz = f.vz * 0.75 + (dz / len) * 0.25;
            }

            // Consume food flake if in range
            if (closestDist < 12.0) {
              _food.removeAt(closestFlakeIndex);
            }
          }
        }

        // Apply velocities
        f.x += f.vx * f.speed;
        f.y += f.vy * f.speed;
        f.z += f.vz * f.speed;
        f.wigglePhase += f.wiggleSpeed;

        // Spherical boundary bounce math
        final dist = math.sqrt(f.x * f.x + f.y * f.y + f.z * f.z);
        if (dist >= sphereRadius) {
          final nx = f.x / dist;
          final ny = f.y / dist;
          final nz = f.z / dist;

          // Reflect velocity against surface normal: v_reflected = v - 2 * (v . n) * n
          final dot = f.vx * nx + f.vy * ny + f.vz * nz;
          f.vx -= 2 * dot * nx;
          f.vy -= 2 * dot * ny;
          f.vz -= 2 * dot * nz;

          // Push back inside
          f.x = nx * (sphereRadius - 1);
          f.y = ny * (sphereRadius - 1);
          f.z = nz * (sphereRadius - 1);

          // Add a random deflection so they steer naturally
          f.vx += (math.Random().nextDouble() - 0.5) * 0.15;
          f.vy += (math.Random().nextDouble() - 0.5) * 0.15;
          f.vz += (math.Random().nextDouble() - 0.5) * 0.15;
        }

        // Keep normalized velocity length
        final vlen = math.sqrt(f.vx * f.vx + f.vy * f.vy + f.vz * f.vz);
        if (vlen > 0) {
          f.vx /= vlen;
          f.vy /= vlen;
          f.vz /= vlen;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double windSway = math.sin(_tickerController.value * math.pi * 2) * 0.05 * (1.0 + _growth);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space24),
        child: GlassmorphicCard(
          borderRadius: AppDimensions.radius24,
          padding: const EdgeInsets.all(AppDimensions.space16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isAquariumTab ? Icons.waves_rounded : Icons.grass_rounded,
                        color: _isAquariumTab ? AppColors.skyBlue : AppColors.leafGreenLight,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isAquariumTab ? 'Aqua Sanctuary' : '3D Fractal Garden',
                        style: AppTypography.journalSubTitle(isDark: isDark).copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space12),

              // Tab Selection Switcher
              Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      label: 'Aquarium',
                      isSelected: _isAquariumTab,
                      activeColor: AppColors.skyBlue,
                      onTap: () => setState(() => _isAquariumTab = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTabButton(
                      label: 'Gardening',
                      isSelected: !_isAquariumTab,
                      activeColor: AppColors.leafGreenLight,
                      onTap: () => setState(() => _isAquariumTab = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space16),

              // Volumetric interactive Renders
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardSize = Size(constraints.maxWidth, 240);
                  return GestureDetector(
                    onTapUp: (details) {
                      if (_isAquariumTab) {
                        _tapGlass(details.localPosition, cardSize);
                      }
                    },
                    child: GlassmorphicCard(
                      borderRadius: AppDimensions.radius24,
                      padding: EdgeInsets.zero,
                      borderColor: _isAquariumTab 
                          ? AppColors.skyBlue.withValues(alpha: 0.15) 
                          : AppColors.leafGreen.withValues(alpha: 0.15),
                      child: Container(
                        height: 240,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppDimensions.radius24),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: _isAquariumTab
                                ? [
                                    const Color(0xFF0F2B48).withValues(alpha: 0.8),
                                    const Color(0xFF071424).withValues(alpha: 0.95),
                                  ]
                                : [
                                    const Color(0xFF132F24).withValues(alpha: 0.8),
                                    const Color(0xFF06150F).withValues(alpha: 0.95),
                                  ],
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppDimensions.radius24),
                          child: CustomPaint(
                            size: cardSize,
                            painter: _isAquariumTab
                                ? AquariumPainter(
                                    fish: _fish,
                                    food: _food,
                                    rippleRadius: _rippleRadius,
                                    rippleCenter: _rippleCenter,
                                  )
                                : FractalPlantPainter(
                                    growth: _growth,
                                    sway: windSway,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppDimensions.space16),

              // Interactive Action Bars based on tab selection
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isAquariumTab
                    ? _buildAquariumActionBar()
                    : _buildGardeningActionBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.space8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: isSelected ? activeColor.withValues(alpha: 0.5) : (isDark ? Colors.white10 : Colors.black12),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.buttonText(isDark: isDark).copyWith(
              color: isSelected ? activeColor : (isDark ? Colors.white70 : Colors.black54),
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAquariumActionBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      key: const ValueKey('aqua_controls'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildActionIconBtn(
              icon: Icons.add_circle_outline_rounded,
              label: 'Add Fishy',
              color: AppColors.skyBlue,
              onTap: () => setState(() => _addFishy()),
            ),
            _buildActionIconBtn(
              icon: Icons.remove_circle_outline_rounded,
              label: 'Remove',
              color: AppColors.tulipPinkLight,
              onTap: () => setState(() => _removeFishy()),
            ),
            _buildActionIconBtn(
              icon: Icons.restaurant_rounded,
              label: 'Feed Them',
              color: AppColors.sunGold,
              onTap: () => setState(() => _dropFood()),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space8),
        Text(
          'Tap the water to create glass ripples and scare the fish!',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall(isDark: isDark).copyWith(
            fontSize: 11,
            color: isDark ? Colors.white30 : Colors.black38,
          ),
        ),
      ],
    );
  }

  Widget _buildGardeningActionBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      key: const ValueKey('garden_controls'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildActionIconBtn(
              icon: Icons.water_drop_rounded,
              label: 'Water Sprout',
              color: AppColors.skyBlue,
              onTap: () => setState(() {
                _growth = math.min(1.0, _growth + 0.08);
              }),
            ),
            _buildActionIconBtn(
              icon: Icons.content_cut_rounded,
              label: 'Prune Leaf',
              color: AppColors.leafGreenLight,
              onTap: () => setState(() {
                _growth = math.max(0.1, _growth - 0.08);
              }),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space8),
        Text(
          'Watering triggers procedural fractal branch growth and tulip blossoms!',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall(isDark: isDark).copyWith(
            fontSize: 11,
            color: isDark ? Colors.white30 : Colors.black38,
          ),
        ),
      ],
    );
  }

  Widget _buildActionIconBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radius12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            BreathingWidget(
              minScale: 0.95,
              maxScale: 1.05,
              duration: const Duration(seconds: 3),
              child: GlassmorphicCard(
                padding: const EdgeInsets.all(10),
                borderRadius: AppDimensions.radius16,
                borderColor: color.withValues(alpha: 0.25),
                child: Icon(icon, color: color, size: 20),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.bodySmall(isDark: isDark).copyWith(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for Tab 1: Aquarium
class AquariumPainter extends CustomPainter {
  final List<Fish3D> fish;
  final List<FoodFlake3D> food;
  final double rippleRadius;
  final Offset? rippleCenter;

  AquariumPainter({
    required this.fish,
    required this.food,
    required this.rippleRadius,
    required this.rippleCenter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 10);
    const double R = 80.0;

    // Draw circular water background gradient
    final waterPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF0F3E64).withValues(alpha: 0.8),
          const Color(0xFF03101E).withValues(alpha: 0.9),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: R));
    canvas.drawCircle(center, R, waterPaint);

    // Draw background swaying plants (behind the fish in depth)
    _drawPlants(canvas, center, R, true);

    // Sort fishies by depth Z so that those in the back (negative Z) are drawn first, and those in the front (positive Z) are drawn on top!
    // This forms a perfect 3D depth-sorting layer!
    final sortedFish = List<Fish3D>.from(fish)
      ..sort((a, b) => a.z.compareTo(b.z));

    for (var f in sortedFish) {
      // Depth calculation mapping
      final double zProgress = (f.z + R) / (2 * R); // ranges from 0.0 (back) to 1.0 (front)

      // Compute projected scale and opacity
      final scale = 0.5 + zProgress * 0.7; // shrinks to 50%, grows to 120%
      final opacity = 0.4 + zProgress * 0.6; // background is slightly foggy, foreground is solid

      // Project 3D coordinate onto 2D screen coordinate relative to sphere center
      final fishCenter = Offset(center.dx + f.x, center.dy + f.y);

      // Swim direction angle (yaw)
      final double angle = math.atan2(f.vy, f.vx);

      // Tail wiggle phase
      final double wiggle = math.sin(f.wigglePhase) * 0.35;

      canvas.save();
      canvas.translate(fishCenter.dx, fishCenter.dy);
      canvas.rotate(angle);
      canvas.scale(scale);

      final fishPaint = Paint()
        ..color = f.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      // Draw Fish Body (Sleek elongated diamond path)
      final bodyPath = Path()
        ..moveTo(14, 0) // Nose tip
        ..quadraticBezierTo(0, -6, -10, -2) // Top body curve
        ..lineTo(-12, 0)
        ..lineTo(-10, 2)
        ..quadraticBezierTo(0, 6, 14, 0) // Bottom body curve
        ..close();
      canvas.drawPath(bodyPath, fishPaint);

      // Draw dynamic wiggling tail fin
      canvas.save();
      canvas.translate(-11, 0);
      canvas.rotate(wiggle);

      final tailPath = Path()
        ..moveTo(0, 0)
        ..lineTo(-8, -6)
        ..quadraticBezierTo(-4, 0, -8, 6)
        ..close();
      canvas.drawPath(tailPath, fishPaint);
      canvas.restore();

      // Draw cute fish eye
      final eyePaint = Paint()..color = Colors.black.withValues(alpha: opacity);
      canvas.drawCircle(const Offset(8, -2), 1.5, eyePaint);

      canvas.restore();
    }

    // Draw foreground plants (in front of background fish)
    _drawPlants(canvas, center, R, false);

    // Draw falling food flakes
    final foodPaint = Paint()
      ..color = AppColors.sunGoldLight.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;
    for (var f in food) {
      final flakeCenter = Offset(center.dx + f.x, center.dy + f.y);
      canvas.drawCircle(flakeCenter, f.scale / 2, foodPaint);
    }

    // Draw tap ripple shockwave overlay
    if (rippleCenter != null && rippleRadius > 0) {
      final ripplePaint = Paint()
        ..color = Colors.white.withValues(alpha: math.max(0.0, 0.45 - (rippleRadius / 160.0)))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(Offset(center.dx + rippleCenter!.dx, center.dy + rippleCenter!.dy), rippleRadius, ripplePaint);
    }

    // Glass Bowl Highlights (Gives it absolute 3D volume, frosted refraction, and realism)
    final reflectionPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.05),
          Colors.transparent,
          Colors.black.withValues(alpha: 0.15),
        ],
        stops: const [0.0, 0.35, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: R));

    final glassBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = Colors.white.withValues(alpha: 0.28);

    canvas.drawCircle(center, R, reflectionPaint);
    canvas.drawCircle(center, R, glassBorderPaint);

    // Dynamic light streak at top-left
    final highlightPath = Path()
      ..addArc(
        Rect.fromCircle(center: center, radius: R - 4),
        -math.pi * 0.75,
        math.pi * 0.45,
      );
    canvas.drawPath(
      highlightPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.5),
    );
  }

  void _drawPlants(Canvas canvas, Offset center, double R, bool isBackground) {
    final plantPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final List<double> offsetsX = isBackground ? [-25, 30] : [-5, 15];
    final List<double> heights = isBackground ? [45, 55] : [35, 40];
    final List<Color> colors = isBackground
        ? [AppColors.leafGreenDark.withValues(alpha: 0.75), const Color(0xFF1B5E20).withValues(alpha: 0.75)]
        : [AppColors.leafGreenLight.withValues(alpha: 0.9), AppColors.leafGreen.withValues(alpha: 0.9)];

    // Time-based phase offset
    final double time = DateTime.now().millisecondsSinceEpoch / 1000.0;

    for (int i = 0; i < offsetsX.length; i++) {
      final double xRoot = offsetsX[i];
      final double h = heights[i];
      plantPaint.color = colors[i];

      final stemPath = Path();
      // Ground point at bottom of sphere
      final double yRoot = math.sqrt(R * R - xRoot * xRoot) * 0.95;
      final rootPos = Offset(center.dx + xRoot, center.dy + yRoot);

      stemPath.moveTo(rootPos.dx, rootPos.dy);

      // Draw curved swaying plant branches
      final double sway = math.sin(time * 1.5 + i * 2.0) * 8.0;
      final cp1 = Offset(rootPos.dx + sway * 0.3, rootPos.dy - h * 0.4);
      final cp2 = Offset(rootPos.dx + sway * 0.7, rootPos.dy - h * 0.7);
      final end = Offset(rootPos.dx + sway, rootPos.dy - h);

      stemPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);
      canvas.drawPath(stemPath, plantPaint);

      // Draw small leaves on stem
      final leafPaint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;
      canvas.drawCircle(end, 3.5, leafPaint);
      canvas.drawCircle(Offset(cp2.dx + 2, cp2.dy), 2.5, leafPaint);
      canvas.drawCircle(Offset(cp1.dx - 2, cp1.dy), 2.5, leafPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom Painter for Tab 2: 3D Fractal Gardening
class FractalPlantPainter extends CustomPainter {
  final double growth;
  final double sway;

  FractalPlantPainter({
    required this.growth,
    required this.sway,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final root = Offset(size.width / 2, size.height - 25);
    final double rootLength = 35 + growth * 40;
    final int maxDepth = (growth * 5.0).round() + 2; // branches divide up to 7 deep!

    // Draw Soil ground
    final groundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.soilBrownLight.withValues(alpha: 0.9),
          AppColors.soilBrown.withValues(alpha: 0.95),
        ],
      ).createShader(Rect.fromLTRB(0, size.height - 30, size.width, size.height));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(20, size.height - 30, size.width - 20, size.height - 15),
        const Radius.circular(8),
      ),
      groundPaint,
    );

    // Start recursive fractal drawing
    _drawBranch(
      canvas: canvas,
      start: root,
      length: rootLength,
      angle: -math.pi / 2, // Straight UP
      thickness: 6.5 * (0.5 + growth * 0.5),
      depth: 0,
      maxDepth: maxDepth,
    );
  }

  void _drawBranch({
    required Canvas canvas,
    required Offset start,
    required double length,
    required double angle,
    required double thickness,
    required int depth,
    required int maxDepth,
  }) {
    // Project end coordinate based on polar coordinates
    final end = Offset(
      start.dx + length * math.cos(angle),
      start.dy + length * math.sin(angle),
    );

    final branchPaint = Paint()
      ..color = Color.lerp(
        AppColors.soilBrownLight,
        AppColors.leafGreenDark,
        depth / maxDepth.toDouble()
      )!.withValues(alpha: 0.95)
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(start, end, branchPaint);

    if (depth >= maxDepth) {
      // Draw dynamic foliage at terminal leaves
      final leafPaint = Paint()
        ..color = AppColors.leafGreenLight.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;
      
      // Draw three leaf petals
      canvas.drawOval(
        Rect.fromCenter(center: end, width: 7.5, height: 4.5),
        leafPaint,
      );

      // Sprout gorgeous blooming pink tulips on highest growth nodes!
      if (growth > 0.4 && depth == maxDepth) {
        final flowerPaint = Paint()
          ..color = AppColors.tulipPinkLight.withValues(alpha: 0.95)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(end.dx, end.dy - 3), 3.0 + (growth * 2), flowerPaint);
      }
      return;
    }

    // Branch splitting ratios
    final double nextLength = length * 0.72;
    final double nextThickness = thickness * 0.7;

    // Split into 2-3 sub-branches with alternating angles and wind sway correction
    _drawBranch(
      canvas: canvas,
      start: end,
      length: nextLength,
      angle: angle - 0.38 + sway * 0.8,
      thickness: nextThickness,
      depth: depth + 1,
      maxDepth: maxDepth,
    );

    _drawBranch(
      canvas: canvas,
      start: end,
      length: nextLength,
      angle: angle + 0.38 + sway,
      thickness: nextThickness,
      depth: depth + 1,
      maxDepth: maxDepth,
    );

    // Central node grows if plant has high water content (growth > 0.6)
    if (growth > 0.65) {
      _drawBranch(
        canvas: canvas,
        start: end,
        length: nextLength * 0.8,
        angle: angle + sway * 0.3,
        thickness: nextThickness * 0.9,
        depth: depth + 1,
        maxDepth: maxDepth,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
