import 'dart:developer' as dev;

import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import '../../../../core/theme/app_theme.dart';

import '../domain/topic.dart';
import '../domain/subject.dart';
import '../domain/notification_log.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/auth_provider.dart';

final notificationServiceProvider = Provider((ref) {
  final isar = ref.watch(isarProvider);
  final user = ref.watch(currentUserProvider);
  return NotificationService(isar: isar, userId: user?.uid);
});

class NotificationService {
  final Isar isar;
  final String? userId;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationService({required this.isar, this.userId});

  Future<void> initialize({void Function(NotificationResponse)? onDidReceiveNotificationResponse}) async {
    tz.initializeTimeZones();
    try {
      final String timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      dev.log('NotificationService: Initialized timezone to $timeZoneName', name: 'Notification');
    } catch (e) {
      dev.log('NotificationService: Error setting timezone - $e', name: 'Notification');
    }
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }

  Future<bool> requestPermission() async {
    final androidImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      return granted ?? false;
    }
    
    final iosImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    return false;
  }

  Future<bool> requestExactAlarmsPermission() async {
    final androidImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final granted = await androidImpl.requestExactAlarmsPermission();
      return granted ?? false;
    }
    return true;
  }

  /// Schedules an exact notification for a specific topic when its review is due.
  Future<void> scheduleTopicReview(Topic topic, DateTime scheduledDate) async {
    try {
      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
      if (tzScheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        return; // Date is in the past
      }

      const androidDetails = AndroidNotificationDetails(
        'topic_review_channel',
        'Topic Reviews',
        channelDescription: 'Reminds you when specific topics are due for review',
        importance: Importance.high,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails();
      const notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

      // We use topic.id as the notification ID so it correctly overwrites any previous schedule for this topic
      await _notificationsPlugin.zonedSchedule(
        topic.id,
        'Time to review!',
        'Your topic "${topic.name}" is due for review.',
        tzScheduledDate,
        notificationDetails,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'topic_${topic.id}',
      );
      dev.log('NotificationService: Scheduled exact review for topic ${topic.id} at $tzScheduledDate', name: 'Notification');
    } catch (e, st) {
      dev.log('NotificationService: Error scheduling exact notification - $e', error: e, stackTrace: st, name: 'Notification');
    }
  }

  Future<void> cancelTopicReview(int topicId) async {
    await _notificationsPlugin.cancel(topicId);
  }

  /// Cancels all previously scheduled custom daily notifications and reschedules them based on settings.
  Future<void> rescheduleAllNotifications(SharedPreferences prefs) async {
    try {
      // We'll use notification IDs starting from 1000 for custom daily times.
      // Since we don't know exactly how many were scheduled previously, we cancel a safe range,
      // or we can just cancel specific IDs. Let's cancel a block of IDs (1000 to 1100).
      for (int i = 1000; i <= 1100; i++) {
        await _notificationsPlugin.cancel(i);
      }

      AndroidNotificationDetails getAndroidDetails(String contentTitle, String htmlText) {
        return AndroidNotificationDetails(
          'daily_review_channel',
          'Daily Review Reminders',
          channelDescription: 'Reminds you to review your cards at your custom times',
          importance: Importance.max,
          priority: Priority.max,
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.reminder,
          color: AppTheme.primary,
          colorized: true,
          styleInformation: BigTextStyleInformation(
            htmlText,
            htmlFormatBigText: true,
            htmlFormatContentTitle: true,
            contentTitle: contentTitle,
          ),
        );
      }
      
      const iosDetails = DarwinNotificationDetails();

      int currentId = 1000;
      
      final nowTime = DateTime.now();
      await isar.writeTxn(() async {
        await isar.notificationLogs.filter().timestampGreaterThan(nowTime).deleteAll();
      });

      // Fetch due subjects
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final dueTopics = await isar.topics.filter()
          .nextReviewDateIsNotNull()
          .nextReviewDateLessThan(todayEnd)
          .findAll();

      final dueSubjectIds = dueTopics.map((t) => t.subjectId).toSet().toList();
      final dueSubjects = await isar.subjects.getAll(dueSubjectIds);
      final validDueSubjects = dueSubjects.whereType<Subject>().toList();

      int subjectIndex = 0;
      Subject? getNextSubject() {
        if (validDueSubjects.isEmpty) return null;
        final s = validDueSubjects[subjectIndex % validDueSubjects.length];
        subjectIndex++;
        return s;
      }

      final suffix = userId != null ? '_$userId' : '';

      // 1. Specific Daily Times
      final timesStr = prefs.getString('notification_daily_times$suffix');
      List<String> dailyTimes = [];
      if (timesStr != null) {
        dailyTimes = List<String>.from(jsonDecode(timesStr));
      } else {
        // Default to 6 AM and 6 PM if not set
        dailyTimes = ['06:00', '18:00'];
        prefs.setString('notification_daily_times$suffix', jsonEncode(dailyTimes));
      }

      for (final time in dailyTimes) {
        final parts = time.split(':');
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]) ?? 6;
          final minute = int.tryParse(parts[1]) ?? 0;
          
          final subject = getNextSubject();
          String title = 'Time to review! 🌟';
          String plainBody = "Ready to crush your goals today? Your flashcards await! 🚀";
          String htmlBody = '<i>$plainBody</i><br><br>Open Akpa now and keep your streak alive!';

          if (subject != null) {
            title = '${subject.name} Review 📚';
            plainBody = "It's time to review ${subject.name}. Let's keep your streak alive!";
            htmlBody = 'You have cards due in <b>${subject.name}</b> today.<br><br><i>$plainBody</i>';
          }

          await _scheduleRepeatingNotification(
            id: currentId++,
            title: title,
            body: plainBody,
            hour: hour,
            minute: minute,
            details: NotificationDetails(
              android: getAndroidDetails(title, htmlBody),
              iOS: iosDetails,
            ),
            type: 'Subject Review',
          );
        }
      }

      // 2. Hourly Repetitions
      final hourlyEnabled = prefs.getBool('notification_hourly_enabled$suffix') ?? false;
      if (hourlyEnabled) {
        final startStr = prefs.getString('notification_hourly_start$suffix') ?? '09:00';
        final endStr = prefs.getString('notification_hourly_end$suffix') ?? '17:00';
        
        final startParts = startStr.split(':');
        final endParts = endStr.split(':');
        
        int startHour = int.tryParse(startParts[0]) ?? 9;
        int endHour = int.tryParse(endParts[0]) ?? 17;
        
        int freq = prefs.getInt('notification_repeat_frequency$suffix') ?? 1;
        if (freq < 1) freq = 1;

        if (startHour <= endHour) {
          for (int h = startHour; h <= endHour; h += freq) {
            final subject = getNextSubject();
            
            String title = 'Repetitive Flow 🌊';
            String plainBody = "Keep the momentum going! Just a few cards. 🔥";
            String htmlBody = '<i>$plainBody</i><br><br>Tap here to review 5 quick cards.';

            if (subject != null) {
              title = '${subject.name} Review 🌊';
              plainBody = "Keep the momentum going with ${subject.name}! 🔥";
              htmlBody = 'You still have <b>${subject.name}</b> cards due.<br><br><i>$plainBody</i>';
            }

            await _scheduleRepeatingNotification(
              id: currentId++,
              title: title,
              body: plainBody,
              hour: h,
              minute: 0,
              details: NotificationDetails(
                android: getAndroidDetails(title, htmlBody),
                iOS: iosDetails,
              ),
              type: 'Repetitive Flow',
            );
          }
        }
      }

      // 3. Exam Countdowns (Dynamic Custom Exams)
      bool examCountdownEnabled = prefs.getBool('notification_exam_countdown_enabled$suffix') ?? false;
      if (examCountdownEnabled) {
        final customExamsJson = prefs.getString('customExams$suffix');
        List<Map<String, dynamic>> examsList = [];
        if (customExamsJson != null) {
          try {
            examsList = List<Map<String, dynamic>>.from(json.decode(customExamsJson));
          } catch (e) {
            dev.log('Error parsing custom exams for notifications: $e');
          }
        } else {
          // Fallback for legacy single exam
          final legacyName = prefs.getString('customExamName$suffix');
          final legacyDate = prefs.getString('customExamDate$suffix');
          if (legacyName != null && legacyDate != null) {
            examsList.add({'name': legacyName, 'date': legacyDate});
          }
        }
        
        for (var exam in examsList) {
          final examName = exam['name'] as String?;
          final examDateStr = exam['date'] as String?;
          
          if (examName != null && examName.isNotEmpty && examDateStr != null) {
            final customExamDate = DateTime.tryParse(examDateStr);
            if (customExamDate != null) {
              final tzNow = tz.TZDateTime.now(tz.local);
              
              final timeStr = prefs.getString('notification_exam_countdown_time$suffix') ?? '06:30';
              final timeParts = timeStr.split(':');
              final examHour = int.tryParse(timeParts[0]) ?? 6;
              final examMinute = int.tryParse(timeParts[1]) ?? 30;
              
              // Schedule for the next 30 days
              for (int i = 0; i < 30; i++) {
                final scheduleDay = tzNow.add(Duration(days: i));
                final scheduledDate = tz.TZDateTime(tz.local, scheduleDay.year, scheduleDay.month, scheduleDay.day, examHour, examMinute);
                
                if (scheduledDate.isBefore(tzNow)) continue; // skip if time already passed today
                
                final targetTime = DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day, examHour, examMinute);
                final daysLeft = customExamDate.difference(targetTime).inDays;
                
                if (daysLeft >= 0) {
                  String htmlText = "<b>$examName:</b> $daysLeft days left<br><br><i>Every day counts. Let's study! 🎯</i>";
                  String plainText = "$examName: $daysLeft days left.";
                  
                  await _scheduleAbsoluteNotification(
                    id: currentId++,
                    title: 'Exam Countdown ⏳',
                    body: plainText,
                    scheduledDate: scheduledDate,
                    details: NotificationDetails(
                      android: getAndroidDetails('Exam Countdown ⏳', htmlText),
                      iOS: iosDetails,
                    ),
                    type: 'Countdown',
                  );
                }
              }
            }
          }
        }
      }

      dev.log('NotificationService: Rescheduled custom notifications. Total scheduled: ${currentId - 1000}', name: 'Notification');
    } catch (e, st) {
      dev.log('NotificationService: Error rescheduling notifications - $e', error: e, stackTrace: st, name: 'Notification');
    }
  }

  Future<void> _scheduleRepeatingNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required NotificationDetails details,
    required String type,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    final cleanTitle = title.replaceAll(RegExp(r'<[^>]*>'), '');
    final log = NotificationLog()
      ..title = cleanTitle
      ..body = body
      ..timestamp = scheduledDate
      ..type = type;
    await isar.writeTxn(() async {
      await isar.notificationLogs.put(log);
    });
  }

  Future<void> _scheduleAbsoluteNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    required String type,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    final cleanTitle = title.replaceAll(RegExp(r'<[^>]*>'), '');
    final log = NotificationLog()
      ..title = cleanTitle
      ..body = body
      ..timestamp = scheduledDate
      ..type = type;
    await isar.writeTxn(() async {
      await isar.notificationLogs.put(log);
    });
  }

  /// Original daily review function
  Future<void> scheduleDailyReviewNotification() async {
    try {
      final now = DateTime.now();
      
      // Calculate how many topics will be due by tomorrow at 10 AM.
      final tomorrow10Am = DateTime(now.year, now.month, now.day + 1, 10, 0);
      final dueTopics = await isar.topics
          .filter()
          .nextReviewDateLessThan(tomorrow10Am)
          .count();

      // We only cancel the ID 0 notification so we don't clear topic notifications
      await _notificationsPlugin.cancel(0);

      if (dueTopics > 0) {
        final scheduleTime = tz.TZDateTime.local(now.year, now.month, now.day, 10, 0);
        final nextSchedule = scheduleTime.isBefore(tz.TZDateTime.now(tz.local)) 
            ? scheduleTime.add(const Duration(days: 1)) 
            : scheduleTime;

        const androidDetails = AndroidNotificationDetails(
          'daily_review_channel',
          'Daily Review Reminders',
          channelDescription: 'Reminds you when topics are due for review',
          importance: Importance.high,
          priority: Priority.high,
        );
        const iosDetails = DarwinNotificationDetails();
        const notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

        await _notificationsPlugin.zonedSchedule(
          0,
          'Time to study!',
          'You have $dueTopics topics due for review.',
          nextSchedule,
          notificationDetails,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        dev.log('NotificationService: Scheduled daily for $nextSchedule with $dueTopics topics', name: 'Notification');
      }
    } catch (e, st) {
      dev.log('NotificationService: Error scheduling daily notification - $e', error: e, stackTrace: st, name: 'Notification');
    }
  }
}
