import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../features/study_session/domain/subject.dart' as isar_model;
import '../../features/study_session/domain/topic.dart';
import '../../features/study_session/domain/activity_log.dart';
import 'database_provider.dart' show isarProvider;
import 'auth_provider.dart';
import 'sync_provider.dart';
// ─────────────────────────────────────────────────────────────────────────────
// UI MODELS
// ─────────────────────────────────────────────────────────────────────────────

class SubjectViewModel {
  final int id;
  final String name;
  final String slug;
  final IconData iconData;
  final Color accentColor;
  final int totalTopics;
  final int totalDue;
  final double masteryPercent;
  final List<int> boxCounts;

  SubjectViewModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.iconData,
    required this.accentColor,
    required this.totalTopics,
    required this.totalDue,
    required this.masteryPercent,
    this.boxCounts = const [0, 0, 0, 0, 0, 0],
  });
}

class TopicViewModel {
  final int id;
  final int subjectId;
  final String name;
  final String description;
  final bool isCompleted;
  final double masteryPercent;
  final int boxNumber;
  final DateTime nextReviewDate;
  final String? readNotes;
  final String? unreadNotes;
  final String? importantNotes;

  TopicViewModel({
    required this.id,
    required this.subjectId,
    required this.name,
    required this.description,
    required this.isCompleted,
    required this.masteryPercent,
    this.boxNumber = 0,
    DateTime? nextReviewDate,
    this.readNotes,
    this.unreadNotes,
    this.importantNotes,
  }) : nextReviewDate = nextReviewDate ?? DateTime.now();

  /// Days until this topic is next due. Negative means overdue.
  int get daysUntilDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(nextReviewDate.year, nextReviewDate.month, nextReviewDate.day);
    return due.difference(today).inDays;
  }

  bool get isDueToday => daysUntilDue <= 0;
}

class SyllabusState {
  final List<SubjectViewModel> subjects;
  final int streakDays;
  final int sessionCorrect;
  final int sessionAgain;
  final int sessionTotal;
  
  // Vault stats (now based on topics)
  final int totalMastered;
  final int totalReviews;
  final int totalLearning;
  final int totalReviewing;

  const SyllabusState({
    required this.subjects,
    this.streakDays = 12,
    this.sessionCorrect = 0,
    this.sessionAgain = 0,
    this.sessionTotal = 0,
    this.totalMastered = 0,
    this.totalReviews = 0,
    this.totalLearning = 0,
    this.totalReviewing = 0,
  });

  SyllabusState copyWith({
    List<SubjectViewModel>? subjects,
    int? streakDays,
    int? sessionCorrect,
    int? sessionAgain,
    int? sessionTotal,
  }) {
    return SyllabusState(
      subjects: subjects ?? this.subjects,
      streakDays: streakDays ?? this.streakDays,
      sessionCorrect: sessionCorrect ?? this.sessionCorrect,
      sessionAgain: sessionAgain ?? this.sessionAgain,
      sessionTotal: sessionTotal ?? this.sessionTotal,
      totalMastered: this.totalMastered,
      totalReviews: this.totalReviews,
      totalLearning: this.totalLearning,
      totalReviewing: this.totalReviewing,
    );
  }

  int get totalDueToday => subjects.fold(0, (s, subj) => s + subj.totalDue);
  int get totalTopics => subjects.fold(0, (s, subj) => s + subj.totalTopics);

