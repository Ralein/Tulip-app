import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glassmorphic_card.dart';
import 'providers/journal_provider.dart';

class JournalListScreen extends ConsumerWidget {
  const JournalListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entriesAsync = ref.watch(journalEntriesProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Your Garden Log',
          style: AppTypography.journalTitle(isDark: isDark).copyWith(fontSize: 22),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/garden'),
        ),
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
            data: (entries) {
              if (entries.isEmpty) {
                return Center(
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
                        'Your garden is waiting to grow.',
                        style: AppTypography.journalSubTitle(isDark: isDark),
                      ),
                      const SizedBox(height: AppDimensions.space8),
                      Text(
                        'Write your first entry to sprout a tulip!',
                        style: AppTypography.bodySmall(isDark: isDark),
                      ),
                    ],
                  ),
                );
              }

              return AnimationLimiter(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space16,
                    vertical: AppDimensions.space8,
                  ),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final dateStr = DateFormat('MMMM dd, yyyy').format(entry.createdAt);

                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: Padding(
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
                                        Text(
                                          dateStr,
                                          style: AppTypography.bodySmall(isDark: isDark).copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Color(int.parse(entry.tulipColorHex)),
                                          ),
                                        ),
                                        // Delete Button
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 20,
                                            color: AppColors.tulipRedLight,
                                          ),
                                          onPressed: () {
                                            ref.read(journalEntriesProvider.notifier).removeEntry(entry.id);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Entry gently dissolved.'),
                                                backgroundColor: AppColors.tulipPink,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppDimensions.space4),
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
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
