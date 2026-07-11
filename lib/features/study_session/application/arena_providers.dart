import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/syllabus_state_provider.dart';

enum TopicSortMode { alphabetical, reverseAlphabetical, dueSoonest, dueLatest }

// State Providers for Arena UI Controls
final arenaSearchQueryProvider = StateProvider<String>((ref) => '');
final arenaSelectedSubjectsProvider = StateProvider<Set<int>>((ref) => {});
final arenaSortModeProvider = StateProvider<TopicSortMode>((ref) => TopicSortMode.dueSoonest);

/// Returns a pre-filtered and sorted list of topics for a specific box.
final filteredArenaTopicsProvider = Provider.family<List<TopicWithSubjectViewModel>, int>((ref, boxNumber) {
  final topicsByBox = ref.watch(topicsByBoxProvider).value ?? {};
  var topics = topicsByBox[boxNumber] ?? [];

  final selectedSubjectIds = ref.watch(arenaSelectedSubjectsProvider);
  if (selectedSubjectIds.isNotEmpty) {
    topics = topics.where((t) => selectedSubjectIds.contains(t.subject.id)).toList();
  }

  final searchQuery = ref.watch(arenaSearchQueryProvider).trim().toLowerCase();
  if (searchQuery.isNotEmpty) {
    topics = topics.where((t) =>
        t.topic.name.toLowerCase().contains(searchQuery) ||
        t.subject.name.toLowerCase().contains(searchQuery)).toList();
  }

  final sortMode = ref.watch(arenaSortModeProvider);
  
  // Create a new list before sorting to avoid mutating the original cached list
  final sortedTopics = List<TopicWithSubjectViewModel>.from(topics);
  sortedTopics.sort((a, b) {
    switch (sortMode) {
      case TopicSortMode.alphabetical:
        return a.topic.name.compareTo(b.topic.name);
      case TopicSortMode.reverseAlphabetical:
        return b.topic.name.compareTo(a.topic.name);
      case TopicSortMode.dueSoonest:
        final aDate = a.topic.nextReviewDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.topic.nextReviewDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aDate.compareTo(bDate);
      case TopicSortMode.dueLatest:
        final aDate = a.topic.nextReviewDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.topic.nextReviewDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
    }
  });

  return sortedTopics;
});
