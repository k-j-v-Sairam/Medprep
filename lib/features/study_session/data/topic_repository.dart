import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/sync_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../application/notification_service.dart';
import '../domain/topic.dart';

final topicRepositoryProvider = Provider<TopicRepository>((ref) {
  return TopicRepository(ref);
});

class TopicRepository {
  final Ref _ref;
  
  TopicRepository(this._ref);

  Isar get _isar => _ref.read(isarProvider);
  String? get _userId => _ref.read(authStateProvider).valueOrNull?.uid;
  NotificationService get _notificationService => _ref.read(notificationServiceProvider);

  Future<void> promoteTopic(int topicId) async {
    final dbTopic = await _isar.topics.get(topicId);
    if (dbTopic == null || dbTopic.boxNumber >= 5) return;

    dbTopic.boxNumber = dbTopic.boxNumber == 0 ? 1 : dbTopic.boxNumber + 1;
    final intervals = [1, 3, 7, 14, 30];
    final days = intervals[(dbTopic.boxNumber.clamp(1, 5)) - 1];
    dbTopic.nextReviewDate = DateTime.now().add(Duration(days: days));
    
    await _isar.writeTxn(() async {
      await _isar.topics.put(dbTopic);
    });
    
    await _notificationService.scheduleTopicReview(dbTopic, dbTopic.nextReviewDate!);
    await _notificationService.scheduleDailyReviewNotification();
    
    final userId = _userId;
    if (userId != null) {
      _ref.read(syncServiceProvider).pushTopic(userId, dbTopic);
    }
  }

  Future<void> demoteTopic(int topicId) async {
    final dbTopic = await _isar.topics.get(topicId);
    if (dbTopic == null) return;

    dbTopic.boxNumber = 1;
    dbTopic.nextReviewDate = DateTime.now().add(const Duration(days: 1));
    
    await _isar.writeTxn(() async {
      await _isar.topics.put(dbTopic);
    });
    
    await _notificationService.scheduleTopicReview(dbTopic, dbTopic.nextReviewDate!);
    await _notificationService.scheduleDailyReviewNotification();
    
    final userId = _userId;
    if (userId != null) {
      _ref.read(syncServiceProvider).pushTopic(userId, dbTopic);
    }
  }

  Future<void> undoMove(int topicId, int oldBox, DateTime? oldDate) async {
    final dbTopic = await _isar.topics.get(topicId);
    if (dbTopic == null) return;

    dbTopic.boxNumber = oldBox;
    dbTopic.nextReviewDate = oldDate;
    await _isar.writeTxn(() async {
      await _isar.topics.put(dbTopic);
    });
    
    if (oldDate != null) {
      await _notificationService.scheduleTopicReview(dbTopic, oldDate);
    } else {
      await _notificationService.cancelTopicReview(topicId);
    }
    await _notificationService.scheduleDailyReviewNotification();
    
    final userId = _userId;
    if (userId != null) {
      _ref.read(syncServiceProvider).pushTopic(userId, dbTopic);
    }
  }

  Future<void> batchMove(List<int> topicIds, int destBox) async {
    final topicsToMove = await _isar.topics.getAll(topicIds);
    
    await _isar.writeTxn(() async {
      for (var t in topicsToMove) {
        if (t != null) {
          t.boxNumber = destBox;
          if (destBox == 0) {
            t.nextReviewDate = null;
            await _notificationService.cancelTopicReview(t.id);
          } else {
            final intervals = [1, 3, 7, 14, 30];
            final days = intervals[(destBox.clamp(1, 5)) - 1];
            t.nextReviewDate = DateTime.now().add(Duration(days: days));
            await _notificationService.scheduleTopicReview(t, t.nextReviewDate!);
          }
          await _isar.topics.put(t);
        }
      }
    });
    
    final userId = _userId;
    if (userId != null) {
      for (var t in topicsToMove) {
        if (t != null) {
          _ref.read(syncServiceProvider).pushTopic(userId, t);
        }
      }
    }
    
    await _notificationService.scheduleDailyReviewNotification();
  }
}
