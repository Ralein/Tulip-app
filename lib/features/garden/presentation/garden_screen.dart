import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

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
import 'widgets/weather_controller.dart';

class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  // Callback when a hotspot is clicked on the 3D model
  void _handleHotspotClick(String slotId) {
    if (!mounted) return;
    switch (slotId) {
      case 'hotspot-1':
        // 1. Write Journal
        context.go('/editor');
        break;
      case 'hotspot-2':
        // 2. Garden Logs
        context.go('/entries');
        break;
      case 'hotspot-3':
        // 3. Shift Weather Ambient drawer
        _showAtmosphereDrawer();
        break;
      case 'hotspot-4':
        // 4. Breathing mindfulness session
        _showBreathingModal();
        break;
    }
  }

  void _showAtmosphereDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return const Padding(
          padding: EdgeInsets.only(
            left: AppDimensions.space16,
            right: AppDimensions.space16,
            bottom: AppDimensions.space24,
          ),
          child: WeatherController(),
        );
      },
    );
  }

  void _showBreathingModal() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) {
        return const BreathingDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final entriesAsync = ref.watch(journalEntriesProvider);
        final gardenState = ref.watch(gardenStateProvider);
        final size = MediaQuery.of(context).size;

        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Time-of-day and Weather Shifting Gradient Background
              AnimatedGradientBg(
                timeOfDay: gardenState.time,
                weather: gardenState.weather,
              ),

              // 2. Falling Petals / Atmospheric weather particles
              Positioned.fill(
                child: ParticleSystemWidget(
                  weather: gardenState.weather,
                ),
              ),

              // 3. Central 3D Model Viewer of stylized_mangrove_greenhouse.glb
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
                    exposure: 1.25,
                    minCameraOrbit: 'auto auto auto',
                    maxCameraOrbit: 'auto auto auto',
                    // Listeners from Javascript inside WebView
                    javascriptChannels: {
                      JavascriptChannel(
                        'HotspotChannel',
                        onMessageReceived: (message) {
                          _handleHotspotClick(message.message);
                        },
                      ),
                    },
                    // Interactive Hotspots placed directly inside HTML WebComponent
                    innerModelViewerHtml: '''
                      <style>
                        .hotspot-btn {
                          position: relative;
                          background: rgba(233, 30, 99, 0.85);
                          color: white;
                          border: 2px solid rgba(255, 255, 255, 0.85);
                          border-radius: 50%;
                          width: 38px;
                          height: 38px;
                          font-family: sans-serif;
                          font-weight: 800;
                          font-size: 15px;
                          cursor: pointer;
                          box-shadow: 0 0 15px rgba(233,30,99,0.7), inset 0 0 8px rgba(255,255,255,0.3);
                          display: flex;
                          align-items: center;
                          justify-content: center;
                          padding: 0;
                          transition: transform 0.2s, background 0.3s;
                        }
                        .hotspot-btn::after {
                          content: '';
                          position: absolute;
                          top: -6px;
                          left: -6px;
                          right: -6px;
                          bottom: -6px;
                          border: 2px solid #E91E63;
                          border-radius: 50%;
                          animation: ripple 1.6s infinite ease-out;
                          opacity: 0;
                          pointer-events: none;
                        }
                        @keyframes ripple {
                          0% {
                            transform: scale(0.8);
                            opacity: 0.8;
                            box-shadow: 0 0 0 0 rgba(233,30,99,0.5);
                          }
                          100% {
                            transform: scale(1.3);
                            opacity: 0;
                            box-shadow: 0 0 0 12px rgba(233,30,99,0);
                          }
                        }
                        .hotspot-btn:hover {
                          transform: scale(1.1);
                          background: rgba(233, 30, 99, 1);
                        }
                        .hotspot-btn:active {
                          transform: scale(1.2);
                        }
                        .hotspot-label {
                          position: absolute;
                          left: 48px;
                          background: rgba(15, 15, 25, 0.88);
                          color: #FFF59D;
                          padding: 6px 14px;
                          border-radius: 12px;
                          font-size: 13px;
                          font-weight: bold;
                          letter-spacing: 0.5px;
                          white-space: nowrap;
                          pointer-events: none;
                          border: 1px solid rgba(255, 255, 255, 0.18);
                          box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.4);
                        }
                      </style>

                      <button slot="hotspot-1" data-position="0.0 1.5 0.5" class="hotspot-btn" onclick="HotspotChannel.postMessage('hotspot-1')">
                        1
                        <span class="hotspot-label">1. Write Sprout</span>
                      </button>

                      <button slot="hotspot-2" data-position="-0.9 0.8 -0.4" class="hotspot-btn" onclick="HotspotChannel.postMessage('hotspot-2')">
                        2
                        <span class="hotspot-label">2. Garden Logs</span>
                      </button>

                      <button slot="hotspot-3" data-position="0.8 0.4 0.6" class="hotspot-btn" onclick="HotspotChannel.postMessage('hotspot-3')">
                        3
                        <span class="hotspot-label">3. Shift Weather</span>
                      </button>

                      <button slot="hotspot-4" data-position="0.0 0.9 -0.6" class="hotspot-btn" onclick="HotspotChannel.postMessage('hotspot-4')">
                        4
                        <span class="hotspot-label">4. Breathing Space</span>
                      </button>
                    ''',
                  ),
                ),
              ),

              // 4. Glowing HUD Header Floating Over Model
              Positioned(
                top: MediaQuery.of(context).padding.top + AppDimensions.space8,
                left: AppDimensions.space16,
                right: AppDimensions.space16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Glowing Streak Counter
                    entriesAsync.maybeWhen(
                      data: (entries) {
                        final int streak = entries.isNotEmpty ? 1 : 0;
                        return StreakCounter(streakDays: streak);
                      },
                      orElse: () => const StreakCounter(streakDays: 0),
                    ),

                    // Quick Action Helper Hint Indicator
                    GlassmorphicCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.explore_outlined,
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

                    // View Logs Menu Button
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
              ),

              // 5. Ambient visual instructions overlay at the bottom
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
                      border: Border.all(
                        color: Colors.white12,
                        width: 1,
                      ),
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
