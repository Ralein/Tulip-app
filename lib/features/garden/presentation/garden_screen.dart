import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_gradient_bg.dart';
import '../../../core/widgets/glassmorphic_card.dart';
import '../../../core/widgets/particle_system.dart';
import '../../journal/presentation/providers/journal_provider.dart';
import 'providers/garden_state_provider.dart';
import 'widgets/breathing_dialog.dart';
import 'widgets/fishbowl_dialog.dart';
import 'widgets/streak_counter.dart';
import 'widgets/weather_controller.dart';
import 'helpers/web_bridge.dart';

class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  WebViewController? _webViewController;
  bool _isAtmosphereOpen = false;

  final List<Map<String, String>> _hotspotsData = const [
    {
      'id': 'hotspot-1',
      'title': 'Botany Table',
      'description': 'The diary of an old botanist has been preserved here',
      'orbit': '170deg 80deg 0.90m',
      'target': '0.90 1.10 7.28',
    },
    {
      'id': 'hotspot-2',
      'title': 'Garden Logs',
      'description': 'Browse your beautiful reflective journal logs here',
      'orbit': '170deg 60deg 0.50m',
      'target': '0.02 0.48 3.41',
    },
    {
      'id': 'hotspot-3',
      'title': 'Aqua Sanctuary',
      'description': 'Interact with 3D fish and practice virtual gardening here',
      'orbit': '370deg 55deg 0.70m',
      'target': '-1.0 1.0 -2.0',
    },
  ];

  int _activeHotspotIndex = -1;
  String? _activeHotspotId;

  @override
  void initState() {
    super.initState();
    initPlatformWebBridge((slotId) {
      _handleHotspotClick(slotId);
    });
  }

  void _resetCamera() {
    resetCameraOnWeb();
    setState(() {
      _activeHotspotIndex = -1;
      _activeHotspotId = null;
    });
    _webViewController?.runJavaScript('''
      const viewer = document.querySelector('model-viewer');
      if (viewer) {
        viewer.setAttribute('interpolation-decay', '200');
        viewer.cameraOrbit = 'auto auto auto';
        viewer.cameraTarget = 'auto auto auto';
        viewer.autoRotate = true;
        document.querySelectorAll('.hotspot-btn').forEach(b => b.classList.remove('active'));
      }
    ''');
  }

  void _handleHotspotSelect(String slotId) {
    final index = _hotspotsData.indexWhere((h) => h['id'] == slotId);
    if (index != -1) {
      setState(() {
        _activeHotspotIndex = index;
        _activeHotspotId = slotId;
      });
    }
  }

  void _launchHotspotAction(String slotId) {
    switch (slotId) {
      case 'hotspot-1':
        context.go('/editor');
        break;
      case 'hotspot-2':
        context.go('/entries');
        break;
      case 'hotspot-3':
        _showFishbowlModal();
        break;
      case 'hotspot-4':
        _showBreathingModal();
        break;
      case 'hotspot-5':
        // Memory Garden — distinct from Journal Logs
        context.go('/memory-garden');
        break;
    }
  }

  void _handleHotspotClick(String slotId) {
    if (!mounted) return;
    _handleHotspotSelect(slotId);
    _launchHotspotAction(slotId);
  }

  void _selectHotspotFromSlider(int index) {
    if (index < 0 || index >= _hotspotsData.length) return;
    final hotspot = _hotspotsData[index];
    final slotId = hotspot['id']!;
    setState(() {
      _activeHotspotIndex = index;
      _activeHotspotId = slotId;
    });

    _webViewController?.runJavaScript('''
      const viewer = document.querySelector('model-viewer');
      if (viewer) {
        document.querySelectorAll('.hotspot-btn').forEach(b => b.classList.remove('active'));
        const activeBtn = document.querySelector('[slot="$slotId"]');
        if (activeBtn) activeBtn.classList.add('active');

        viewer.setAttribute('interpolation-decay', '250');
        viewer.autoRotate = false;
        viewer.cameraOrbit = "${hotspot['orbit']}";
        viewer.cameraTarget = "${hotspot['target']}";
      }
    ''');
  }

  void _showFishbowlModal() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => const FishbowlDialog(),
    );
  }

  void _showBreathingModal() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => const BreathingDialog(),
    );
  }

  /// Calculates a consecutive-day streak from a list of journal entries.
  /// Assumes each entry exposes a [createdAt] DateTime field.
  int _calculateStreak(List<dynamic> entries) {
    if (entries.isEmpty) return 0;

    final days =
        entries
            .map(
              (e) => DateTime(
                e.createdAt.year,
                e.createdAt.month,
                e.createdAt.day,
              ),
            )
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a)); // newest first

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Streak must include today or yesterday to be active
    if (days.first.isBefore(todayDate.subtract(const Duration(days: 1)))) {
      return 0;
    }

    int streak = 1;
    for (int i = 0; i < days.length - 1; i++) {
      final diff = days[i].difference(days[i + 1]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final entriesAsync = ref.watch(journalEntriesProvider);
        final gardenState = ref.watch(gardenStateProvider);

        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Time-of-day + weather gradient background
              AnimatedGradientBg(
                timeOfDay: gardenState.time,
                weather: gardenState.weather,
              ),

              // 2. Atmospheric particles (petals, rain, snow, etc.)
              Positioned.fill(
                child: ParticleSystemWidget(weather: gardenState.weather),
              ),

              // 3. Central 3D model
              Positioned.fill(
                child: SafeArea(
                  child: ModelViewer(
                    id: 'mangrove-greenhouse',
                    src: kIsWeb
                        ? 'assets/assets/images/stylized_mangrove_greenhouse.glb'
                        : 'assets/images/stylized_mangrove_greenhouse.glb',
                    alt: 'A premium 3D mangrove greenhouse sanctuary',
                    backgroundColor: Colors.transparent,
                    autoRotate: true,
                    autoRotateDelay: 6000,
                    rotationPerSecond: '12deg',
                    cameraControls: true,
                    exposure: 1.15,
                    interactionPrompt: InteractionPrompt.none,
                    minCameraOrbit: 'auto auto 0.1m',
                    maxCameraOrbit: 'auto auto auto',
                    javascriptChannels: {
                      JavascriptChannel(
                        'HotspotChannel',
                        onMessageReceived: (message) {
                          _handleHotspotClick(message.message);
                        },
                      ),
                      JavascriptChannel(
                        'HotspotSelectChannel',
                        onMessageReceived: (message) {
                          _handleHotspotSelect(message.message);
                        },
                      ),
                    },
                    onWebViewCreated: (controller) {
                      _webViewController = controller;
                    },
                    innerModelViewerHtml: '''
                      <img src="x" style="display:none;" onerror="
                        if (!window.twLoaded) {
                          window.twLoaded = true;
                          const script = document.createElement('script');
                          script.src = 'https://cdn.tailwindcss.com';
                          document.head.appendChild(script);
                          
                          window.tailwind = window.tailwind || {};
                          window.tailwind.config = {
                            theme: {
                              extend: {
                                keyframes: {
                                  'pulse-ring': {
                                    '0%': { transform: 'scale(0.85)', opacity: '0.6' },
                                    '100%': { transform: 'scale(1.35)', opacity: '0' }
                                  }
                                },
                                animation: {
                                  'pulse-ring': 'pulse-ring 2.4s infinite ease-out'
                                }
                              }
                            }
                          };
                        }

                        // Register pointerdown listener on the model-viewer to ensure manual rotation remains snappy and premium
                        setTimeout(function() {
                          const viewer = document.querySelector('model-viewer');
                          if (viewer) {
                            viewer.addEventListener('pointerdown', () => {
                              viewer.setAttribute('interpolation-decay', '80');
                            });
                          }
                        }, 200);

                        window.zoomToHotspot = function(slotId) {
                          const viewer = document.querySelector('model-viewer');
                          if (!viewer) {
                            if (typeof HotspotChannel !== 'undefined') {
                              HotspotChannel.postMessage(slotId);
                            } else {
                              window.parent.postMessage(slotId, '*');
                            }
                            return;
                          }

                          const activeBtn = document.querySelector('[slot=\\'' + slotId + '\\']');
                          const isAlreadyActive = activeBtn && activeBtn.classList.contains('active');

                          document.querySelectorAll('.hotspot-btn').forEach(b => b.classList.remove('active'));
                          if (activeBtn) activeBtn.classList.add('active');

                          // ── Camera targets (snappy & zoomed in closer for premium feel) ────────
                          const cameraTargets = {
                            'hotspot-1': { orbit: '170deg 80deg 0.90m', target: '0.90 1.10 7.28' }, 
                            'hotspot-2': { orbit: '170deg 60deg 0.50m', target: '0.02 0.48 3.41' }, // Tilted down
                            'hotspot-3': { orbit: '370deg 55deg 0.70m', target: '-1.0 1.0 -2.0' }  // Panned significantly left to center the pond
                          };

                          const target = cameraTargets[slotId];
                          if (target) {
                            viewer.setAttribute('interpolation-decay', '250');
                            viewer.autoRotate = false;
                            viewer.cameraOrbit = target.orbit;
                            viewer.cameraTarget = target.target;
                          }

                          // Notify Flutter of selection
                          if (typeof HotspotSelectChannel !== 'undefined') {
                            HotspotSelectChannel.postMessage(slotId);
                          } else {
                            window.parent.postMessage(slotId, '*');
                          }

                          if (isAlreadyActive) {
                            // 2nd click: Interact!
                            if (typeof HotspotChannel !== 'undefined') {
                              HotspotChannel.postMessage(slotId);
                            } else {
                              window.parent.postMessage(slotId, '*');
                            }
                          }
                        };

                        // Register message listener to receive reset commands from Flutter Web
                        window.addEventListener('message', function(event) {
                          if (event.data === 'reset-camera') {
                            const viewer = document.querySelector('model-viewer');
                            if (viewer) {
                              viewer.setAttribute('interpolation-decay', '200');
                              // Force reset of camera properties by removing them or setting to auto
                              viewer.removeAttribute('camera-orbit');
                              viewer.removeAttribute('camera-target');
                              viewer.cameraOrbit = 'auto auto auto';
                              viewer.cameraTarget = 'auto auto auto';
                              viewer.autoRotate = true;
                              document.querySelectorAll('.hotspot-btn').forEach(b => b.classList.remove('active'));
                            }
                          }
                        });
                      " />

                      <style type="text/tailwindcss">
                        @layer components {
                          .hotspot-btn {
                            @apply relative bg-[rgba(14,165,233,0.65)] text-white border border-[rgba(255,255,255,0.45)] rounded-full w-7 h-7 font-sans font-bold text-xs cursor-pointer flex items-center justify-center p-0 transition-all duration-[400ms] ease-[cubic-bezier(0.34,1.56,0.64,1)] backdrop-blur-sm shadow-[0_0_10px_rgba(56,189,248,0.4)];
                            transform-style: preserve-3d;
                          }

                          .hotspot-btn::after {
                            @apply content-[''] absolute -top-[4px] -left-[4px] -right-[4px] -bottom-[4px] border border-[rgba(56,189,248,0.4)] rounded-full opacity-0 pointer-events-none animate-pulse-ring;
                          }

                          .hotspot-btn:hover {
                            @apply bg-[rgba(14,165,233,0.9)] text-white border-white shadow-[0_0_15px_rgba(56,189,248,0.7)];
                            transform: scale(1.15);
                          }

                          .hotspot-btn:active {
                            @apply bg-[rgba(14,165,233,0.95)] shadow-[0_2px_8px_rgba(0,0,0,0.2)];
                            transform: scale(1.05);
                            transition-duration: 150ms;
                          }

                          .hotspot-btn.active {
                            @apply bg-[rgba(14,165,233,0.85)] border-white shadow-[0_0_20px_rgba(56,189,248,0.8)];
                            transform: scale(1.1);
                          }
                        }
                      </style>

                      <!-- Hotspot 1 · Botany Table -->
                      <button slot="hotspot-1" data-position="0.78 1.01 7.28" data-normal="0 1 0" class="hotspot-btn" onclick="zoomToHotspot('hotspot-1')">
                        1
                      </button>

                      <!-- Hotspot 2 · Garden Logs -->
                      <button slot="hotspot-2" data-position="0.02 0.48 3.41" data-normal="0 1 0" class="hotspot-btn" onclick="zoomToHotspot('hotspot-2')">
                        2
                      </button>

                      <!-- Hotspot 3 · Aqua Sanctuary -->
                      <button slot="hotspot-3" data-position="0.0 1.0 -2.0" data-normal="0 1 0" class="hotspot-btn" onclick="zoomToHotspot('hotspot-3')">
                        3
                      </button>
                    ''',
                  ),
                ),
              ),

              // 4. Glowing HUD header
              Positioned(
                top: MediaQuery.of(context).padding.top + AppDimensions.space8,
                left: AppDimensions.space16,
                right: AppDimensions.space16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Streak counter with real consecutive-day calculation
                    entriesAsync.maybeWhen(
                      data: (entries) =>
                          StreakCounter(streakDays: _calculateStreak(entries)),
                      orElse: () => const StreakCounter(streakDays: 0),
                    ),

                    // Hint pill
                    GlassmorphicCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.touch_app_outlined,
                            size: 16,
                            color: isDark
                                ? AppColors.sunGold
                                : AppColors.tulipPinkDark,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tap nodes to interact',
                            style: AppTypography.bodySmall(isDark: isDark)
                                .copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                          ),
                        ],
                      ),
                    ),

                    // Navigation & control actions
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Reset View Compass button
                        InkWell(
                          onTap: _resetCamera,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull,
                          ),
                          child: GlassmorphicCard(
                            padding: const EdgeInsets.all(
                              AppDimensions.space12,
                            ),
                            child: Icon(
                              Icons.explore,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.tulipPinkDark,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.space8),
                        // Atmosphere/Weather button
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isAtmosphereOpen = !_isAtmosphereOpen;
                            });
                          },
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull,
                          ),
                          child: GlassmorphicCard(
                            padding: const EdgeInsets.all(
                              AppDimensions.space12,
                            ),
                            child: Icon(
                              _isAtmosphereOpen ? Icons.wb_cloudy_rounded : Icons.cloud_outlined,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.tulipPinkDark,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.space8),
                        // View logs button
                        InkWell(
                          onTap: () => context.go('/entries'),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull,
                          ),
                          child: GlassmorphicCard(
                            padding: const EdgeInsets.all(
                              AppDimensions.space12,
                            ),
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.tulipPinkDark,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 5. Floating Native Description Tooltip Box
              AnimatedPositioned(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutBack,
                bottom: _activeHotspotIndex != -1 ? 96.0 : 48.0,
                left: AppDimensions.space24,
                right: AppDimensions.space24,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _activeHotspotIndex != -1 ? 1.0 : 0.0,
                  child: _activeHotspotIndex != -1
                      ? Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 340),
                            child: InkWell(
                              onTap: () => _launchHotspotAction(_activeHotspotId!),
                              borderRadius: BorderRadius.circular(AppDimensions.radius24),
                              child: GlassmorphicCard(
                                borderRadius: AppDimensions.radius24,
                                padding: const EdgeInsets.all(AppDimensions.space16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _hotspotsData[_activeHotspotIndex]['title']!,
                                          style: AppTypography.journalSubTitle(isDark: isDark).copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 16,
                                          color: AppColors.skyBlue,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _hotspotsData[_activeHotspotIndex]['description']!,
                                      style: AppTypography.bodySmall(isDark: isDark).copyWith(
                                        color: Colors.white70,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),

              // 6. Bottom Glassmorphic Hotspot Switcher Slider Pill
              Positioned(
                bottom: 24.0,
                left: AppDimensions.space24,
                right: AppDimensions.space24,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: GlassmorphicCard(
                      borderRadius: AppDimensions.radiusFull,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left Cycle button
                          IconButton(
                            onPressed: () {
                              final newIndex = _activeHotspotIndex == -1
                                  ? 2
                                  : (_activeHotspotIndex - 1 + _hotspotsData.length) % _hotspotsData.length;
                              _selectHotspotFromSlider(newIndex);
                            },
                            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),

                          // Interactive center label
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                if (_activeHotspotIndex != -1) {
                                  _launchHotspotAction(_activeHotspotId!);
                                } else {
                                  _selectHotspotFromSlider(0);
                                }
                              },
                              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  _activeHotspotIndex != -1
                                      ? _hotspotsData[_activeHotspotIndex]['title']!
                                      : 'Explore Sanctuary',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodyMedium(isDark: true).copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Right Cycle button
                          IconButton(
                            onPressed: () {
                              final newIndex = _activeHotspotIndex == -1
                                  ? 0
                                  : (_activeHotspotIndex + 1) % _hotspotsData.length;
                              _selectHotspotFromSlider(newIndex);
                            },
                            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 7. Sliding Atmosphere Controller Card
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
                top: _isAtmosphereOpen
                    ? MediaQuery.of(context).padding.top + 70.0
                    : -320.0, // Hidden off-screen above
                right: AppDimensions.space16,
                left: MediaQuery.of(context).size.width > 360
                    ? null
                    : AppDimensions.space16,
                width: MediaQuery.of(context).size.width > 360
                    ? 320
                    : null,
                child: const WeatherController(),
              ),
            ],
          ),
        );
      },
    );
  }
}
