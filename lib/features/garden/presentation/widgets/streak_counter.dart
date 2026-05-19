import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/breathing_widget.dart';

class StreakCounter extends StatelessWidget {
  final int streakDays;

  const StreakCounter({
    super.key,
    required this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BreathingWidget(
      minScale: 0.97,
      maxScale: 1.03,
      duration: const Duration(seconds: 3),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space8,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.glassCardDark : AppColors.glassCardLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: streakDays > 0 
                ? AppColors.sunGold.withValues(alpha: 0.5) 
                : (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight),
            width: 1.5,
          ),
          boxShadow: streakDays > 0
              ? [
                  BoxShadow(
                    color: AppColors.sunGold.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : AppDimensions.glassShadow(isDark: isDark),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Streak Fire / Flame icon with glow
            Icon(
              Icons.local_fire_department_rounded,
              color: streakDays > 0 ? AppColors.sunGold : AppColors.textSecondaryLight,
              size: 22,
            ),
            const SizedBox(width: AppDimensions.space4),
            Text(
              '$streakDays days',
              style: AppTypography.bodyMedium(isDark: isDark).copyWith(
                fontWeight: FontWeight.bold,
                color: streakDays > 0
                    ? (isDark ? AppColors.sunGold : AppColors.tulipPinkDark)
                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
