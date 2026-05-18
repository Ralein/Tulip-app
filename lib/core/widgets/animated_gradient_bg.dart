import 'package:flutter/material.dart';
import '../../features/garden/presentation/providers/garden_state_provider.dart';

class AnimatedGradientBg extends StatefulWidget {
  final DayTime timeOfDay;
  final GardenWeather weather;
  final Widget? child;

  const AnimatedGradientBg({
    super.key,
    required this.timeOfDay,
    this.weather = GardenWeather.sunny,
    this.child,
  });

  @override
  State<AnimatedGradientBg> createState() => _AnimatedGradientBgState();
}

class _AnimatedGradientBgState extends State<AnimatedGradientBg>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -0.2, end: 0.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Color> _getGradientColors(DayTime time, GardenWeather weather) {
    final List<Color> baseColors = switch (time) {
      DayTime.morning => [
          const Color(0xFFFFE0B2), // Warm Peach
          const Color(0xFFF1F8E9), // Light Sage Green
          const Color(0xFFE3F2FD), // Sky Blue Light
        ],
      DayTime.afternoon => [
          const Color(0xFFBBDEFB), // Soft Blue
          const Color(0xFFE3F2FD), // Warm Sky Light
          const Color(0xFFFFF9C4), // Soft Sunlit Cream
        ],
      DayTime.evening => [
          const Color(0xFFFFB74D), // Dusk Orange
          const Color(0xFFF06292), // Sunset Pink
          const Color(0xFF4A148C), // Evening Purple
        ],
      DayTime.night => [
          const Color(0xFF0D47A1), // Midnight Navy
          const Color(0xFF1A237E), // Indigo
          const Color(0xFF000000), // Pure Dark
        ],
    };

    // Morph colors gently depending on weather
    switch (weather) {
      case GardenWeather.rainy:
        // Blend with misty, dark slate/cyan tones for cozy rainfall mood
        return baseColors.map((color) => Color.lerp(color, const Color(0xFF455A64), 0.5)!).toList();
      case GardenWeather.starry:
        // Blend with beautiful cosmic violet/indigo
        return baseColors.map((color) => Color.lerp(color, const Color(0xFF311B92), 0.25)!).toList();
      case GardenWeather.windy:
        // Shifting with dusty bronze/amber hues
        return baseColors.map((color) => Color.lerp(color, const Color(0xFF8D6E63), 0.2)!).toList();
      case GardenWeather.sunny:
      default:
        return baseColors;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getGradientColors(widget.timeOfDay, widget.weather);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _animation.value, -1.0),
              end: Alignment(1.0 - _animation.value, 1.0),
              colors: colors,
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}
