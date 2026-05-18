import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glassmorphic_card.dart';
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
  late double _bloomFactor;

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
    _bloomFactor = widget.entry?.growthProgress ?? initialMoodItem.bloomFactor;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
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
      tulipColorHex: _tulipColor.value.toString(),
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

    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.entry == null ? 'Water Your Thoughts' : 'Tend Your Sprout',
          style: AppTypography.journalTitle(isDark: isDark).copyWith(fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline_rounded, size: 28, color: AppColors.leafGreenLight),
            onPressed: _save,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.nightIndigo, AppColors.bgDark]
                : [AppColors.skyBlueLight, AppColors.bgLight],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.space16),
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
                        _bloomFactor = moodItem.bloomFactor;
                      });
                    },
                  ),
                  const SizedBox(height: AppDimensions.space16),

                  // 3. Title Field
                  GlassmorphicCard(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: AppDimensions.space4),
                    child: TextFormField(
                      controller: _titleController,
                      style: AppTypography.journalSubTitle(isDark: isDark),
                      decoration: InputDecoration(
                        hintText: 'Give your sprout a name...',
                        hintStyle: AppTypography.journalSubTitle(isDark: isDark).copyWith(
                          color: isDark ? AppColors.textSecondaryDark.withOpacity(0.5) : AppColors.textSecondaryLight.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please name your thought' : null,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space16),

                  // 4. Content Field
                  GlassmorphicCard(
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _contentController,
                          maxLines: 12,
                          style: AppTypography.bodyNormal(isDark: isDark),
                          decoration: InputDecoration(
                            hintText: 'Write down what sways your mind...',
                            hintStyle: AppTypography.bodyNormal(isDark: isDark).copyWith(
                              color: isDark ? AppColors.textSecondaryDark.withOpacity(0.5) : AppColors.textSecondaryLight.withOpacity(0.5),
                            ),
                            border: InputBorder.none,
                          ),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Write something to water the tulip' : null,
                        ),
                        const Divider(color: Colors.white24, height: AppDimensions.space16),
                        
                        // Word Count indicator
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _contentController,
                          builder: (context, value, child) {
                            final words = value.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$words words written',
                                  style: AppTypography.bodySmall(isDark: isDark),
                                ),
                                // Sprout growth rating based on word count!
                                Text(
                                  words < 5 ? '🌱 Sprout' : words < 20 ? '🌿 Leaf' : '🌷 Full Bloom',
                                  style: AppTypography.bodySmall(isDark: isDark).copyWith(
                                    color: AppColors.leafGreenLight,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
