import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glassmorphic_card.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  void _showPromptDialog(BuildContext context, bool isDark) {
    final prompts = [
      "What is something that made your inner garden smile today?",
      "If your mood was a weather pattern, what would it be?",
      "Write about a gentle breeze that brought you calm today.",
      "What thoughts do you want to prune away today?",
      "Who or what watered your soul today?",
    ];
    final randomPrompt = prompts[DateTime.now().day % prompts.length];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.space24),
          child: GlassmorphicCard(
            padding: const EdgeInsets.all(AppDimensions.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_stories_rounded,
                  color: AppColors.tulipPink,
                  size: 32,
                ),
                const SizedBox(height: AppDimensions.space16),
                Text(
                  'Daily Reflection Sprout',
                  style: AppTypography.journalSubTitle(isDark: isDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.space12),
                Text(
                  '"$randomPrompt"',
                  style: AppTypography.bodyNormal(isDark: isDark).copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.space24),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.tulipPink,
                  ),
                  child: const Text('Gently Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reflection Prompt Button
        GestureDetector(
          onTap: () => _showPromptDialog(context, isDark),
          child: GlassmorphicCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space16,
              vertical: AppDimensions.space12,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.sunGold,
                  size: 18,
                ),
                const SizedBox(width: AppDimensions.space8),
                Text(
                  'Reflection Prompt',
                  style: AppTypography.bodySmall(isDark: isDark).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
