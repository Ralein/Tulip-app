import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/breathing_widget.dart';
import '../../../../core/widgets/glassmorphic_card.dart';

class BreathingDialog extends StatefulWidget {
  const BreathingDialog({super.key});

  @override
  State<BreathingDialog> createState() => _BreathingDialogState();
}

class _BreathingDialogState extends State<BreathingDialog> {
  int _seconds = 0;
  Timer? _timer;
  String _breathState = 'Inhale';
  Color _breathColor = AppColors.tulipPink;

  @override
  void initState() {
    super.initState();
    _startMeditation();
  }

  void _startMeditation() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _seconds++;
        // 4s Inhale, 4s Hold, 4s Exhale box-breathing cycle
        final cycleTime = _seconds % 12;
        if (cycleTime < 4) {
          _breathState = 'Inhale deeply...';
          _breathColor = AppColors.tulipPink;
        } else if (cycleTime < 8) {
          _breathState = 'Hold your breath...';
          _breathColor = AppColors.sunGold;
        } else {
          _breathState = 'Exhale slowly...';
          _breathColor = AppColors.leafGreen;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space24),
        child: GlassmorphicCard(
          borderRadius: AppDimensions.radius24,
          padding: const EdgeInsets.all(AppDimensions.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Breathing Space',
                    style: AppTypography.journalSubTitle(isDark: isDark).copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
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
              const SizedBox(height: AppDimensions.space8),

              Text(
                'Focus on the pulsing ring to soothe your mind before writing.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall(isDark: isDark).copyWith(
                  color: isDark ? Colors.white54 : Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppDimensions.space32),

              // Animated Breathing Ring Workspace
              SizedBox(
                height: 200,
                width: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Pulsing Glow Circle
                    BreathingWidget(
                      minScale: 0.8,
                      maxScale: 1.25,
                      duration: const Duration(seconds: 4),
                      child: AnimatedContainer(
                        duration: const Duration(seconds: 2),
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _breathColor.withOpacity(0.08),
                          border: Border.all(
                            color: _breathColor.withOpacity(0.35),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _breathColor.withOpacity(0.2),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Inner Core Circle
                    BreathingWidget(
                      minScale: 0.9,
                      maxScale: 1.15,
                      duration: const Duration(seconds: 4),
                      child: AnimatedContainer(
                        duration: const Duration(seconds: 2),
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _breathColor.withOpacity(0.18),
                          border: Border.all(
                            color: _breathColor,
                            width: 2.5,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.spa_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space32),

              // Current Breathing Stage Text
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                child: Text(
                  _breathState,
                  key: ValueKey<String>(_breathState),
                  style: AppTypography.handWritten(
                    isDark: isDark,
                    fontSize: 28,
                  ).copyWith(
                    color: _breathColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space8),

              Text(
                'Elapsed: ${_seconds}s',
                style: AppTypography.bodySmall(isDark: isDark).copyWith(
                  color: isDark ? Colors.white38 : Colors.black38,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppDimensions.space16),
            ],
          ),
        ),
      ),
    );
  }
}
