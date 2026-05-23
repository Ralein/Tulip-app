import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

class OnboardingPageData {
  final IconData icon;
  final String tagline;
  final String description;
  final Color themeColor;

  const OnboardingPageData({
    required this.icon,
    required this.tagline,
    required this.description,
    required this.themeColor,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late PageController _pageController;
  int _currentPage = 0;

  final List<OnboardingPageData> _pages = const [
    OnboardingPageData(
      icon: Icons.local_florist_rounded,
      tagline: 'Nurture your inner garden',
      description: 'Step into a peaceful, interactive sanctuary to water and tend your inner thoughts. Every journal entry plants a seed that flourishes in real-time.',
      themeColor: AppColors.tulipPink,
    ),
    OnboardingPageData(
      icon: Icons.water_drop_rounded,
      tagline: 'Reflect & Grow',
      description: 'Your words provide life-giving water to your botanical sanctuary. Write regular entries to spark vibrant blooms in your 3D greenhouse.',
      themeColor: AppColors.skyBlue,
    ),
    OnboardingPageData(
      icon: Icons.spa_rounded,
      tagline: 'Cultivate Peace of Mind',
      description: 'Interact with local hotspots, adjust the weather ambient, and breathe deeply. Tulip is designed to help you find moments of absolute presence.',
      themeColor: AppColors.leafGreen,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full-screen looping onboarding GIF
          Image.asset(
            'assets/images/garden_onboarding.gif',
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),

          // 2. Sophisticated gradient overlay for text readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.25),
                  Colors.black.withValues(alpha: 0.45),
                  Colors.black.withValues(alpha: 0.8),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // 3. Safe area overlay content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space32,
                vertical: AppDimensions.space24,
              ),
              child: AnimatedBuilder(
                animation: _fadeController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0.0, _slideAnimation.value),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppDimensions.space16),
                    // App Title (always visible, anchors the branding)
                    Text(
                      'Tulip',
                      style: AppTypography.journalTitle(isDark: true).copyWith(
                        fontSize: 44,
                        letterSpacing: 2.0,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            offset: const Offset(0, 4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    // Swipeable Main Content Area
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemCount: _pages.length,
                        itemBuilder: (context, index) {
                          final page = _pages[index];
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Beautiful ambient-colored floating icon
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                padding: const EdgeInsets.all(AppDimensions.space16),
                                decoration: BoxDecoration(
                                  color: page.themeColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: page.themeColor.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  page.icon,
                                  color: page.themeColor,
                                  size: 48,
                                ),
                              ),
                              const SizedBox(height: 28.0),

                              // Page Tagline
                              Text(
                                page.tagline,
                                style: AppTypography.handWritten(isDark: true, fontSize: 26).copyWith(
                                  color: AppColors.moonYellow,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      offset: const Offset(0, 2),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20.0),

                              // Glassmorphic Details Card
                              Container(
                                padding: const EdgeInsets.all(AppDimensions.space24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppDimensions.radius24),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 15,
                                      spreadRadius: -2,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  page.description,
                                  style: AppTypography.bodyNormal(isDark: true).copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    height: 1.6,
                                    fontSize: 15,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // Active Bubble Page Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (index) {
                        final isSelected = _currentPage == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 320),
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          height: 8.0,
                          width: isSelected ? 24.0 : 8.0,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? _pages[index].themeColor 
                                : Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: AppDimensions.space32),

                    // Glowing Action Button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 320),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                        boxShadow: [
                          BoxShadow(
                            color: _pages[_currentPage].themeColor.withValues(alpha: 0.45),
                            blurRadius: 20,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentPage < _pages.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            // Navigate to 3D Garden main screen!
                            context.go('/garden');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _pages[_currentPage].themeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: AppDimensions.space16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == _pages.length - 1 ? 'Start Journey' : 'Next',
                              style: AppTypography.buttonText(isDark: true).copyWith(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.space8),
                            Icon(
                              _currentPage == _pages.length - 1 
                                  ? Icons.arrow_forward_rounded 
                                  : Icons.navigate_next_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
