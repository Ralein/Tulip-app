import 'package:hive_flutter/hive_flutter.dart';

part 'journal_entry.g.dart';

@HiveType(typeId: 0)
class JournalEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final String mood; // 'happy', 'calm', 'sad', 'excited', 'reflective'

  @HiveField(4)
  final List<String> tags;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime updatedAt;

  @HiveField(7)
  final String tulipColorHex; // Hex color code of the tulip drawn in the garden

  @HiveField(8)
  final double swayPhaseOffset; // Phase offset for sine wave swaying

  @HiveField(9)
  final double growthProgress; // Sprout to bloom (0.0 to 1.0)

  JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.mood,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.tulipColorHex,
    required this.swayPhaseOffset,
    this.growthProgress = 1.0,
  });

  JournalEntry copyWith({
    String? title,
    String? content,
    String? mood,
    List<String>? tags,
    DateTime? updatedAt,
    String? tulipColorHex,
    double? swayPhaseOffset,
    double? growthProgress,
  }) {
    return JournalEntry(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tulipColorHex: tulipColorHex ?? this.tulipColorHex,
      swayPhaseOffset: swayPhaseOffset ?? this.swayPhaseOffset,
      growthProgress: growthProgress ?? this.growthProgress,
    );
  }
}
