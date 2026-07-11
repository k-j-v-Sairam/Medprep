import 'dart:async';
import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:isar_community/isar.dart' hide Query;
import 'package:shared_preferences/shared_preferences.dart';

import '../../study_session/domain/topic.dart';
import '../../study_session/domain/activity_log.dart';
import '../../study_session/domain/subject.dart';

/// The Firestore path schema:
///   users/{userId}/topic_progress/{topicId}
///   users/{userId}/activity_logs/{dateStr}
///   users/{userId}/subjects/{subjectId}
///
class FirestoreSyncService {
  final FirebaseFirestore _firestore;
  final Isar _isar;
  final SharedPreferences _prefs;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  FirestoreSyncService({
    required Isar isar,
    required SharedPreferences prefs,
    FirebaseFirestore? firestore,
  })  : _isar = isar,
        _prefs = prefs,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Starts listening for network reconnections.  When connectivity is
  /// restored and [userId] is non-null, a background sync is triggered.
  ///
  /// Call once after the user is confirmed authenticated.
  void startConnectivityListener(String userId) {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((results) {
      final hasNetwork = results.any((r) => r != ConnectivityResult.none);
      if (hasNetwork) {
        dev.log('🌐 Network restored — triggering sync for $userId', name: 'SyncService');
        unawaited(syncAll(userId));
      }
    });
  }

  /// Stops the connectivity listener (call when the user signs out).
  void stopConnectivityListener() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  // ── Sync orchestrator ─────────────────────────────────────────────────────

  /// Runs a full two-way sync: pushes local progress to Firestore, then
  /// pulls remote progress that is newer than what is local.
  ///
  /// Runs silently in the background.  Never throws — all errors are logged.
  Future<void> syncAll(String userId) async {
    try {
      await _checkConnectivity();
      await pushProgressDelta(userId);
      await pushActivityLogs(userId);
      await pullRemoteProgress(userId);
      await pullRemoteActivityLogs(userId);
      await pullRemoteSubjects(userId);
    } catch (e, st) {
      dev.log('SyncService.syncAll error: $e',
          name: 'SyncService', error: e, stackTrace: st);
    }
  }

  // ── Push (local → Firestore) ──────────────────────────────────────────────

