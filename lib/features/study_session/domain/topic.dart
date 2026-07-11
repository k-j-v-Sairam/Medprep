import 'package:isar_community/isar.dart';

part 'topic.g.dart';

/// Topic Collection
/// Optimized for: Rapidly querying all topics under a specific subject.
/// Query pattern: `isar.topics.where().subjectIdEqualTo(id).findAll()`
/// Flat reference architecture avoids nesting `Flashcard` objects directly
/// to ensure we don't accidentally load thousands of cards when building the topic list.
@collection
class Topic {
  Id id = Isar.autoIncrement;

  /// Indexed because every query for topics filters by subject.
  /// Without this index, Isar would have to perform a full collection scan
  /// over all topics across all subjects, which degrades performance as the DB grows.
  @Index()
  late int subjectId;

  late String name;
  String? description;
  
  bool isCompleted = false;

  @Index(type: IndexType.value)
  int boxNumber = 0;

  @Index(type: IndexType.value)
  DateTime? nextReviewDate;

  String? readNotes;
  String? unreadNotes;
  String? importantNotes;
}
