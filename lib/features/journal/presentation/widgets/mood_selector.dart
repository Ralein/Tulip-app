import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tulip_painter.dart';

class MoodItem {
  final String key;
  final String label;
  final Color tulipColor;
  final double bloomFactor;

  const MoodItem({
    required this.key,
    required this.label,
    required this.tulipColor,
    required this.bloomFactor,
  });
}

class MoodSelector extends StatelessWidget {
  final String selectedMood;
  final ValueChanged<MoodItem> onMoodSelected;

  static const List<MoodItem> moods = [
    MoodItem(
      key: 'happy',
      label: 'Joyful',
      tulipColor: AppColors.tulipPinkLight,
      bloomFactor: 0.9,
    ),
    MoodItem(
      key: 'calm',
      label: 'Calm',
      tulipColor: AppColors.skyBlue,
      bloomFactor: 0.6,
    ),
    MoodItem(
      key: 'reflective',
      label: 'Reflective',
      tulipColor: AppColors.duskPurpleLight,
      bloomFactor: 0.4,
    ),
    MoodItem(
      key: 'excited',
      label: 'Excited',
      tulipColor: AppColors.sunGold,
      bloomFactor: 1.0,
    ),
    MoodItem(
      key: 'sad',
      label: 'Gently Blue',
      tulipColor: AppColors.soilBrownLight,
      bloomFactor: 0.2,
    ),
  ];

  const MoodSelector({
    super.key,
    required this.selectedMood,
    required this.onMoodSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.space8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: moods.map((mood) {
          final isSelected = selectedMood == mood.key;

          return GestureDetector(
            onTap: () => onMoodSelected(mood),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              padding: const EdgeInsets.all(AppDimensions.space8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppColors.glassCardDark : AppColors.glassCardLight)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppDimensions.radius24),
                border: Border.all(
                  color: isSelected
                      ? mood.tulipColor.withValues(alpha: 0.5)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Beautiful CustomPainted vector tulip showing bloom state per mood
                  SizedBox(
                    width: 40,
                    height: 55,
                    child: CustomPaint(
                      painter: TulipPainter(
                        tulipColor: mood.tulipColor,
                        growthProgress: 1.0,
                        bloomFactor: mood.bloomFactor,
                        swayAngle: isSelected ? 0.05 : 0.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space4),
                  Text(
                    mood.label,
                    style: AppTypography.bodySmall(isDark: isDark).copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                      color: isSelected
                          ? mood.tulipColor
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