  double get globalMastery {
    if (subjects.isEmpty) return 0.0;
    double sum = 0;
    for (var s in subjects) {
      sum += s.masteryPercent;
    }
    return sum / subjects.length;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAPPING: SLUG -> ICON & COLOR
// ─────────────────────────────────────────────────────────────────────────────

class SubjectAesthetics {
  final IconData icon;
  final Color color;
  const SubjectAesthetics(this.icon, this.color);
}

const Map<String, SubjectAesthetics> _subjectAestheticsMap = {
  'anatomy': SubjectAesthetics(Icons.accessibility_new_rounded, Color(0xFF4AE176)),
  'physiology': SubjectAesthetics(Icons.monitor_heart_outlined, Color(0xFFFF8A65)),
  'biochemistry': SubjectAesthetics(Icons.science_outlined, Color(0xFF8083FF)),
  'pathology': SubjectAesthetics(Icons.coronavirus_outlined, Color(0xFFFFDAD6)),
  'microbiology': SubjectAesthetics(Icons.bug_report_outlined, Color(0xFFDCE775)),
  'pharmacology': SubjectAesthetics(Icons.medication_outlined, Color(0xFF4FDBC8)),
  'forensic_medicine': SubjectAesthetics(Icons.gavel_outlined, Color(0xFF90A4AE)),
  'social_&_preventive_medicine': SubjectAesthetics(Icons.public_outlined, Color(0xFF81C784)),
  'medicine': SubjectAesthetics(Icons.health_and_safety_outlined, Color(0xFF64B5F6)),
  'surgery': SubjectAesthetics(Icons.content_cut_outlined, Color(0xFFE57373)),
  'gynaecology_&_obstetrics': SubjectAesthetics(Icons.pregnant_woman_outlined, Color(0xFFF06292)),
  'pediatrics': SubjectAesthetics(Icons.child_care_outlined, Color(0xFFFFD54F)),
  'orthopaedics': SubjectAesthetics(Icons.sports_martial_arts_outlined, Color(0xFFBCAAA4)),
  'ophthalmology': SubjectAesthetics(Icons.visibility_outlined, Color(0xFF4DB6AC)),
  'ent': SubjectAesthetics(Icons.hearing_outlined, Color(0xFF9575CD)),
  'psychiatry': SubjectAesthetics(Icons.psychology_outlined, Color(0xFFC0C1FF)),
  'radiology': SubjectAesthetics(Icons.sensors_outlined, Color(0xFF4DD0E1)),
  'anaesthesia': SubjectAesthetics(Icons.masks_outlined, Color(0xFF7986CB)),
  'skin': SubjectAesthetics(Icons.spa_outlined, Color(0xFFFFB74D)),
  'dental': SubjectAesthetics(Icons.medical_services_outlined, Color(0xFFA1887F)),
  'clinical_high-yield': SubjectAesthetics(Icons.star_outline_rounded, Color(0xFFFFD700)),
  'self_made': SubjectAesthetics(Icons.auto_awesome_rounded, Color(0xFFBCAAA4)),
};

SubjectAesthetics getAesthetics(String slug) {
  return _subjectAestheticsMap[slug] ?? const SubjectAesthetics(Icons.book_outlined, Color(0xFFBDBDBD));
}

// ─────────────────────────────────────────────────────────────────────────────
// ASYNC NOTIFIER PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

class SyllabusNotifier extends AsyncNotifier<SyllabusState> {
  @override
  Future<SyllabusState> build() async {
    return _loadState();
  }

  Future<SyllabusState> _loadState() async {
    final isar = ref.watch(isarProvider);
    final isarSubjects = await isar.subjects.where().findAll();
    final now = DateTime.now();
    final cutoff = now.add(const Duration(hours: 1));

    List<SubjectViewModel> viewModels = await Future.wait(isarSubjects.map((s) async {
      final totalTopics = await isar.topics.where().subjectIdEqualTo(s.id).count();
      final totalDue = await isar.topics.filter()
          .subjectIdEqualTo(s.id)
          .nextReviewDateLessThan(cutoff)
          .boxNumberLessThan(5)
          .count();
      final masteredTopics = await isar.topics.filter()
          .subjectIdEqualTo(s.id)
          .boxNumberGreaterThan(4)
          .count();

      final boxCounts = <int>[];
      for (int i = 0; i <= 5; i++) {
        boxCounts.add(await isar.topics.filter().subjectIdEqualTo(s.id).boxNumberEqualTo(i).count());
      }

      double mastery = totalTopics > 0 ? masteredTopics / totalTopics : 0.0;
      final aesthetics = getAesthetics(s.slug);

      return SubjectViewModel(
        id: s.id,
        name: s.name,
        slug: s.slug,
        iconData: aesthetics.icon,
        accentColor: aesthetics.color,
        totalTopics: totalTopics,
        totalDue: totalDue,
        masteryPercent: mastery,
        boxCounts: boxCounts,
      );
    }));

    // Sort by most due topics first, then by total topics, then by name
    viewModels.sort((a, b) {
      if (a.totalDue != b.totalDue) return b.totalDue.compareTo(a.totalDue);
      if (a.totalTopics != b.totalTopics) return b.totalTopics.compareTo(a.totalTopics);
      return a.name.compareTo(b.name);
    });

    // Vault Stats calculation (now based on topics instead of cards)
    final globalMastered = await isar.topics.where().boxNumberGreaterThan(4).count();
    final globalLearning = await isar.topics.where().boxNumberLessThan(3).count();
    final globalReviewing = await isar.topics.where().boxNumberBetween(3, 4).count();

    final logs = await isar.activityLogs.where().sortByDateDesc().findAll();
    int totalReviews = 0;
    int streak = 0;
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    DateTime? expectedDate = today;

    for (var log in logs) {
      totalReviews += log.topicsReviewed;
      final logDay = DateTime(log.date.year, log.date.month, log.date.day);
      
      if (expectedDate != null) {
        if (logDay == expectedDate) {
          if (log.topicsReviewed > 0) {
            streak++;
            expectedDate = expectedDate.subtract(const Duration(days: 1));
          } else {
            expectedDate = null;
          }
        } else if (logDay == yesterday && expectedDate == today) {
          // haven't studied today yet, but studied yesterday. Streak continues from yesterday.
          if (log.topicsReviewed > 0) {
            streak++;
            expectedDate = yesterday.subtract(const Duration(days: 1));
          } else {
            expectedDate = null;
          }
        } else if (logDay.isBefore(expectedDate)) {
          expectedDate = null; // missed a day, streak broken
        }
      }
    }

    final currentState = state.valueOrNull;
    return SyllabusState(
      subjects: viewModels,
      streakDays: streak,
      totalMastered: globalMastered,
      totalReviews: totalReviews,
      totalLearning: globalLearning,
      totalReviewing: globalReviewing,
      sessionCorrect: currentState?.sessionCorrect ?? 0,
      sessionAgain: currentState?.sessionAgain ?? 0,
      sessionTotal: currentState?.sessionTotal ?? 0,
    );
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadState());
  }

  Future<void> toggleTopicCompletion(int topicId) async {
    final isar = ref.read(isarProvider);
    final topic = await isar.topics.get(topicId);
    if (topic != null) {
      topic.isCompleted = !topic.isCompleted;
      await isar.writeTxn(() async {
        await isar.topics.put(topic);
      });
      final userId = ref.read(authStateProvider).valueOrNull?.uid;
      if (userId != null) {
        ref.read(syncServiceProvider).pushTopic(userId, topic);
      }
      await reload();
    }
  }

  Future<void> updateTopicNotes(int topicId, String? readNotes, String? unreadNotes, String? importantNotes) async {
    final isar = ref.read(isarProvider);
    final topic = await isar.topics.get(topicId);
    if (topic != null) {
      topic.readNotes = readNotes;
      topic.unreadNotes = unreadNotes;
      topic.importantNotes = importantNotes;
      await isar.writeTxn(() async {
        await isar.topics.put(topic);
      });
      final userId = ref.read(authStateProvider).valueOrNull?.uid;
      if (userId != null) {
        ref.read(syncServiceProvider).pushTopic(userId, topic);
      }
      ref.invalidate(topicsForSubjectProvider(topic.subjectId));
      ref.invalidate(topicsByBoxProvider);
    }
  }

  void handleSessionProgress(bool isCorrect) {
    if (state.valueOrNull == null) return;
    final curr = state.value!;
    state = AsyncValue.data(curr.copyWith(
      sessionCorrect: isCorrect ? curr.sessionCorrect + 1 : curr.sessionCorrect,
      sessionAgain: !isCorrect ? curr.sessionAgain + 1 : curr.sessionAgain,
      sessionTotal: curr.sessionTotal + 1,
    ));
  }

  void resetSession() {
    if (state.valueOrNull == null) return;
    state = AsyncValue.data(state.value!.copyWith(
      sessionCorrect: 0,
      sessionAgain: 0,
      sessionTotal: 0,
    ));
  }

  Future<void> addTopic({
    required String topicName,
  }) async {
    final isar = ref.read(isarProvider);
    
    // Find or create 'Self Made' subject
    var selfMadeSubject = await isar.subjects.filter().slugEqualTo('self_made').findFirst();
    bool newSubject = false;
    if (selfMadeSubject == null) {
      selfMadeSubject = isar_model.Subject()
        ..name = 'Self Made'
        ..slug = 'self_made'
        ..colorCode = '0xFFBCAAA4';
      await isar.writeTxn(() async {
        await isar.subjects.put(selfMadeSubject!);
      });
      newSubject = true;
    }

    final newTopic = Topic()
      ..id = DateTime.now().millisecondsSinceEpoch // Use timestamp for custom topics
      ..subjectId = selfMadeSubject.id
      ..name = topicName
      ..isCompleted = false
      ..boxNumber = 0
      ..nextReviewDate = DateTime.now();

    await isar.writeTxn(() async {
      await isar.topics.put(newTopic);
    });
    
    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    if (userId != null) {
      if (newSubject) ref.read(syncServiceProvider).pushSubject(userId, selfMadeSubject!);
      ref.read(syncServiceProvider).pushTopic(userId, newTopic);
    }

    await reload();
  }
}

final syllabusProvider = AsyncNotifierProvider<SyllabusNotifier, SyllabusState>(
  SyllabusNotifier.new,
);

/// Provider to get topic view models for a given subject. 
/// Used for TopicDetailScreen.
final topicsForSubjectProvider = FutureProvider.family<List<TopicViewModel>, int>((ref, subjectId) async {
  final isar = ref.watch(isarProvider);
  final topics = await isar.topics.where().subjectIdEqualTo(subjectId).findAll();
  final now = DateTime.now();
  final cutoff = now.add(const Duration(hours: 1));
  
  final viewModels = await Future.wait(topics.map((t) async {
    final isMastered = t.boxNumber > 4;
    double mastery = isMastered ? 1.0 : (t.boxNumber / 5.0);
    
    return TopicViewModel(
      id: t.id,
      subjectId: t.subjectId,
      name: t.name,
      description: t.description ?? '',
      isCompleted: t.isCompleted,
      masteryPercent: mastery,
      boxNumber: t.boxNumber,
      nextReviewDate: t.nextReviewDate,
      readNotes: t.readNotes,
      unreadNotes: t.unreadNotes,
      importantNotes: t.importantNotes,
    );
  }));
  
  return viewModels;
});

class CompletedTopicEntry {
  final SubjectViewModel subject;
  final TopicViewModel topic;
  CompletedTopicEntry(this.subject, this.topic);
}

final completedTopicsProvider = FutureProvider<List<CompletedTopicEntry>>((ref) async {
  final isar = ref.watch(isarProvider);
  final topics = await isar.topics.filter().isCompletedEqualTo(true).findAll();
  final subjects = await isar.subjects.where().findAll();
  
  final entries = await Future.wait(topics.map((t) async {
    final s = subjects.firstWhere((subj) => subj.id == t.subjectId, orElse: () => subjects.first);
    final aesthetics = getAesthetics(s.slug);
    
    final subjViewModel = SubjectViewModel(
      id: s.id,
      name: s.name,
      slug: s.slug,
      iconData: aesthetics.icon,
      accentColor: aesthetics.color,
      totalTopics: 0,
      totalDue: 0,
      masteryPercent: 0,
    );
    
    final isMastered = t.boxNumber > 4;
    double mastery = isMastered ? 1.0 : (t.boxNumber / 5.0);
    
    final topicViewModel = TopicViewModel(
      id: t.id,
      subjectId: t.subjectId,
      name: t.name,
      description: t.description ?? '',
      isCompleted: t.isCompleted,
      masteryPercent: mastery,
      boxNumber: t.boxNumber,
      nextReviewDate: t.nextReviewDate,
      readNotes: t.readNotes,
      unreadNotes: t.unreadNotes,
      importantNotes: t.importantNotes,
    );
    
    return CompletedTopicEntry(subjViewModel, topicViewModel);
  }));
  
  return entries;
});

final monthlyActivityProvider = FutureProvider<Map<DateTime, int>>((ref) async {
  final isar = ref.watch(isarProvider);
  final now = DateTime.now();
  final twentyEightDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 27));
  
