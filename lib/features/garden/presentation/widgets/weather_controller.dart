import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glassmorphic_card.dart';
import '../providers/garden_state_provider.dart';

class WeatherController extends ConsumerWidget {
  const WeatherController({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gardenState = ref.watch(gardenStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassmorphicCard(
      borderRadius: AppDimensions.radius24,
      padding: const EdgeInsets.all(AppDimensions.space16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle/indicator
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.space12),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Garden Atmosphere',
                style: AppTypography.journalSubTitle(isDark: isDark).copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.wb_sunny_outlined,
                size: 20,
                color: isDark ? AppColors.sunGold : AppColors.tulipPink,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),

          // Time-of-day Selector Row
          Text(
            'Time Shift',
            style: AppTypography.bodySmall(isDark: isDark).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: DayTime.values.map((time) {
                final isSelected = gardenState.time == time;
                return Padding(
                  padding: const EdgeInsets.only(right: AppDimensions.space8),
                  child: InkWell(
                    onTap: () {
                      ref.read(gardenStateProvider.notifier).updateTime(time);
                    },
                    borderRadius: BorderRadius.circular(AppDimensions.radius12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space12,
                        vertical: AppDimensions.space8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? AppColors.tulipPinkDark : AppColors.tulipPink)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : (isDark ? Colors.white10 : Colors.black12),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(AppDimensions.radius12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getTimeIcon(time),
                            size: 16,
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          ),
                          const SizedBox(width: AppDimensions.space8),
                          Text(
                            _getTimeName(time),
                            style: AppTypography.bodyMedium(isDark: isDark).copyWith(
                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: AppDimensions.space12),

          // Weather Selector Row
          Text(
            'Weather Ambient',
            style: AppTypography.bodySmall(isDark: isDark).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: GardenWeather.values.map((weather) {
                final isSelected = gardenState.weather == weather;
                return Padding(
                  padding: const EdgeInsets.only(right: AppDimensions.space8),
                  child: InkWell(
                    onTap: () {
                      ref.read(gardenStateProvider.notifier).updateWeather(weather);
                    },
                    borderRadius: BorderRadius.circular(AppDimensions.radius12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space12,
                        vertical: AppDimensions.space8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? AppColors.tulipPink : AppColors.leafGreenLight)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : (isDark ? Colors.white10 : Colors.black12),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(AppDimensions.radius12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getWeatherIcon(weather),
                            size: 16,
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          ),
                          const SizedBox(width: AppDimensions.space8),
                          Text(
                            _getWeatherName(weather),
                            style: AppTypography.bodyMedium(isDark: isDark).copyWith(
                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTimeIcon(DayTime time) {
    switch (time) {
      case DayTime.morning:
        return Icons.wb_twilight_outlined;
      case DayTime.afternoon:
        return Icons.wb_sunny;
      case DayTime.evening:
        return Icons.nights_stay;
      case DayTime.night:
        return Icons.mode_night_outlined;
    }
  }

  String _getTimeName(DayTime time) {
    switch (time) {
      case DayTime.morning:
        return 'Morning';
      case DayTime.afternoon:
        return 'Afternoon';
      case DayTime.evening:
        return 'Dusk';
      case DayTime.night:
        return 'Midnight';
    }
  }

  IconData _getWeatherIcon(GardenWeather weather) {
    switch (weather) {
      case GardenWeather.sunny:
        return Icons.wb_sunny_rounded;
      case GardenWeather.rainy:
        return Icons.water_drop;
      case GardenWeather.starry:
        return Icons.star_border_purple500_rounded;
      case GardenWeather.windy:
        return Icons.air_rounded;
    }
  }

  String _getWeatherName(GardenWeather weather) {
    switch (weather) {
      case GardenWeather.sunny:
        return 'Sunny';
      case GardenWeather.rainy:
        return 'Rainy';
      case GardenWeather.starry:
        return 'Starry';
      case GardenWeather.windy:
        return 'Windy';
    }
  }
}
