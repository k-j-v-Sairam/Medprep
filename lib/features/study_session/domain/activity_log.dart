import 'package:isar_community/isar.dart';

part 'activity_log.g.dart';

@collection
class ActivityLog {
  Id id = Isar.autoIncrement;

  /// The day the study session happened. We usually normalize this to midnight.
  @Index(unique: true)
  late DateTime date;

  /// How many topics were reviewed on this day
  int topicsReviewed = 0;
}
