import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/journal_repository.dart';
import '../../data/models/journal_entry.dart';

// 1. Repository Provider
final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepository();
});

// 2. Entries StateNotifier Provider
final journalEntriesProvider = StateNotifierProvider<JournalEntriesNotifier, AsyncValue<List<JournalEntry>>>((ref) {
  final repository = ref.watch(journalRepositoryProvider);
  return JournalEntriesNotifier(repository);
});

class JournalEntriesNotifier extends StateNotifier<AsyncValue<List<JournalEntry>>> {
  final JournalRepository _repository;
  StreamSubscription<List<JournalEntry>>? _subscription;

  JournalEntriesNotifier(this._repository) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      await _repository.init();
      final initialEntries = _repository.getAllEntries();
      state = AsyncValue.data(initialEntries);

      // Start watching reactive stream of entries
      _subscription = _repository.watchEntries().listen(
        (entries) {
          state = AsyncValue.data(entries);
        },
        onError: (err, stack) {
          state = AsyncValue.error(err, stack);
        },
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addOrUpdateEntry(JournalEntry entry) async {
    try {
      await _repository.saveEntry(entry);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> removeEntry(String id) async {
    try {
      await _repository.deleteEntry(id);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> clearAll() async {
    try {
      await _repository.clearAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
