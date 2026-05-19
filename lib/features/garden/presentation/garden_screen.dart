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
import 'widgets/streak_counter.dart';
import 'helpers/web_bridge.dart';


class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    initPlatformWebBridge((slotId) {
      _handleHotspotClick(slotId);
    });
  }

  void _resetCamera() {
    resetCameraOnWeb();
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

  void _handleHotspotClick(String slotId) {
    if (!mounted) return;
    switch (slotId) {
      case 'hotspot-1':
        context.go('/editor');
        break;
      case 'hotspot-2':
        context.go('/entries');
        break;
      case 'hotspot-3':
        _showBreathingModal();
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

    final days = entries
        .map((e) => DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // newest first

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Streak must include today or yesterday to be active
    if (days.first.isBefore(todayDate.subtract(const Duration(days: 1)))) return 0;

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
                child: ParticleSystemWidget(
                  weather: gardenState.weather,
                ),
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
                          if (activeBtn && activeBtn.classList.contains('active')) {
                            // 2nd click: Interact!
                            if (typeof HotspotChannel !== 'undefined') {
                              HotspotChannel.postMessage(slotId);
                            } else {
                              window.parent.postMessage(slotId, '*');
                            }
                          } else {
                            // 1st click: Zoom to the button
                            document.querySelectorAll('.hotspot-btn').forEach(b => b.classList.remove('active'));
                            if (activeBtn) activeBtn.classList.add('active');

                            // ── Camera targets (snappy & zoomed in closer for premium feel) ────────
                            const cameraTargets = {
                              'hotspot-1': { orbit: '190deg 75deg 0.35m', target: '0.78 1.01 7.28' },
                              'hotspot-2': { orbit: '170deg 72deg 0.50m', target: '0.02 0.48 3.41' },
                              'hotspot-3': { orbit: '320deg 55deg 0.70m', target: '-0.5 1.0 -2.0' }
                            };

                            const target = cameraTargets[slotId];
                            if (target) {
                              viewer.setAttribute('interpolation-decay', '250');
                              viewer.autoRotate = false;
                              viewer.cameraOrbit = target.orbit;
                              viewer.cameraTarget = target.target;
                            }
                          }
                        };

                        // Register message listener to receive reset commands from Flutter Web
                        window.addEventListener('message', function(event) {
                          if (event.data === 'reset-camera') {
                            const viewer = document.querySelector('model-viewer');
                            if (viewer) {
                              viewer.setAttribute('interpolation-decay', '200');
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
                            @apply relative bg-[rgba(180,180,180,0.18)] text-[rgba(255,255,255,0.7)] border-[1.5px] border-[rgba(255,255,255,0.15)] rounded-full w-10 h-10 font-sans font-bold text-sm cursor-pointer flex items-center justify-center p-0 transition-all duration-[350ms] ease-[cubic-bezier(0.4,0,0.2,1)] backdrop-blur-md group shadow-[0_0_12px_rgba(255,255,255,0.06),inset_0_0_6px_rgba(255,255,255,0.05)];
                          }

                          .hotspot-btn::after {
                            @apply content-[''] absolute -top-[5px] -left-[5px] -right-[5px] -bottom-[5px] border-[1.5px] border-[rgba(200,200,200,0.2)] rounded-full opacity-0 pointer-events-none animate-pulse-ring;
                          }

                          .hotspot-btn:hover {
                            @apply scale-[1.12] bg-[rgba(220,220,220,0.45)] text-white/95 border-[rgba(255,255,255,0.4)] shadow-[0_0_20px_rgba(255,255,255,0.15),inset_0_0_10px_rgba(255,255,255,0.1)];
                          }

                          .hotspot-btn:active {
                            @apply scale-[1.18] bg-[rgba(240,240,240,0.55)];
                          }

                          .hotspot-btn.active {
                            @apply bg-[rgba(255,255,255,0.35)] border-[rgba(255,255,255,0.5)] shadow-[0_0_25px_rgba(255,255,255,0.2)];
                          }

                          .hotspot-label {
                            @apply absolute left-[50px] bg-[rgba(20,20,30,0.82)] text-[rgba(230,230,230,0.9)] py-1.5 px-3 rounded-[10px] text-xs font-semibold tracking-[0.4px] whitespace-nowrap pointer-events-none border border-[rgba(255,255,255,0.1)] shadow-[0_6px_24px_rgba(0,0,0,0.5)] backdrop-blur-sm opacity-0 -translate-x-1.5 transition-all duration-300 ease-in-out group-hover:opacity-100 group-hover:translate-x-0;
                          }
                        }
                      </style>

                      <!-- Hotspot 1 · Write Sprout — Botany Table (desk inside greenhouse) -->
                      <button slot="hotspot-1" data-position="0.78 1.01 7.28" data-normal="0 1 0" class="hotspot-btn" onclick="zoomToHotspot('hotspot-1')">
                        1<span class="hotspot-label">✏️ Write Sprout</span>
                      </button>

                      <!-- Hotspot 2 · Garden Logs — Pond area -->
                      <button slot="hotspot-2" data-position="0.02 0.48 3.41" data-normal="0 1 0" class="hotspot-btn" onclick="zoomToHotspot('hotspot-2')">
                        2<span class="hotspot-label">📓 Garden Logs</span>
                      </button>

                      <!-- Hotspot 3 · Koi Pond -->
                      <button slot="hotspot-3" data-position="0.0 1.0 -2.0" data-normal="0 1 0" class="hotspot-btn" onclick="zoomToHotspot('hotspot-3')">
                        3<span class="hotspot-label">Koi Pond</span>
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
                      data: (entries) => StreakCounter(
                        streakDays: _calculateStreak(entries),
                      ),
                      orElse: () => const StreakCounter(streakDays: 0),
                    ),

                    // Hint pill
                    GlassmorphicCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.touch_app_outlined,
                            size: 16,
                            color: isDark ? AppColors.sunGold : AppColors.tulipPinkDark,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tap nodes to interact',
                            style: AppTypography.bodySmall(isDark: isDark).copyWith(
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
                          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                          child: GlassmorphicCard(
                            padding: const EdgeInsets.all(AppDimensions.space12),
                            child: Icon(
                              Icons.explore,
                              color: isDark ? Colors.white : AppColors.tulipPinkDark,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.space8),
                        // View logs button
                        InkWell(
                          onTap: () => context.go('/entries'),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                          child: GlassmorphicCard(
                            padding: const EdgeInsets.all(AppDimensions.space12),
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: isDark ? Colors.white : AppColors.tulipPinkDark,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 5. Bottom instruction bar
              Positioned(
                bottom: AppDimensions.space24,
                left: AppDimensions.space32,
                right: AppDimensions.space32,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                      border: Border.all(color: Colors.white12, width: 1),
                    ),
                    child: Text(
                      'Drag to rotate sanctuary • Pinch to zoom',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall(isDark: true).copyWith(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}