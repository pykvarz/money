import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../widgets/transaction_dialog.dart';
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  GlobalKey<NavigatorState>? _navigatorKey;

  // Channel constants
  static const String basicChannelKey = 'reminders_v3';
  static const String statusChannelKey = 'weekly_status';

  Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;

    await AwesomeNotifications().initialize(
      null, // Use default app icon
      [
        // 1. Basic Channel
        NotificationChannel(
          channelKey: basicChannelKey,
          channelName: 'Reminders',
          channelDescription: 'Daily and weekly reminders',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
        // 2. Status Channel (The "Widget")
        NotificationChannel(
          channelKey: statusChannelKey,
          channelName: 'Weekly Status',
          channelDescription: 'Ongoing weekly summary',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.Low, // Low importance to be less intrusive but persistent
          channelShowBadge: false,
          playSound: false,
          enableVibration: false,
          locked: true, 
          onlyAlertOnce: true,
        )
      ],
      debug: true,
    );
    
    // Clear only specific reminders if needed
    // await AwesomeNotifications().cancelAll(); 

    await AwesomeNotifications().setListeners(
        onActionReceivedMethod: onActionReceivedMethod,
        onNotificationCreatedMethod: onNotificationCreatedMethod,
        onNotificationDisplayedMethod: onNotificationDisplayedMethod,
        onDismissActionReceivedMethod: onDismissActionReceivedMethod);
        
    await _scheduleDailyReminder();
    await _scheduleWeeklySummaryReminder();
  }

  Future<void> checkInitialLaunch() async {
    final ReceivedAction? initialAction = await AwesomeNotifications()
        .getInitialNotificationAction(removeFromActionEvents: true);
        
    if (initialAction != null) {
       _handleNotificationTap(initialAction.buttonKeyPressed, initialAction.payload);
    }
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    final service = NotificationService();
    if (service._navigatorKey?.currentState?.context != null) {
         service._handleNotificationTap(receivedAction.buttonKeyPressed, receivedAction.payload);
    }
  }

  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {}

  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {}

  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
      // Logic to recreate if dismissed?
      if (receivedAction.id == 888) {
          // It was dismissed (shouldn't happen with locked: true)
      }
  }
  
  void _handleNotificationTap(String? buttonKey, Map<String, String?>? payload) {
    if (_navigatorKey?.currentState?.context != null) {
      if (buttonKey == 'ADD_TRANSACTION') {
        _showAddTransactionDialog(_navigatorKey!.currentState!.context);
      } else {
        // Handle widget tap - check for categoryId in payload
        if (payload != null && payload.containsKey('categoryId')) {
           final categoryId = payload['categoryId'];
           _showAddTransactionDialog(_navigatorKey!.currentState!.context, categoryId: categoryId);
        } else {
           // Default tap if no payload
        }
      }
    }
  }

  Future<void> _showAddTransactionDialog(BuildContext context, {String? categoryId}) async {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    
    // Find the category object if ID is provided
    Category? initialCategory;
    if (categoryId != null) {
      try {
        initialCategory = expenseProvider.categories.firstWhere((c) => c.id == categoryId);
      } catch (e) {
        // Category not found
      }
    }
    
    final result = await showDialog<Transaction>(
      context: context,
      builder: (context) => TransactionDialog(
        categories: expenseProvider.categories,
        initialCategoryId: categoryId, // Correct parameter name
      ),
    );

    if (result != null) {
      await expenseProvider.addTransaction(result);
      if (context.mounted) {
        Provider.of<BudgetProvider>(context, listen: false).checkBudgetStatus(expenseProvider);
      }
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
        channelKey: basicChannelKey,
        title: 'Не забудьте записать расходы!',
        body: 'Потратили что-то сегодня? Запишите, чтобы бюджет был точным.',
        category: NotificationCategory.Reminder,
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

  // Schedule Weekly Summary (Prompt)
  Future<void> scheduleWeeklySummary(TimeOfDay time, {String? body}) async {
    final content = body ?? 'Зайдите, чтобы узнать, сколько вы сэкономили на лимитах!';
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 102,
        channelKey: basicChannelKey,
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

  // Persistent Status "Widget" using AwesomeNotifications (Restoring from GitHub pattern)
  Future<void> showWeeklySummaryPersistent({
    required List<Map<String, dynamic>> weeklyItems,
    required List<Map<String, dynamic>> monthlyItems,
    required double totalSpent,
    required double totalLimit,
    String? weekRange,
  }) async {
      // Cancel aggregate summary (ID 888) if it exists, to avoid duplicates
      await AwesomeNotifications().cancel(888);

      final List<Map<String, dynamic>> allItems = [...weeklyItems, ...monthlyItems];

      if (allItems.isEmpty) {
          // If no limits, maybe show a placeholder or nothing? 
          // For now, doing nothing or cancelling old ones is safer.
          return;
      }

      for (var item in allItems) {
         final String name = item['name'];
         final double spent = item['spent'];
         final double limit = item['limit'];
         final String idStr = item['id'].toString();
         
         // Generate unique ID for notification
         final int notificationId = 2000 + (idStr.hashCode % 10000).abs();
         
         final percentage = limit > 0 ? (spent / limit * 100).clamp(0, 100).toDouble() : 0.0;
         final spentStr = spent.toInt().toString();
         final limitStr = limit.toInt().toString();
         
         // "Sum of sum" format requested: e.g. "17000 / 20000"
         // Title: Category: %
         String title = '$name: ${percentage.toInt()}%';
         // Date range removed as requested
         
         final bodyText = '$spentStr / $limitStr ₸';

         await AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: notificationId,
              channelKey: statusChannelKey,
              title: title,
              body: bodyText,
              summary: 'Лимиты',
              locked: true,
              autoDismissible: false,
              category: NotificationCategory.Progress,
              notificationLayout: NotificationLayout.ProgressBar,
              progress: percentage,
              showWhen: false,
              color: spent > limit ? Colors.red : const Color(0xFF9D50DD),
              payload: {'categoryId': idStr},
            ),
         );
      }
  }

  // Bridge for old API calls (can be refactored later)
  Future<void> showWeeklySummary({
    required List<Map<String, dynamic>> weeklyItems,
    required List<Map<String, dynamic>> monthlyItems,
    required double totalSpent,
    required double totalLimit,
    required String currency,
    String? weekRange,
  }) async {
      await showWeeklySummaryPersistent(
          weeklyItems: weeklyItems,
          monthlyItems: monthlyItems, 
          totalSpent: totalSpent, 
          totalLimit: totalLimit,
          weekRange: weekRange,
      );
  }

  // Wrapper for updating content (if needed by Settings)
  Future<void> updateWeeklySummaryContent(double spent, double limit) async {
  }

  // Cancel notification for a specific limit/category
  Future<void> cancelLimitNotification(String categoryId) async {
    // Generate the same notification ID that was used when creating it
    final int notificationId = 2000 + (categoryId.hashCode % 10000).abs();
    await AwesomeNotifications().cancel(notificationId);
  }

  Future<void> cancelAll() async {
    await AwesomeNotifications().cancelAll();
  }
  
  // Helpers
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