  final logs = await isar.activityLogs
      .filter()
      .dateGreaterThan(twentyEightDaysAgo.subtract(const Duration(milliseconds: 1)))
      .sortByDate()
      .findAll();
      
  final aggregated = <DateTime, int>{};
  for (final log in logs) {
    // Normalise date to midnight
    final date = DateTime(log.date.year, log.date.month, log.date.day);
    aggregated[date] = (aggregated[date] ?? 0) + log.topicsReviewed;
  }
  
  return aggregated;
});

// ─────────────────────────────────────────────────────────────────────────────
// ARENA: TOPICS BY BOX PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

/// A topic entry for the Arena screen — includes subject info for the badge.
class TopicWithSubjectViewModel {
  final TopicViewModel topic;
  final SubjectViewModel subject;

  const TopicWithSubjectViewModel({required this.topic, required this.subject});
}

/// Returns all topics grouped by their [Topic.boxNumber] (1–5).
///
/// Uses indexed [boxNumber] Isar queries — no full-table scan.
/// Subjects are loaded once and used for badge display.
/// This provider is NOT auto-disposed so it stays cached across navigations
/// and only re-runs when explicitly invalidated (after a review session).
final topicsByBoxProvider = FutureProvider<Map<int, List<TopicWithSubjectViewModel>>>((ref) async {
  final isar = ref.watch(isarProvider);
  
  // Load all subjects once for badge display
  final isarSubjects = await isar.subjects.where().findAll();
  final subjectMap = <int, isar_model.Subject>{};
  for (final s in isarSubjects) {
    subjectMap[s.id] = s;
  }

  // Group topics by boxNumber using indexed queries (1 query per box = 5 total)
  final result = <int, List<TopicWithSubjectViewModel>>{};
  
  for (int box = 0; box <= 5; box++) {
    final topics = await isar.topics.where().boxNumberEqualTo(box).findAll();
    
    final entries = await Future.wait(topics.map((t) async {
      final subj = subjectMap[t.subjectId];
      if (subj == null) return null;
      
      final aesthetics = getAesthetics(subj.slug);
      final subjViewModel = SubjectViewModel(
        id: subj.id,
        name: subj.name,
        slug: subj.slug,
        iconData: aesthetics.icon,
        accentColor: aesthetics.color,
        totalTopics: 0,
        totalDue: 0,
        masteryPercent: 0,
      );
      
      return TopicWithSubjectViewModel(
        topic: TopicViewModel(
          id: t.id,
          subjectId: t.subjectId,
          name: t.name,
          description: t.description ?? '',
          isCompleted: t.isCompleted,
          masteryPercent: 0,
          boxNumber: t.boxNumber,
          nextReviewDate: t.nextReviewDate,
          readNotes: t.readNotes,
          unreadNotes: t.unreadNotes,
          importantNotes: t.importantNotes,
        ),
        subject: subjViewModel,
      );
    }));
    
    result[box] = entries.whereType<TopicWithSubjectViewModel>().toList();
  }
  
  return result;
});
