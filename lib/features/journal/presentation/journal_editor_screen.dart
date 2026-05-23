import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glassmorphic_card.dart';
import '../../../core/widgets/breathing_widget.dart';
import '../data/models/journal_entry.dart';
import 'providers/journal_provider.dart';
import 'widgets/mood_selector.dart';

class JournalEditorScreen extends ConsumerStatefulWidget {
  final JournalEntry? entry;

  const JournalEditorScreen({
    super.key,
    this.entry,
  });

  @override
  ConsumerState<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends ConsumerState<JournalEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _selectedMood;
  late Color _tulipColor;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry?.title ?? '');
    _contentController = TextEditingController(text: widget.entry?.content ?? '');
    _selectedMood = widget.entry?.mood ?? 'happy';
    
    // Choose default tulip color based on mood
    final initialMoodItem = MoodSelector.moods.firstWhere(
      (m) => m.key == _selectedMood,
      orElse: () => MoodSelector.moods.first,
    );
    _tulipColor = widget.entry != null
        ? Color(int.parse(widget.entry!.tulipColorHex))
        : initialMoodItem.tulipColor;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  List<Color> _getMoodColors(String mood, bool isDark) {
    if (isDark) {
      switch (mood) {
        case 'happy':
          return [const Color(0xFF3E2723), AppColors.bgDark]; // Warm chocolate amber
        case 'calm':
          return [const Color(0xFF0D47A1).withValues(alpha: 0.25), AppColors.bgDark]; // Deep ocean navy
        case 'reflective':
          return [const Color(0xFF4A148C).withValues(alpha: 0.25), AppColors.bgDark]; // Dusk orchid purple
        case 'excited':
          return [const Color(0xFFF57F17).withValues(alpha: 0.2), AppColors.bgDark]; // Glowing sunrise bronze
        case 'sad':
          return [const Color(0xFF37474F).withValues(alpha: 0.35), AppColors.bgDark]; // Overcast charcoal
        default:
          return [AppColors.nightIndigo, AppColors.bgDark];
      }
    } else {
      switch (mood) {
        case 'happy':
          return [const Color(0xFFFFF0F5), AppColors.bgLight]; // Pastel rose blush
        case 'calm':
          return [const Color(0xFFE3F2FD), AppColors.bgLight]; // Pale sky blue
        case 'reflective':
          return [const Color(0xFFF3E5F5), AppColors.bgLight]; // Lavender cream
        case 'excited':
          return [const Color(0xFFFFF9C4), AppColors.bgLight]; // Soft sunshine cream
        case 'sad':
          return [const Color(0xFFECEFF1), AppColors.bgLight]; // Mist grey
        default:
          return [AppColors.skyBlueLight, AppColors.bgLight];
      }
    }
  }

  String _getMoodPrompt(String mood) {
    switch (mood) {
      case 'happy':
        return '🌸 What brought a radiant smile to your face today? Share the light.';
      case 'calm':
        return '🍃 Describe a quiet, peaceful moment. What sways in your thoughts?';
      case 'reflective':
        return '✨ What did today teach you? Let\'s gently look inward.';
      case 'excited':
        return '🔥 What is sparking your creative fire right now? Capture the rush!';
      case 'sad':
        return '🌧️ It is okay to feel overcast. Write to comfort your inner sanctuary.';
      default:
        return 'Write down what sways your mind...';
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final String id = widget.entry?.id ?? Uuid().v4();
    final now = DateTime.now();

    final entry = JournalEntry(
      id: id,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      mood: _selectedMood,
      tags: widget.entry?.tags ?? ['journal'],
      createdAt: widget.entry?.createdAt ?? now,
      updatedAt: now,
      tulipColorHex: _tulipColor.toARGB32().toString(),
      swayPhaseOffset: widget.entry?.swayPhaseOffset ?? (math.Random().nextDouble() * math.pi * 2),
      growthProgress: 1.0, // Mark as fully grown when written!
    );

    ref.read(journalEntriesProvider.notifier).addOrUpdateEntry(entry);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your garden has bloomed with a new tulip!'),
        backgroundColor: AppColors.leafGreen,
      ),
    );

    context.go('/garden');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final moodColors = _getMoodColors(_selectedMood, isDark);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.entry == null ? 'Water Your Thoughts' : 'Tend Your Sprout',
          style: AppTypography.journalTitle(isDark: isDark).copyWith(fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/garden'),
        ),
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: moodColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Scrollable Input Form Fields
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: AppDimensions.space8),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Mood Selector Label
                        Text(
                          'How is your inner garden today?',
                          textAlign: TextAlign.center,
                          style: AppTypography.handWritten(isDark: isDark, fontSize: 24),
                        ),
                        const SizedBox(height: AppDimensions.space8),

                        // 2. Beautiful Mood Selector Row
                        MoodSelector(
                          selectedMood: _selectedMood,
                          onMoodSelected: (moodItem) {
                            setState(() {
                              _selectedMood = moodItem.key;
                              _tulipColor = moodItem.tulipColor;
                            });
                          },
                        ),
                        const SizedBox(height: AppDimensions.space16),

                        // 3. Ambient Dynamic Prompt
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: Container(
                            key: ValueKey<String>(_selectedMood),
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: AppDimensions.space12),
                            child: Text(
                              _getMoodPrompt(_selectedMood),
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall(isDark: isDark).copyWith(
                                fontStyle: FontStyle.italic,
                                color: isDark ? _tulipColor.withValues(alpha: 0.9) : AppColors.textSecondaryLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space12),

                        // 4. Title Field
                        GlassmorphicCard(
                          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: AppDimensions.space4),
                          child: TextFormField(
                            controller: _titleController,
                            style: AppTypography.journalSubTitle(isDark: isDark),
                            decoration: InputDecoration(
                              hintText: 'Give your thought a name...',
                              hintStyle: AppTypography.journalSubTitle(isDark: isDark).copyWith(
                                color: isDark ? AppColors.textSecondaryDark.withValues(alpha: 0.4) : AppColors.textSecondaryLight.withValues(alpha: 0.4),
                              ),
                              border: InputBorder.none,
                            ),
                            validator: (value) => value == null || value.trim().isEmpty ? 'Please name your thought' : null,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space16),

                        // 5. Content Field
                        GlassmorphicCard(
                          padding: const EdgeInsets.all(AppDimensions.space16),
                          child: TextFormField(
                            controller: _contentController,
                            maxLines: 10,
                            style: AppTypography.bodyNormal(isDark: isDark),
                            decoration: InputDecoration(
                              hintText: 'Write down what sways your mind...',
                              hintStyle: AppTypography.bodyNormal(isDark: isDark).copyWith(
                                color: isDark ? AppColors.textSecondaryDark.withValues(alpha: 0.4) : AppColors.textSecondaryLight.withValues(alpha: 0.4),
                              ),
                              border: InputBorder.none,
                            ),
                            validator: (value) => value == null || value.trim().isEmpty ? 'Write something to water the tulip' : null,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space16),
                      ],
                    ),
                  ),
                ),
              ),

              // 6. Interactive Floating Glassmorphic bottom save bar
              Padding(
                padding: const EdgeInsets.all(AppDimensions.space16),
                child: GlassmorphicCard(
                  padding: const EdgeInsets.all(AppDimensions.space12),
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _contentController,
                    builder: (context, value, child) {
                      final words = value.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
                      final growthLabel = words < 5 ? '🌱 Sprout' : words < 20 ? '🌿 Growing Leaf' : '🌷 Full Bloom';
                      final progressFraction = math.min(1.0, words / 20.0);

                      return Row(
                        children: [
                          // Interactive Stats
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$words words',
                                      style: AppTypography.bodySmall(isDark: isDark).copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      growthLabel,
                                      style: AppTypography.bodySmall(isDark: isDark).copyWith(
                                        color: isDark ? _tulipColor : AppColors.tulipPinkDark,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Micro progress bar representing growth!
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: progressFraction,
                                    minHeight: 4,
                                    backgroundColor: isDark ? Colors.white10 : Colors.black12,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isDark ? _tulipColor : AppColors.leafGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space16),

                          // Breathing glowing button for tactile saving satisfaction
                          BreathingWidget(
                            minScale: 0.96,
                            maxScale: 1.04,
                            duration: const Duration(seconds: 2),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                                boxShadow: [
                                  BoxShadow(
                                    color: _tulipColor.withValues(alpha: 0.45),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _tulipColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: AppDimensions.space12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.local_florist_rounded, size: 16, color: Colors.white),
                                    const SizedBox(width: 6),
                                    Text(
                                      widget.entry == null ? 'Water' : 'Prune',
                                      style: AppTypography.buttonText(isDark: true).copyWith(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
