import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../data/database.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    // Initialize timezone database
    tz.initializeTimeZones();

    // Configure Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configure iOS initialization settings
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _notificationsPlugin.initialize(settings: initializationSettings);
  }

  Future<bool> requestPermissions() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return true;
    final bool? androidGranted = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    final bool? iOSGranted = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    return (androidGranted ?? false) || (iOSGranted ?? false);
  }

  Future<void> showBudgetAlert({
    required String categoryName,
    required double spentPercent,
  }) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'budget_alerts_channel',
          'Budget Alerts',
          channelDescription: 'Notifications when budgets exceed thresholds',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      id: 100 + categoryName.hashCode,
      title: 'Budget Warning! ⚠️',
      body:
          'Your spending for $categoryName has reached ${(spentPercent * 100).toStringAsFixed(0)}% of its limit.',
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> scheduleWeeklySummary() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    // Cancel existing weekly summary
    await _notificationsPlugin.cancel(id: 200);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'weekly_summary_channel',
          'Weekly Spending Summary',
          channelDescription: 'Scheduled summary of weekly financial reports',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    // Schedule for next Sunday at 9:00 AM
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9, // 9 AM
      0,
    );

    // Find next Sunday (Sunday is day 7 in DateTime)
    while (scheduledDate.weekday != DateTime.sunday ||
        scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id: 200,
      title: 'Weekly Finance Summary 📊',
      body:
          'Your weekly BudgetWise summary is ready! Open the app to review your balance and category targets.',
      scheduledDate: scheduledDate,
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> scheduleGoalDeadlineReminder(SavingsGoal goal) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    final int goalNotificationId = 300 + goal.id.hashCode;

    // Cancel any existing reminder for this goal
    await _notificationsPlugin.cancel(id: goalNotificationId);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'goal_reminders_channel',
          'Goal Deadline Reminders',
          channelDescription:
              'Notifications alerting when a savings goal deadline is close',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    // Schedule 1 day before the goal deadline
    final DateTime deadline = goal.deadline;
    final DateTime reminderTime = deadline.subtract(const Duration(days: 1));

    final tz.TZDateTime tzReminderTime = tz.TZDateTime.from(
      reminderTime,
      tz.local,
    );
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    if (tzReminderTime.isBefore(now)) {
      // If deadline is less than 1 day away, do not schedule
      return;
    }

    await _notificationsPlugin.zonedSchedule(
      id: goalNotificationId,
      title: 'Goal Deadline Approaching! 🎯',
      body:
          'Your savings goal "${goal.name}" is due tomorrow! Make a final contribution to hit your target.',
      scheduledDate: tzReminderTime,
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelGoalReminder(String goalId) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    await _notificationsPlugin.cancel(id: 300 + goalId.hashCode);
  }
}
