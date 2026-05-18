import 'package:flutter/material.dart';

enum DayTime { morning, afternoon, evening, night }

class AnimatedGradientBg extends StatefulWidget {
  final DayTime timeOfDay;
  final Widget? child;

  const AnimatedGradientBg({
    super.key,
    required this.timeOfDay,
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
      duration: const Duration(seconds: 10),
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

  List<Color> _getGradientColors(DayTime time) {
    switch (time) {
      case DayTime.morning:
        return [
          const Color(0xFFFFE0B2), // Warm Peach
          const Color(0xFFF1F8E9), // Light Sage Green
          const Color(0xFFE3F2FD), // Sky Blue Light
        ];
      case DayTime.afternoon:
        return [
          const Color(0xFFBBDEFB), // Soft Blue
          const Color(0xFFE3F2FD), // Warm Sky Light
          const Color(0xFFFFF9C4), // Soft Sunlit Cream
        ];
      case DayTime.evening:
        return [
          const Color(0xFFFFB74D), // Dusk Orange
          const Color(0xFFF06292), // Sunset Pink
          const Color(0xFF4A148C), // Evening Purple
        ];
      case DayTime.night:
        return [
          const Color(0xFF0D47A1), // Midnight Navy
          const Color(0xFF1A237E), // Indigo
          const Color(0xFF000000), // Pure Dark
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getGradientColors(widget.timeOfDay);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
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
