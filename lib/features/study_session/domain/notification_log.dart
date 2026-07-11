import 'package:isar_community/isar.dart';

part 'notification_log.g.dart';

@collection
class NotificationLog {
  Id id = Isar.autoIncrement;

  late String title;
  late String body;
  late DateTime timestamp;
  late String type; // e.g., 'Subject Review', 'Countdown', 'Repetitive Flow'
}
