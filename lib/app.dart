import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/garden/presentation/garden_screen.dart';
import 'features/journal/presentation/journal_editor_screen.dart';
import 'features/journal/presentation/journal_list_screen.dart';
import 'features/journal/data/models/journal_entry.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/garden',
          builder: (context, state) => const GardenScreen(),
        ),
        GoRoute(
          path: '/entries',
          builder: (context, state) => const JournalListScreen(),
        ),
        GoRoute(
          path: '/editor',
          builder: (context, state) {
            final entry = state.extra as JournalEntry?;
            return JournalEditorScreen(entry: entry);
          },
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Tulip Journal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
