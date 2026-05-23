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
          const Color(0xFF456B5D), // Soft Golden Sage Glow (Center)
          const Color(0xFF1E2D30), // Deep Teal Mist
          const Color(0xFF0C1318), // Dark Slate Border
        ],
      DayTime.afternoon => [
          const Color(0xFFC85A46), // Warm Reddish-Terracotta Sunset Glow (Center)
          const Color(0xFF4E201B), // Cozy Rich Mahogany
          const Color(0xFF220D0A), // Warm Charcoal Shadows
        ],
      DayTime.evening => [
          const Color(0xFF8C3E61), // Burning Twilight Rose (Center)
          const Color(0xFF412048), // Royal Evening Purple
          const Color(0xFF150B18), // Midnight Void
        ],
      DayTime.night => [
          const Color(0xFF203B56), // Mystical Deep Cobalt Glow (Center)
          const Color(0xFF0F172E), // Deep Space Indigo
          const Color(0xFF050814), // Infinite Midnight Black
        ],
    };

    // Morph colors gently depending on weather
    switch (weather) {
      case GardenWeather.rainy:
        // Blend with misty, cool dark steel-grey for rainy cozy mood
        return baseColors.map((color) => Color.lerp(color, const Color(0xFF263238), 0.6)!).toList();
      case GardenWeather.starry:
        // Blend with glowing cosmic violet/indigo
        return baseColors.map((color) => Color.lerp(color, const Color(0xFF1A0F30), 0.45)!).toList();
      case GardenWeather.windy:
        // Blend with mystical dusty bronze/amber
        return baseColors.map((color) => Color.lerp(color, const Color(0xFF4E3629), 0.3)!).toList();
      case GardenWeather.sunny:
        return baseColors;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getGradientColors(widget.timeOfDay, widget.weather);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Deep base linear gradient
            AnimatedContainer(
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    colors[1],
                    colors[2],
                  ],
                ),
              ),
            ),
            // Floating, breathing radial glow (mesh effect)
            AnimatedContainer(
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(_animation.value * 0.8, _animation.value - 0.2),
                  radius: 1.6,
                  colors: [
                    colors[0].withValues(alpha: 0.85),
                    colors[1].withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
            if (widget.child != null) widget.child!,
          ],
        );
      },
    );
  }
}
