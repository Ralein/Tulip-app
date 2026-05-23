import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glassmorphic_card.dart';
import '../data/models/journal_entry.dart';
import 'providers/journal_provider.dart';
import 'widgets/mood_selector.dart';

class JournalListScreen extends ConsumerStatefulWidget {
  const JournalListScreen({super.key});

  @override
  ConsumerState<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends ConsumerState<JournalListScreen> {
  late TextEditingController _searchController;
  String _searchQuery = '';
  String? _selectedMoodFilter;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entriesAsync = ref.watch(journalEntriesProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
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
          child: entriesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.tulipPink),
            ),
            error: (err, stack) => Center(
              child: Text(
                'Failed to load entries: $err',
                style: AppTypography.bodyNormal(isDark: isDark),
              ),
            ),
            data: (rawEntries) {
              // 1. Process entries (Newest first)
              final entries = List<JournalEntry>.from(rawEntries)
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

              // 2. Compute Mood Stats for dashboard
              final stats = _getMoodPercentages(entries);

              // 3. Apply Search and Mood Filter
              final filteredEntries = entries.where((entry) {
                final matchesSearch = _searchQuery.isEmpty ||
                    entry.title.toLowerCase().contains(_searchQuery) ||
                    entry.content.toLowerCase().contains(_searchQuery);
                final matchesMood = _selectedMoodFilter == null || entry.mood == _selectedMoodFilter;
                return matchesSearch && matchesMood;
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Custom AppBar Header Row ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: AppDimensions.space8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          onPressed: () => context.go('/garden'),
                        ),
                        const SizedBox(width: AppDimensions.space8),
                        Text(
                          'Your Garden Log',
                          style: AppTypography.journalTitle(isDark: isDark).copyWith(fontSize: 22),
                        ),
                      ],
                    ),
                  ),

                  // --- 1. Mood Stats Dashboard Panel ---
                  if (entries.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: AppDimensions.space4),
                      child: GlassmorphicCard(
                        padding: const EdgeInsets.all(AppDimensions.space16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Sanctuary Harmony',
                                  style: AppTypography.journalSubTitle(isDark: isDark).copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${entries.length} seeds planted',
                                  style: AppTypography.bodySmall(isDark: isDark).copyWith(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.space12),
                            // Stacked Mood Bar representation
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                              child: SizedBox(
                                height: 10,
                                child: Row(
                                  children: stats.entries.map((stat) {
                                    final moodItem = MoodSelector.moods.firstWhere((m) => m.key == stat.key);
                                    return Expanded(
                                      flex: (stat.value * 100).round(),
                                      child: Container(
                                        color: moodItem.tulipColor,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppDimensions.space12),
                            // Small Mood Chips legend
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: MoodSelector.moods.map((mood) {
                                final pct = stats[mood.key] ?? 0.0;
                                return Column(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: mood.tulipColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${(pct * 100).round()}%',
                                      style: AppTypography.bodySmall(isDark: isDark).copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // --- 2. Search & Filters Bar ---
                  Padding(
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    child: Column(
                      children: [
                        // Search bar
                        GlassmorphicCard(
                          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: 2),
                          borderRadius: AppDimensions.radiusFull,
                          child: TextFormField(
                            controller: _searchController,
                            style: AppTypography.bodyNormal(isDark: isDark),
                            decoration: InputDecoration(
                              hintText: 'Search through sways and names...',
                              hintStyle: AppTypography.bodySmall(isDark: isDark).copyWith(
                                color: isDark ? AppColors.textSecondaryDark.withValues(alpha: 0.4) : AppColors.textSecondaryLight.withValues(alpha: 0.4),
                              ),
                              icon: Icon(Icons.search_rounded, size: 20, color: isDark ? Colors.white54 : Colors.black45),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space12),
                        // Mood Filter row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip(
                                label: 'All sways',
                                isSelected: _selectedMoodFilter == null,
                                color: isDark ? Colors.white24 : Colors.black12,
                                onTap: () => setState(() => _selectedMoodFilter = null),
                              ),
                              ...MoodSelector.moods.map((mood) {
                                return _buildFilterChip(
                                  label: mood.label,
                                  isSelected: _selectedMoodFilter == mood.key,
                                  color: mood.tulipColor,
                                  onTap: () => setState(() => _selectedMoodFilter = mood.key),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- 3. Entries List with Sticky Month Headers ---
                  Expanded(
                    child: filteredEntries.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.energy_savings_leaf_outlined,
                                  size: 64,
                                  color: AppColors.leafGreen,
                                ),
                                const SizedBox(height: AppDimensions.space16),
                                Text(
                                  _searchQuery.isNotEmpty || _selectedMoodFilter != null
                                      ? 'No matching thoughts found.'
                                      : 'Your garden is waiting to grow.',
                                  style: AppTypography.journalSubTitle(isDark: isDark),
                                ),
                                const SizedBox(height: AppDimensions.space8),
                                Text(
                                  _searchQuery.isNotEmpty || _selectedMoodFilter != null
                                      ? 'Try broadening your search or filters.'
                                      : 'Write your first entry to sprout a tulip!',
                                  style: AppTypography.bodySmall(isDark: isDark),
                                ),
                              ],
                            ),
                          )
                        : AnimationLimiter(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.space16,
                                vertical: AppDimensions.space8,
                              ),
                              itemCount: filteredEntries.length,
                              itemBuilder: (context, index) {
                                final entry = filteredEntries[index];
                                final dateStr = DateFormat('MMMM dd, yyyy').format(entry.createdAt);
                                final monthYearStr = DateFormat('MMMM yyyy').format(entry.createdAt);

                                // Check if we should render a monthly header divider
                                final bool showMonthHeader = index == 0 ||
                                    DateFormat('MMMM yyyy').format(filteredEntries[index - 1].createdAt) != monthYearStr;

                                return AnimationConfiguration.staggeredList(
                                  position: index,
                                  duration: const Duration(milliseconds: 400),
                                  child: SlideAnimation(
                                    verticalOffset: 45.0,
                                    child: FadeInAnimation(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          if (showMonthHeader) ...[
                                            Padding(
                                              padding: const EdgeInsets.only(top: AppDimensions.space16, bottom: AppDimensions.space12, left: AppDimensions.space8),
                                              child: Text(
                                                monthYearStr.toUpperCase(),
                                                style: AppTypography.buttonText(isDark: isDark).copyWith(
                                                  fontSize: 12,
                                                  letterSpacing: 1.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                                ),
                                              ),
                                            ),
                                          ],
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: AppDimensions.space12),
                                            child: InkWell(
                                              onTap: () => context.go('/editor', extra: entry),
                                              borderRadius: BorderRadius.circular(AppDimensions.radius24),
                                              child: GlassmorphicCard(
                                                padding: const EdgeInsets.all(AppDimensions.space16),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: Color(int.parse(entry.tulipColorHex)).withValues(alpha: 0.15),
                                                            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                                                            border: Border.all(
                                                              color: Color(int.parse(entry.tulipColorHex)).withValues(alpha: 0.25),
                                                              width: 1,
                                                            ),
                                                          ),
                                                          child: Text(
                                                            dateStr,
                                                            style: AppTypography.bodySmall(isDark: isDark).copyWith(
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 11,
                                                              color: Color(int.parse(entry.tulipColorHex)),
                                                            ),
                                                          ),
                                                        ),
                                                        // Action Buttons Row (Edit & Delete)
                                                        Row(
                                                          children: [
                                                            IconButton(
                                                              icon: const Icon(
                                                                Icons.edit_note_rounded,
                                                                size: 22,
                                                                color: Colors.white60,
                                                              ),
                                                              onPressed: () => context.go('/editor', extra: entry),
                                                            ),
                                                            IconButton(
                                                              icon: const Icon(
                                                                Icons.delete_outline_rounded,
                                                                size: 20,
                                                                color: AppColors.tulipRedLight,
                                                              ),
                                                              onPressed: () => _confirmDissolution(context, ref, entry),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: AppDimensions.space8),
                                                    Text(
                                                      entry.title,
                                                      style: AppTypography.journalSubTitle(isDark: isDark).copyWith(
                                                        fontSize: 18,
                                                      ),
                                                    ),
                                                    const SizedBox(height: AppDimensions.space8),
                                                    Text(
                                                      entry.content,
                                                      maxLines: 3,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: AppTypography.bodyNormal(isDark: isDark).copyWith(
                                                        fontSize: 14,
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            border: Border.all(
              color: isSelected ? Colors.transparent : (isDark ? Colors.white12 : Colors.black12),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.bodySmall(isDark: isDark).copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, double> _getMoodPercentages(List<JournalEntry> entries) {
    final Map<String, double> percentages = {};
    if (entries.isEmpty) return percentages;

    // Seed all moods to 0 to preserve ordering
    for (var m in MoodSelector.moods) {
      percentages[m.key] = 0.0;
    }

    for (var entry in entries) {
      percentages[entry.mood] = (percentages[entry.mood] ?? 0.0) + 1.0;
    }

    percentages.updateAll((key, val) => val / entries.length);
    return percentages;
  }

  void _confirmDissolution(BuildContext context, WidgetRef ref, JournalEntry entry) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dissolve Entry'),
        content: const Text('Are you sure you want to gently dissolve this thought from your memory garden?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Keep Seed', style: TextStyle(color: AppColors.leafGreen)),
          ),
          TextButton(
            onPressed: () {
              ref.read(journalEntriesProvider.notifier).removeEntry(entry.id);
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Entry gently dissolved.'),
                  backgroundColor: AppColors.tulipPink,
                ),
              );
            },
            child: const Text('Dissolve', style: TextStyle(color: AppColors.tulipRedLight)),
          ),
        ],
      ),
    );
  }
}
