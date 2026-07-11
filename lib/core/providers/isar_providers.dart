import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import 'package:akpa/features/study_session/domain/subject.dart';
import 'package:akpa/features/study_session/domain/topic.dart';
import 'package:akpa/features/study_session/domain/activity_log.dart';
import 'database_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SUMMARY MODELS (lightweight, not Isar objects)
// ─────────────────────────────────────────────────────────────────────────────

/// A lightweight summary of a subject for display in the Syllabus screen.
class SubjectSummary {
  final int id;
  final String name;
  final String slug;
  final int totalTopics;
  final int completedTopics;

  const SubjectSummary({
    required this.id,
    required this.name,
    required this.slug,
    required this.totalTopics,
    required this.completedTopics,
  });
}

/// A lightweight summary of a topic for display in topic lists.
class TopicSummary {
  final int id;
  final int subjectId;
  final String name;
  final bool isCompleted;

  const TopicSummary({
    required this.id,
    required this.subjectId,
    required this.name,
    required this.isCompleted,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

/// Returns all subjects as lightweight [SubjectSummary] objects.
final isarSubjectsProvider = FutureProvider<List<SubjectSummary>>((ref) async {
  final isar = ref.watch(isarProvider);
  try {
    final subjects = await isar.subjects.where().findAll();
    final summaries = <SubjectSummary>[];
    for (final s in subjects) {
      final totalTopics = await isar.topics.where().subjectIdEqualTo(s.id).count();
      final completedTopics = await isar.topics.where().subjectIdEqualTo(s.id).filter().isCompletedEqualTo(true).count();
      summaries.add(SubjectSummary(
        id: s.id,
        name: s.name,
        slug: s.slug,
        totalTopics: totalTopics,
        completedTopics: completedTopics,
      ));
    }
    return summaries;
  } catch (e, st) {
    dev.log('isarSubjectsProvider error: $e', name: 'IsarProviders', error: e, stackTrace: st);
    rethrow;
  }
});

/// Returns topics for a given [subjectId] as [TopicSummary] objects.
final isarTopicsProvider =
    FutureProvider.family<List<TopicSummary>, int>((ref, subjectId) async {
  final isar = ref.watch(isarProvider);
  try {
    final topics = await isar.topics
        .filter()
        .subjectIdEqualTo(subjectId)
        .findAll();
    return topics
        .map((t) => TopicSummary(
              id: t.id,
              subjectId: t.subjectId,
              name: t.name,
              isCompleted: t.isCompleted,
            ))
        .toList();
  } catch (e, st) {
    dev.log('isarTopicsProvider($subjectId) error: $e',
        name: 'IsarProviders', error: e, stackTrace: st);
    rethrow;
  }
});
