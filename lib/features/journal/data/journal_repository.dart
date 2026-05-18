import 'package:hive_flutter/hive_flutter.dart';
import 'models/journal_entry.dart';

class JournalRepository {
  static const String _boxName = 'journal_entries_box';

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(JournalEntryAdapter());
    }
    await Hive.openBox<JournalEntry>(_boxName);
  }

  Box<JournalEntry> get _box => Hive.box<JournalEntry>(_boxName);

  List<JournalEntry> getAllEntries() {
    final entries = _box.values.toList();
    // Sort descending by creation date
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<void> saveEntry(JournalEntry entry) async {
    await _box.put(entry.id, entry);
  }

  Future<void> deleteEntry(String id) async {
    await _box.delete(id);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }

  Stream<List<JournalEntry>> watchEntries() {
    return _box.watch().map((_) => getAllEntries());
  }
}
