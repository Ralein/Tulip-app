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
        
    final resolvedBorderColor = borderColor ?? 
        (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight);

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
            padding: padding,
            decoration: BoxDecoration(
              color: resolvedBgColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: resolvedBorderColor,
                width: borderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
