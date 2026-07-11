import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/providers/isar_providers.dart';
import '../../../core/providers/syllabus_state_provider.dart';
import '../../study_session/domain/topic.dart';
import '../../study_session/domain/subject.dart' as isar_model;

class LibraryItemViewModel {
  final TopicViewModel topic;
  final SubjectViewModel subject;

  LibraryItemViewModel({
    required this.topic,
    required this.subject,
  });
}

// Keep this for backwards compatibility if needed elsewhere, though we'll use the new one primarily.
class ReviewItem {
  final Topic topic;
  final String subjectName;
  final bool isOverdue;

  ReviewItem({
    required this.topic,
    required this.subjectName,
    required this.isOverdue,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// STATE PROVIDERS FOR FILTERS
// ─────────────────────────────────────────────────────────────────────────────

final librarySearchQueryProvider = StateProvider<String>((ref) => '');
final librarySelectedSubjectProvider = StateProvider<int?>((ref) => null);
final librarySelectedBoxProvider = StateProvider<int?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// MAIN LIBRARY PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

final libraryTopicsProvider = FutureProvider.autoDispose<List<LibraryItemViewModel>>((ref) async {
  final isar = ref.watch(isarProvider);
  final searchQuery = ref.watch(librarySearchQueryProvider).toLowerCase().trim();
  final selectedSubjectId = ref.watch(librarySelectedSubjectProvider);
  final selectedBoxNumber = ref.watch(librarySelectedBoxProvider);

  // Fetch all subjects and convert to SubjectViewModel for easy access
  final isarSubjects = await isar.subjects.where().findAll();
  final Map<int, SubjectViewModel> subjectMap = {};
  
  // We can fetch from SyllabusState if we want full stats, but basic mapping is fine here
  final syllabusAsync = ref.watch(syllabusProvider);
  
  if (syllabusAsync.hasValue && syllabusAsync.value != null) {
    for (final s in syllabusAsync.value!.subjects) {
      subjectMap[s.id] = s;
    }
  }

  // Fetch all topics
  List<Topic> allTopics;
  
  // Apply box filter at DB level if possible
  if (selectedBoxNumber != null) {
    allTopics = await isar.topics.where().boxNumberEqualTo(selectedBoxNumber).findAll();
  } else {
    // If no box selected, sort by box descending to show highest boxes first or something
    // Or just fetch all.
    allTopics = await isar.topics.where().findAll();
  }
  
  final results = <LibraryItemViewModel>[];
  
  for (final topic in allTopics) {
    // Apply subject filter
    if (selectedSubjectId != null && topic.subjectId != selectedSubjectId) {
      continue;
    }
    
    // Apply search filter
    if (searchQuery.isNotEmpty) {
      if (!topic.name.toLowerCase().contains(searchQuery) && 
          !(topic.description?.toLowerCase().contains(searchQuery) ?? false)) {
        continue;
      }
    }
    
    final subject = subjectMap[topic.subjectId];
    if (subject == null) continue; // Skip if subject doesn't exist
    
    // Map to ViewModel
    final tvm = TopicViewModel(
      id: topic.id,
      subjectId: topic.subjectId,
      name: topic.name,
      description: topic.description ?? '',
      isCompleted: topic.isCompleted,
      masteryPercent: (topic.boxNumber / 5).clamp(0.0, 1.0),
      boxNumber: topic.boxNumber,
      nextReviewDate: topic.nextReviewDate,
      readNotes: topic.readNotes,
      unreadNotes: topic.unreadNotes,
      importantNotes: topic.importantNotes,
    );
    
    results.add(LibraryItemViewModel(topic: tvm, subject: subject));
  }
  
  // Sort results: Completed first, then by box number descending, then by name
  results.sort((a, b) {
    if (a.topic.boxNumber != b.topic.boxNumber) {
      return b.topic.boxNumber.compareTo(a.topic.boxNumber);
    }
    return a.topic.name.compareTo(b.topic.name);
  });

  return results;
});

// Original Review Provider
final libraryReviewProvider = FutureProvider.autoDispose<List<ReviewItem>>((ref) async {
  final isar = ref.watch(isarProvider);
  final now = DateTime.now();
  final topicsToReview = await isar.topics
      .where()
      .nextReviewDateIsNotNull()
      .filter()
      .isCompletedEqualTo(true)
      .sortByNextReviewDate()
      .findAll();

  final results = <ReviewItem>[];
  for (final topic in topicsToReview) {
    final daysUntilDue = topic.nextReviewDate!.difference(now).inDays;
    if (daysUntilDue <= 7) {
      final subject = await isar.subjects.get(topic.subjectId);
      final isOverdue = topic.nextReviewDate!.isBefore(now);
      results.add(ReviewItem(
        topic: topic,
        subjectName: subject?.name ?? 'Unknown Subject',
        isOverdue: isOverdue,
      ));
    }
  }

  results.sort((a, b) {
    if (a.isOverdue && !b.isOverdue) return -1;
    if (!a.isOverdue && b.isOverdue) return 1;
    return a.topic.nextReviewDate!.compareTo(b.topic.nextReviewDate!);
  });

  return results;
});
