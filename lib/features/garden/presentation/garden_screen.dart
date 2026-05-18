import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_gradient_bg.dart';
import '../../../core/widgets/breathing_widget.dart';
import '../../../core/widgets/glassmorphic_card.dart';
import '../../../core/widgets/particle_system.dart';
import '../../../core/widgets/tulip_painter.dart';
import '../../journal/presentation/providers/journal_provider.dart';
import 'providers/garden_state_provider.dart';
import 'widgets/garden_sky.dart';
import 'widgets/streak_counter.dart';
import 'widgets/tulip_field.dart';
import 'widgets/weather_controller.dart';

class PlantedSeed {
  final Offset position;
  final DateTime plantedAt;
  final Color color;
  final double scaleTarget;

  PlantedSeed({
    required this.position,
    required this.plantedAt,
    required this.color,
    required this.scaleTarget,
  });
}

class SkySparkle {
  final Offset position;
  final DateTime createdAt;
  final double maxRadius;

  SkySparkle({
    required this.position,
    required this.createdAt,
    required this.maxRadius,
  });
}

class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> with TickerProviderStateMixin {
  final List<PlantedSeed> _seeds = [];
  final List<SkySparkle> _sparkles = [];
  final math.Random _random = math.Random();
  Timer? _decayTimer;

