import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/topic_repository.dart';
import '../../../core/providers/syllabus_state_provider.dart';

final topicControllerProvider = Provider<TopicController>((ref) {
  return TopicController(ref);
});

class TopicController {
  final Ref _ref;
  
  TopicController(this._ref);

  TopicRepository get _repository => _ref.read(topicRepositoryProvider);

  Future<void> promoteTopic(int topicId) async {
    await _repository.promoteTopic(topicId);
    _ref.invalidate(topicsByBoxProvider);
  }

  Future<void> demoteTopic(int topicId) async {
    await _repository.demoteTopic(topicId);
    _ref.invalidate(topicsByBoxProvider);
  }

  Future<void> undoMove(int topicId, int oldBox, DateTime? oldDate) async {
    await _repository.undoMove(topicId, oldBox, oldDate);
    _ref.invalidate(topicsByBoxProvider);
  }

  Future<void> batchMove(List<int> topicIds, int destBox) async {
    await _repository.batchMove(topicIds, destBox);
    _ref.invalidate(topicsByBoxProvider);
  }
}
