import 'package:flutter/material.dart';

class ParallaxBackground extends StatelessWidget {
  final double scrollOffset;
  final Widget foreground;
  final Widget background;
  final Widget? midground;

  const ParallaxBackground({
    super.key,
    required this.scrollOffset,
    required this.foreground,
    required this.background,
    this.midground,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background layer (e.g. sky) - moves slowest
        Positioned(
          top: -scrollOffset * 0.15,
          left: 0,
          right: 0,
          bottom: 0,
          child: background,
        ),
        
        // Midground layer (e.g. distant hills/mountains) - moves medium speed
        if (midground != null)
          Positioned(
            top: -scrollOffset * 0.35,
            left: -20,
            right: -20,
            bottom: 0,
            child: midground!,
          ),
          
        // Foreground layer (e.g. actual garden or main view) - moves normal speed
        Positioned(
          top: -scrollOffset,
          left: 0,
          right: 0,
          bottom: 0,
          child: foreground,
        ),
      ],
    );
  }
}