  @override
  void initState() {
    super.initState();
    // Decay timer to remove temporary seedlings/sparkles after they bloom fully
    _decayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final now = DateTime.now();
      setState(() {
        _seeds.removeWhere((seed) => now.difference(seed.plantedAt).inSeconds > 12);
        _sparkles.removeWhere((sparkle) => now.difference(sparkle.createdAt).inMilliseconds > 800);
      });
    });
  }

  @override
  void dispose() {
    _decayTimer?.cancel();
    super.dispose();
  }

  Color _getRandomTulipColor() {
    final colors = [
      AppColors.tulipPink,
      AppColors.tulipPinkLight,
      AppColors.tulipPinkDark,
      AppColors.tulipRed,
      AppColors.tulipRedLight,
      AppColors.sunGold,
      AppColors.moonYellow,
      AppColors.duskPurpleLight,
      const Color(0xFFE040FB), // Glowing purple tulip
      const Color(0xFF00E5FF), // Magic cyan tulip
    ];
    return colors[_random.nextInt(colors.length)];
  }

  void _onGardenTapped(Offset localPosition, double screenHeight) {
    final relativeY = localPosition.dy / screenHeight;

    if (relativeY < 0.35) {
      // Tap is in the sky: Spawn an elegant celestial sparkle ripple!
      setState(() {
        _sparkles.add(SkySparkle(
          position: localPosition,
          createdAt: DateTime.now(),
          maxRadius: 20.0 + _random.nextDouble() * 20.0,
        ));
      });
    } else {
      // Tap is in the soil: Seed planting!
      setState(() {
        _seeds.add(PlantedSeed(
          position: localPosition,
          plantedAt: DateTime.now(),
          color: _getRandomTulipColor(),
          scaleTarget: 0.6 + _random.nextDouble() * 0.4,
        ));
      });
      // Trigger a light haptic sensation style animation
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final entriesAsync = ref.watch(journalEntriesProvider);
        final gardenState = ref.watch(gardenStateProvider);
        final size = MediaQuery.of(context).size;

        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Time-of-day and Weather Shifting Gradient Background
              AnimatedGradientBg(
                timeOfDay: gardenState.time,
                weather: gardenState.weather,
              ),

              // 2. Sky Elements
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: size.height * 0.45,
                child: GardenSky(
                  isNight: gardenState.time == DayTime.night || gardenState.time == DayTime.evening,
                ),
              ),

              // 3. Falling Petals / Atmospheric weather particles
              Positioned.fill(
                child: ParticleSystemWidget(
                  weather: gardenState.weather,
                ),
              ),

              // 4. Perspective 3D Swaying Stable Tulip Field
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: size.height * 0.65,
                child: entriesAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.tulipPink),
                  ),
                  error: (err, stack) => Center(
                    child: Text('Error: $err'),
                  ),
                  data: (entries) => TulipField(entries: entries),
                ),
              ),

              // 5. Interactive sandbox layer (Captures Taps for planting seeds/sparkles!)
              Positioned.fill(
                child: GestureDetector(
                  onTapDown: (details) => _onGardenTapped(details.localPosition, size.height),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),

              // 6. Sky Sparkle Ripple Renderings
              ..._sparkles.map((sparkle) {
                final elapsedMs = DateTime.now().difference(sparkle.createdAt).inMilliseconds;
                final progress = math.min(1.0, elapsedMs / 800.0);
                final opacity = 1.0 - progress;

                return Positioned(
                  left: sparkle.position.dx - sparkle.maxRadius,
                  top: sparkle.position.dy - sparkle.maxRadius,
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: const AlwaysStoppedAnimation(0),
                      builder: (context, child) {
                        return Container(
                          width: sparkle.maxRadius * 2,
                          height: sparkle.maxRadius * 2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(opacity.clamp(0.0, 1.0)),
                              width: 1.5,
                            ),
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withOpacity((opacity * 0.6).clamp(0.0, 1.0)),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }),

              // 7. Temporary Sprouts Growing Real-Time!
              ..._seeds.map((seed) {
                final elapsedMs = DateTime.now().difference(seed.plantedAt).inMilliseconds;
                
                // Growth phase 1: Stem sprout (first 2 seconds)
                final growthProgress = math.min(1.0, elapsedMs / 2500.0);
                
                // Growth phase 2: Bloom factor (following 2 seconds)
                final bloomFactor = elapsedMs > 2500
                    ? math.min(1.0, (elapsedMs - 2500) / 2000.0)
                    : 0.0;

                // Bounce spring scale animation
                final scale = growthProgress < 0.8
                    ? (growthProgress / 0.8) * seed.scaleTarget * 0.9
                    : seed.scaleTarget;

                // Sway animation
                final swayAngle = 0.05 * math.sin(elapsedMs / 250.0);

                return Positioned(
                  left: seed.position.dx - 40,
                  top: seed.position.dy - 80,
                  child: IgnorePointer(
                    child: SizedBox(
                      width: 80,
                      height: 100,
                      child: Transform.scale(
                        scale: scale,
                        alignment: Alignment.bottomCenter,
                        child: CustomPaint(
                          painter: TulipPainter(
                            tulipColor: seed.color,
                            growthProgress: growthProgress,
                            bloomFactor: bloomFactor,
                            swayAngle: swayAngle,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),

              // 8. Ambient ground shadow overlay
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 120,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          isDark
                              ? AppColors.bgDark.withOpacity(0.8)
                              : AppColors.bgLight.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 9. Glowing Stats Header
              Positioned(
                top: MediaQuery.of(context).padding.top + AppDimensions.space8,
                left: AppDimensions.space16,
                right: AppDimensions.space16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Glowing Streak Counter
                    entriesAsync.maybeWhen(
                      data: (entries) {
                        final int streak = entries.isNotEmpty ? 1 : 0;
                        return StreakCounter(streakDays: streak);
                      },
                      orElse: () => const StreakCounter(streakDays: 0),
                    ),

                    // View Logs Button
                    InkWell(
                      onTap: () => context.go('/entries'),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                      child: GlassmorphicCard(
                        padding: const EdgeInsets.all(AppDimensions.space12),
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: isDark ? Colors.white : AppColors.tulipPinkDark,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 10. Ambient Weather and Atmosphere Controller
              Positioned(
                bottom: 150,
                left: AppDimensions.space16,
                right: AppDimensions.space16,
                child: const WeatherController(),
              ),

              // 11. Empty Garden Helper Text (with interactive hints!)
              entriesAsync.maybeWhen(
                data: (entries) {
                  if (entries.isNotEmpty) return const SizedBox();
                  return Positioned(
                    bottom: 330,
                    left: 32,
                    right: 32,
                    child: IgnorePointer(
                      child: Column(
                        children: [
                          Text(
                            'Your Garden is Empty',
                            style: AppTypography.journalSubTitle(isDark: isDark).copyWith(
                              fontSize: 22,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap anywhere on the ground to plant interactive test seeds, or tap the Sprout FAB below to write and grow your permanent tulips!',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall(isDark: isDark).copyWith(
                              fontSize: 13,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                orElse: () => const SizedBox(),
              ),

              // 12. Floating Action Sprout Button
              Positioned(
                bottom: AppDimensions.space24,
                left: 0,
                right: 0,
                child: Center(
                  child: BreathingWidget(
                    minScale: 0.95,
                    maxScale: 1.05,
                    duration: const Duration(seconds: 2),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.tulipPink.withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: FloatingActionButton.large(
                        onPressed: () => context.go('/editor'),
                        backgroundColor: AppColors.tulipPink,
                        foregroundColor: Colors.white,
                        shape: const CircleBorder(),
                        child: const Icon(
                          Icons.spa_rounded,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
