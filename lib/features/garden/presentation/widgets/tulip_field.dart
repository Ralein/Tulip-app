import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/tulip_painter.dart';
import '../../../journal/data/models/journal_entry.dart';

class TulipField extends StatefulWidget {
  final List<JournalEntry> entries;

  const TulipField({
    super.key,
    required this.entries,
  });

  @override
  State<TulipField> createState() => _TulipFieldState();
}

class _TulipFieldState extends State<TulipField>
    with SingleTickerProviderStateMixin {
  late AnimationController _swayController;
  final Map<String, Offset> _positions = {};

  @override
  void initState() {
    super.initState();
    _swayController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _swayController.dispose();
    super.dispose();
  }

  // Generates consistent coordinates based on the entry ID
  Offset _getPosition(String id, Size size) {
    if (_positions.containsKey(id)) {
      return _positions[id]!;
    }

    final random = math.Random(id.hashCode);
    
    // Distribute tulips horizontally, and place them in vertical perspective rows
    // (Bigger Y coordinates represent closer foreground rows)
    final double x = 30.0 + random.nextDouble() * (size.width - 60.0);
    final double y = size.height * 0.35 + random.nextDouble() * (size.height * 0.55);
    
    final pos = Offset(x, y);
    _positions[id] = pos;
    return pos;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) {
      // Draw a default beautiful glowing guide tulip sprout when garden is empty!
      return LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          
          return AnimatedBuilder(
            animation: _swayController,
            builder: (context, child) {
              final sway = math.sin(_swayController.value * math.pi * 2) * 0.05;
              
              return CustomPaint(
                size: size,
                painter: TulipPainter(
                  tulipColor: AppColors.tulipPinkLight,
                  swayAngle: sway,
                  growthProgress: 0.8,
                  bloomFactor: 0.4,
                ),
              );
            },
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        
        // Sort entries so that higher Y-value (closer foreground) is painted last!
        // This is crucial for proper 3D rendering occlusion!
        final sortedEntries = List<JournalEntry>.from(widget.entries);
        sortedEntries.sort((a, b) {
          final posA = _getPosition(a.id, size);
          final posB = _getPosition(b.id, size);
          return posA.dy.compareTo(posB.dy);
        });

        return AnimatedBuilder(
          animation: _swayController,
          builder: (context, child) {
            return Stack(
              children: sortedEntries.map((entry) {
                final pos = _getPosition(entry.id, size);
                
                // Sway phase varies by entry for random wind offset
                final swayPhase = entry.swayPhaseOffset;
                final sway = math.sin((_swayController.value * math.pi * 2) + swayPhase) * 0.06;

                // Bloom factor based on contents length! Larger entry = bigger bloom
                final int words = entry.content.split(RegExp(r'\s+')).length;
                final double bloom = math.min(1.0, 0.3 + (words / 40));

                // Scale tulip based on depth perspective
                final double scale = 0.5 + (pos.dy / size.height) * 0.7;

                return Positioned(
                  left: pos.dx - (40 * scale) / 2,
                  top: pos.dy - (60 * scale),
                  width: 40 * scale,
                  height: 60 * scale,
                  child: CustomPaint(
                    painter: TulipPainter(
                      tulipColor: Color(int.parse(entry.tulipColorHex)),
                      swayAngle: sway,
                      growthProgress: entry.growthProgress,
                      bloomFactor: bloom,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}
