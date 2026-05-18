import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulip/app.dart';
import 'package:tulip/features/journal/data/journal_repository.dart';
import 'package:tulip/features/journal/data/models/journal_entry.dart';
import 'package:tulip/features/journal/presentation/providers/journal_provider.dart';

class MockJournalRepository implements JournalRepository {
  final List<JournalEntry> _entries = [];
  final _controller = StreamController<List<JournalEntry>>.broadcast();

  @override
  Future<void> init() async {}

  @override
  List<JournalEntry> getAllEntries() => _entries;

  @override
  Future<void> saveEntry(JournalEntry entry) async {
    _entries.add(entry);
    _controller.add(_entries);
  }

  @override
  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    _controller.add(_entries);
  }

  @override
  Future<void> clearAll() async {
    _entries.clear();
    _controller.add(_entries);
  }

  @override
  Stream<List<JournalEntry>> watchEntries() => _controller.stream;
}

void main() {
  testWidgets('App simple compile smoke test', (WidgetTester tester) async {
    // Build our app with overridden repository to avoid Hive initialization errors in tests
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(MockJournalRepository()),
        ],
        child: const App(),
      ),
    );

    // Verify that the App widget compiles and mounts
    expect(find.byType(App), findsOneWidget);
  });
}
