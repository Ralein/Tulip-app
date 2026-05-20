import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double borderRadius;
  final Color? color;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;
  final double borderWidth;
  final List<BoxShadow>? customShadows;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.borderRadius = AppDimensions.radius24,
    this.color,
    this.borderColor,
    this.padding = const EdgeInsets.all(AppDimensions.space16),
    this.borderWidth = 1.5,
    this.customShadows,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final resolvedBgColor = color ?? 
        (isDark ? AppColors.glassCardDark : AppColors.glassCardLight);

    return Container(
      decoration: BoxDecoration(
        boxShadow: customShadows ?? AppDimensions.glassShadow(isDark: isDark),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: EdgeInsets.all(borderWidth),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.4 : 0.7),
                  Colors.white.withValues(alpha: 0.0),
                  isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                  isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.15),
                ],
                stops: const [0.0, 0.4, 0.8, 1.0],
              ),
            ),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius > borderWidth ? borderRadius - borderWidth : 0),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: isDark ? 0.12 : 0.35),
                    resolvedBgColor,
                    resolvedBgColor,
                    Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                  ],
                  stops: const [0.0, 0.15, 0.85, 1.0],
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
