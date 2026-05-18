import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_gradient_bg.dart';
import '../../../core/widgets/tulip_painter.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageData> _pages = [
    const OnboardingPageData(
      title: "Welcome to Tulip",
      description: "A sanctuary to water and tend your inner thoughts. Your mind is a beautiful garden waiting to flourish.",
      growthProgress: 0.3,
      bloomFactor: 0.0,
      tulipColor: AppColors.soilBrownLight,
    ),
    const OnboardingPageData(
      title: "Tend Your Sprout",
      description: "Every journal log plants a fresh vector seedling. As you write down your reflections, watch it sway and rise.",
      growthProgress: 0.7,
      bloomFactor: 0.2,
      tulipColor: AppColors.leafGreenLight,
    ),
    const OnboardingPageData(
      title: "Flourish in Bloom",
      description: "Consistency lets your garden thrive. Express your moods, discover glowing colors, and build a beautiful, sticky writing habit.",
      growthProgress: 1.0,
      bloomFactor: 1.0,
      tulipColor: AppColors.tulipPinkLight,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedGradientBg(timeOfDay: DayTime.morning),
          
          PageView.builder(
            controller: _pageController,
            onPageChanged: (int index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final page = _pages[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Dynamic visual showcase: High-fidelity onboarding GIF on Page 1, Vector Tulip painter on others!
                    Container(
                      height: 220,
                      width: 280,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppDimensions.radius24),
                        boxShadow: [
                          BoxShadow(
                            color: page.tulipColor.withOpacity(0.25),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimensions.radius24),
                        child: index == 0
                            ? Image.asset(
                                'assets/images/garden_onboarding.gif',
                                fit: BoxFit.cover,
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                                  border: Border.all(
                                    color: isDark ? Colors.white12 : Colors.black12,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(AppDimensions.radius24),
                                ),
                                padding: const EdgeInsets.all(AppDimensions.space24),
                                child: CustomPaint(
                                  painter: TulipPainter(
                                    tulipColor: page.tulipColor,
                                    growthProgress: page.growthProgress,
                                    bloomFactor: page.bloomFactor,
                                    swayAngle: 0.04,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space32),
                    Text(
                      page.title,
                      style: AppTypography.journalTitle(isDark: isDark).copyWith(fontSize: 28),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    Text(
                      page.description,
                      style: AppTypography.bodyNormal(isDark: isDark).copyWith(
                        height: 1.5,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),

          // Bottom Page Indicator & Action Button
          Positioned(
            bottom: 40,
            left: AppDimensions.space32,
            right: AppDimensions.space32,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Page Dots
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 6),
                      width: _currentPage == index ? 18 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppColors.tulipPink
                            : (isDark ? Colors.white24 : Colors.black12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                // Action Button
                TextButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      // Navigate to Garden Dashboard!
                      context.go('/');
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AppColors.tulipPink,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1 ? "Enter Garden" : "Next",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPageData {
  final String title;
  final String description;
  final double growthProgress;
  final double bloomFactor;
  final Color tulipColor;

  const OnboardingPageData({
    required this.title,
    required this.description,
    required this.growthProgress,
    required this.bloomFactor,
    required this.tulipColor,
  });
}
