import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../widgets/transaction_dialog.dart';
import '../providers/expense_provider.dart';
import '../models/transaction.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  GlobalKey<NavigatorState>? _navigatorKey;

  Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;

    await AwesomeNotifications().initialize(
      // set the icon to null if you want to use the default app icon
      null, 
      [
        NotificationChannel(
          channelGroupKey: 'reminders_group',
          channelKey: 'reminders_v3',
          channelName: 'Reminders',
          channelDescription: 'Daily and weekly reminders',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          criticalAlerts: true,
        ),
        NotificationChannel(
          channelGroupKey: 'status_group',
          channelKey: 'weekly_status',
          channelName: 'Weekly Status',
          channelDescription: 'Ongoing weekly summary',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.Low,
          channelShowBadge: false,
          playSound: false,
          enableVibration: false,
          locked: true, 
        )
      ],
      channelGroups: [
        NotificationChannelGroup(
            channelGroupKey: 'reminders_group',
            channelGroupName: 'Reminders Group'),
        NotificationChannelGroup(
            channelGroupKey: 'status_group',
            channelGroupName: 'Status Group')
      ],
      debug: true,
    );

    // Request permission to send notifications
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        // Option to request permission here or in UI
      }
    });

    await AwesomeNotifications().setListeners(
        onActionReceivedMethod: onActionReceivedMethod,
        onNotificationCreatedMethod: onNotificationCreatedMethod,
        onNotificationDisplayedMethod: onNotificationDisplayedMethod,
        onDismissActionReceivedMethod: onDismissActionReceivedMethod);
        
    await _scheduleDailyReminder();
    await _scheduleWeeklySummaryReminder();
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    final service = NotificationService();
    if (service._navigatorKey?.currentState?.context != null) {
         service._handleNotificationTap();
    }
  }

  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {}

  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {}

  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {}
  
  void _handleNotificationTap() {
    if (_navigatorKey?.currentState?.context != null) {
      _showAddTransactionDialog(_navigatorKey!.currentState!.context);
    }
  }

  Future<void> _showAddTransactionDialog(BuildContext context) async {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    
    final result = await showDialog<Transaction>(
      context: context,
      builder: (context) => TransactionDialog(
        categories: expenseProvider.categories,
      ),
    );

    if (result != null) {
      await expenseProvider.addTransaction(result);
    }
  }

  Future<bool> checkPermission() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }

  Future<void> requestPermission() async {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  // Schedule Daily Reminder
  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 101,
        channelKey: 'reminders_v3',
        title: 'Не забудьте записать расходы!',
        body: 'Потратили что-то сегодня? Запишите, чтобы бюджет был точным.',
        category: NotificationCategory.Reminder,
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        hour: time.hour,
        minute: time.minute,
        second: 0,
        millisecond: 0,
        repeats: true,
        allowWhileIdle: true,
        preciseAlarm: true, 
      ),
    );
  }

  // Schedule Weekly Summary
  Future<void> scheduleWeeklySummary(TimeOfDay time, {String? body}) async {
    final content = body ?? 'Зайдите, чтобы узнать, сколько вы сэкономили на лимитах!';
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 102,
        channelKey: 'reminders_v3', 
        title: 'Итоги недели 📊',
        body: content,
        category: NotificationCategory.Reminder,
      ),
      schedule: NotificationCalendar(
        weekday: 7, // Sunday
        hour: time.hour,
        minute: time.minute,
        second: 0,
        millisecond: 0,
        repeats: true,
        allowWhileIdle: true,
        preciseAlarm: true,
      ),
    );
  }



  Future<void> showWeeklySummaryPersistent({
    required List<Map<String, dynamic>> items,
    required double totalSpent,
    required double totalLimit,
  }) async {
      final percentage = totalLimit > 0 ? (totalSpent / totalLimit * 100).clamp(0, 100).toDouble() : 0.0;
      final spentStr = totalSpent.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
      final limitStr = totalLimit.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
      
      String title = 'Статус недели: ${percentage.toInt()}%';
      String bodyText = 'Потрачено: $spentStr ₸ из $limitStr ₸';
      
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 888,
          channelKey: 'weekly_status',
          title: title,
          body: bodyText,
          summary: 'Ваш бюджет',
          locked: true,
          autoDismissible: false,
          category: NotificationCategory.Progress,
          notificationLayout: NotificationLayout.ProgressBar,
          progress: percentage,
          showWhen: false,
          color: totalSpent > totalLimit ? Colors.red : const Color(0xFF9D50DD),
        ),
      );
  }

  // Wrapper for persistent summary to match old API
  Future<void> showWeeklySummary({
    required List<Map<String, dynamic>> items,
    required double totalSpent,
    required double totalLimit,
    required String currency,
  }) async {
      await showWeeklySummaryPersistent(
          items: items, 
          totalSpent: totalSpent, 
          totalLimit: totalLimit
      );
  }

  // Wrapper for updating content
  Future<void> updateWeeklySummaryContent(double spent, double limit) async {
    final box = await Hive.openBox('settings');
    final hour = box.get('weekly_reminder_hour', defaultValue: 20);
    final minute = box.get('weekly_reminder_minute', defaultValue: 0);

    final saving = limit - spent;
    String content;
    if (spent > limit) {
       content = '⚠️ Расходы: ${spent.toInt()} / Лимит: ${limit.toInt()} (Превышение: ${(spent - limit).toInt()})';
    } else {
       content = '✅ Расходы: ${spent.toInt()} / Лимит: ${limit.toInt()} (Экономия: ${saving.toInt()})';
    }
    
    // We restart the schedule with new content? 
    // Awesome Notifications allows updating by ID.
    // If we want to strictly update the *scheduled* notification content:
    await scheduleWeeklySummary(TimeOfDay(hour: hour, minute: minute), body: content);
  }

  Future<void> cancelAll() async {
    await AwesomeNotifications().cancelAll();
  }
  
  Future<List<NotificationModel>> getPendingNotifications() async {
      return await AwesomeNotifications().listScheduledNotifications();
  }
  
  // Helpers
  Future<String> getCurrentTimezone() async {
     return await AwesomeNotifications().getLocalTimeZoneIdentifier();
  }

  Future<void> _scheduleDailyReminder() async {
    final box = await Hive.openBox('settings');
    final hour = box.get('daily_reminder_hour', defaultValue: 21);
    final minute = box.get('daily_reminder_minute', defaultValue: 0);
    await scheduleDailyReminder(TimeOfDay(hour: hour, minute: minute));
  }

  Future<void> _scheduleWeeklySummaryReminder() async {
    final box = await Hive.openBox('settings');
    final hour = box.get('weekly_reminder_hour', defaultValue: 20);
    final minute = box.get('weekly_reminder_minute', defaultValue: 0);
    await scheduleWeeklySummary(TimeOfDay(hour: hour, minute: minute));
  }
}
