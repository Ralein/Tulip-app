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
import '../../journal/presentation/providers/journal_provider.dart';
import 'widgets/garden_sky.dart';
import 'widgets/streak_counter.dart';
import 'widgets/tulip_field.dart';

class GardenScreen extends ConsumerWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entriesAsync = ref.watch(journalEntriesProvider);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Time-of-day Shifting Animated Gradient Background
          AnimatedGradientBg(timeOfDay: isDark ? DayTime.night : DayTime.afternoon),

          // 2. Parallax Sky Elements (Sun/Moon, Twinkling Stars, Drifting Clouds)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: GardenSky(isNight: isDark),
          ),

          // 3. Falling Petals Ambient Particle System
          const Positioned.fill(
            child: ParticleSystemWidget(),
          ),

          // 4. Perspective 3D Swaying Tulip Field
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.of(context).size.height * 0.65,
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

          // 5. Ambient Sunlight overlay (Gently fading bottom shadow)
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

          // 6. Glowing Stat Header (Glassmorphic Container at the Top)
          Positioned(
            top: MediaQuery.of(context).padding.top + AppDimensions.space8,
            left: AppDimensions.space16,
            right: AppDimensions.space16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Glowing Journal Streak Counter
                entriesAsync.maybeWhen(
                  data: (entries) {
                    // Simple streak calculation (mock or based on entry dates)
                    final int streak = entries.isNotEmpty ? 1 : 0; // Sprout initial streak
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

          // 7. Empty Garden Hint text
          entriesAsync.maybeWhen(
            data: (entries) {
              if (entries.isNotEmpty) return const SizedBox();
              return Positioned(
                bottom: 160,
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
                        'Tap the floating sprout below to write your first journal and grow your personal Tulip!',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall(isDark: isDark).copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            orElse: () => const SizedBox(),
          ),

          // 8. Floating Action Sprout Button (pulsing micro-animation FAB)
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
                      Icons.spa_rounded, // Leaves/Sprout icon
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
  }
}