  /// Uploads local [Topic] progress records that have been reviewed
  Future<void> pushProgressDelta(String userId) async {
    try {
      final pushStartTime = DateTime.now();
      
      var query = _isar.topics.filter()
          .boxNumberGreaterThan(0)
          .or().isCompletedEqualTo(true)
          .or().readNotesIsNotEmpty()
          .or().unreadNotesIsNotEmpty()
          .or().importantNotesIsNotEmpty();
      
      final reviewed = await query.findAll();

      if (reviewed.isEmpty) {
        return;
      }

      final collRef = _userProgressCollection(userId);
      const chunkSize = 500; // Firestore batch limit

      for (int i = 0; i < reviewed.length; i += chunkSize) {
        final chunk = reviewed.skip(i).take(chunkSize);
        final batch = _firestore.batch();
        for (final topic in chunk) {
          final docRef = collRef.doc(topic.id.toString());
          batch.set(
            docRef,
            {
              'boxNumber': topic.boxNumber,
              'isCompleted': topic.isCompleted,
              'nextReviewDate': topic.nextReviewDate?.toIso8601String(),
              'readNotes': topic.readNotes,
              'unreadNotes': topic.unreadNotes,
              'importantNotes': topic.importantNotes,
              'name': topic.name, // useful if it's a self-made topic
              'subjectId': topic.subjectId,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
        await batch.commit();
      }

      await _prefs.setString('last_sync_$userId', pushStartTime.toIso8601String());

      dev.log('SyncService: pushed ${reviewed.length} progress records', name: 'SyncService');
    } catch (e, st) {
      dev.log('SyncService.pushProgressDelta error: $e',
          name: 'SyncService', error: e, stackTrace: st);
    }
  }

  Future<void> pushActivityLogs(String userId) async {
    try {
      final logs = await _isar.activityLogs.where().findAll();
      if (logs.isEmpty) return;

      final collRef = _userActivityLogsCollection(userId);
      final batch = _firestore.batch();
      for (final log in logs) {
        final dateStr = "${log.date.year}-${log.date.month.toString().padLeft(2, '0')}-${log.date.day.toString().padLeft(2, '0')}";
        final docRef = collRef.doc(dateStr);
        batch.set(docRef, {
          'topicsReviewed': log.topicsReviewed,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
    } catch (e, st) {
      dev.log('SyncService.pushActivityLogs error: $e', name: 'SyncService', error: e, stackTrace: st);
    }
  }

  // ── Immediate Push (Fire and Forget) ──────────────────────────────────────

  Future<void> pushTopic(String userId, Topic topic) async {
    try {
      await _userProgressCollection(userId).doc(topic.id.toString()).set({
        'boxNumber': topic.boxNumber,
        'isCompleted': topic.isCompleted,
        'nextReviewDate': topic.nextReviewDate?.toIso8601String(),
        'readNotes': topic.readNotes,
        'unreadNotes': topic.unreadNotes,
        'importantNotes': topic.importantNotes,
        'name': topic.name,
        'subjectId': topic.subjectId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Offline first, swallow exception
    }
  }

  Future<void> pushActivityLog(String userId, ActivityLog log) async {
    try {
      final dateStr = "${log.date.year}-${log.date.month.toString().padLeft(2, '0')}-${log.date.day.toString().padLeft(2, '0')}";
      await _userActivityLogsCollection(userId).doc(dateStr).set({
        'topicsReviewed': log.topicsReviewed,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Offline first, swallow exception
    }
  }

  Future<void> pushSubject(String userId, Subject subject) async {
    try {
      await _userSubjectsCollection(userId).doc(subject.id.toString()).set({
        'name': subject.name,
        'slug': subject.slug,
        'colorCode': subject.colorCode,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Offline first, swallow exception
    }
  }

  // ── Pull (Firestore → local) ──────────────────────────────────────────────

  /// Downloads Firestore progress documents and applies any that are newer
  Future<void> pullRemoteProgress(String userId) async {
    try {
      final pullStartTime = DateTime.now();
      final lastSyncStr = _prefs.getString('last_sync_pull_$userId') ?? 
                          _prefs.getString('last_sync_$userId');
      DateTime? lastSync;
      if (lastSyncStr != null) {
        lastSync = DateTime.tryParse(lastSyncStr);
      }

      Query<Map<String, dynamic>> query = _userProgressCollection(userId);
      if (lastSync != null) {
        query = query.where('updatedAt', isGreaterThan: Timestamp.fromDate(lastSync));
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        await _prefs.setString('last_sync_pull_$userId', pullStartTime.toIso8601String());
        return;
      }

      final docMap = <int, Map<String, dynamic>>{};
      for (final doc in snapshot.docs) {
        final topicId = int.tryParse(doc.id);
        if (topicId != null) {
          docMap[topicId] = doc.data();
        }
      }

      await _isar.writeTxn(() async {
        final topicIds = docMap.keys.toList();
        final locals = await _isar.topics.getAll(topicIds);
        final toUpdate = <Topic>[];

        for (int i = 0; i < locals.length; i++) {
          Topic? local = locals[i];
          final topicId = topicIds[i];
          final data = docMap[topicId]!;

          if (local == null) {
            // It might be a self-made topic synced from another device
            if (data['name'] != null && data['subjectId'] != null) {
              local = Topic()
                ..id = topicId
                ..subjectId = data['subjectId'] as int
                ..name = data['name'] as String;
            } else {
              continue;
            }
          }

          local.boxNumber = (data['boxNumber'] as int?) ?? local.boxNumber;
          local.isCompleted = (data['isCompleted'] as bool?) ?? local.isCompleted;
          local.nextReviewDate =
              _parseDateTime(data['nextReviewDate']) ?? local.nextReviewDate;
          local.readNotes = (data['readNotes'] as String?) ?? local.readNotes;
          local.unreadNotes = (data['unreadNotes'] as String?) ?? local.unreadNotes;
          local.importantNotes = (data['importantNotes'] as String?) ?? local.importantNotes;

          toUpdate.add(local);
        }

        if (toUpdate.isNotEmpty) {
          await _isar.topics.putAll(toUpdate);
        }
      });
      
      await _prefs.setString('last_sync_pull_$userId', pullStartTime.toIso8601String());

      dev.log('SyncService: pulled ${snapshot.docs.length} remote records',
          name: 'SyncService');
    } catch (e, st) {
      dev.log('SyncService.pullRemoteProgress error: $e',
          name: 'SyncService', error: e, stackTrace: st);
    }
  }

  Future<void> pullRemoteActivityLogs(String userId) async {
    try {
      final snapshot = await _userActivityLogsCollection(userId).get();
      if (snapshot.docs.isEmpty) return;

      final logsToInsert = <ActivityLog>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = _parseDateString(doc.id);
        if (date == null) continue;

        ActivityLog? log = await _isar.activityLogs.filter().dateEqualTo(date).findFirst();
        if (log == null) {
          log = ActivityLog()..date = date;
        }

        final remoteReviews = (data['topicsReviewed'] as int?) ?? 0;
        if (remoteReviews > log.topicsReviewed) {
          log.topicsReviewed = remoteReviews;
          logsToInsert.add(log);
        }
      }

      if (logsToInsert.isNotEmpty) {
        await _isar.writeTxn(() async {
          await _isar.activityLogs.putAll(logsToInsert);
        });
      }
    } catch (e, st) {
      dev.log('SyncService.pullRemoteActivityLogs error: $e', name: 'SyncService', error: e, stackTrace: st);
    }
  }

  Future<void> pullRemoteSubjects(String userId) async {
    try {
      final snapshot = await _userSubjectsCollection(userId).get();
      if (snapshot.docs.isEmpty) return;

      final subjectsToInsert = <Subject>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final subjectId = int.tryParse(doc.id);
        if (subjectId == null) continue;

        Subject? subject = await _isar.subjects.get(subjectId);
        if (subject == null) {
          subject = Subject()
            ..id = subjectId
            ..name = data['name'] ?? 'Self Made'
            ..slug = data['slug'] ?? 'self_made'
            ..colorCode = data['colorCode'];
          subjectsToInsert.add(subject);
        }
      }

      if (subjectsToInsert.isNotEmpty) {
        await _isar.writeTxn(() async {
          await _isar.subjects.putAll(subjectsToInsert);
        });
      }
    } catch (e, st) {
      dev.log('SyncService.pullRemoteSubjects error: $e', name: 'SyncService', error: e, stackTrace: st);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _userProgressCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('topic_progress');

  CollectionReference<Map<String, dynamic>> _userActivityLogsCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('activity_logs');

  CollectionReference<Map<String, dynamic>> _userSubjectsCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('subjects');

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  DateTime? _parseDateString(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
    } catch (_) {}
    return null;
  }

  Future<void> resetAllTopicProgress(String userId) async {
    try {
      final collRef = _userProgressCollection(userId);
      final snapshot = await collRef.get();
      const chunkSize = 500;
      
      for (int i = 0; i < snapshot.docs.length; i += chunkSize) {
        final chunk = snapshot.docs.skip(i).take(chunkSize);
        final batch = _firestore.batch();
        for (final doc in chunk) {
          batch.update(doc.reference, {
            'boxNumber': 0,
            'isCompleted': false,
            'nextReviewDate': null,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }
    } catch (e, st) {
      dev.log('SyncService.resetAllTopicProgress error: $e', name: 'SyncService', error: e, stackTrace: st);
    }
  }

  /// Throws [StateError] if there is definitely no network.
  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    final hasNetwork = results.any((r) => r != ConnectivityResult.none);
    if (!hasNetwork) throw StateError('No network connection');
  }
}
