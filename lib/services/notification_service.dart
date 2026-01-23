import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import '../widgets/transaction_dialog.dart';
import '../providers/expense_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  GlobalKey<NavigatorState>? _navigatorKey;

  Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;
    
    // Initialize locale data for formatting
    await initializeDateFormatting('ru', null);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationTap();
      },
    );
    
    // Check if app was launched by notification
    final launchDetails = await _notificationsPlugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      // Delay to allow app to build
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap();
      });
    }

    // Create channel for persistent status
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'weekly_status_channel',
      'Weekly Status',
      description: 'Shows ongoing weekly spending summary',
      importance: Importance.low, // Low importance to avoid sound/vibration spam
      playSound: false,
      enableVibration: false,
      showBadge: false,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request permission (Android 13+)
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

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

  Future<void> showWeeklySummary({
    required List<Map<String, dynamic>> items, // [{name, spent, limit, isOver}]
    required double totalSpent,
    required double totalLimit,
    required String currency,
  }) async {
    if (items.isEmpty) {
      await _notificationsPlugin.cancel(888);
      return;
    }

    // Format dates for title
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final dateFormat = DateFormat('d MMM', 'ru');
    final dateRange = '${dateFormat.format(monday)} - ${dateFormat.format(sunday)}';

    String title;
    String contentText;
    String summaryText;

    if (items.length == 1) {
      // Single category mode
      final item = items.first;
      final name = item['name'];
      final spent = (item['spent'] as double).toInt();
      final limit = (item['limit'] as double).toInt();
      final remaining = limit - spent;
      final isOver = item['spent'] > item['limit'];

      title = '$name: $dateRange';
      if (isOver) {
        contentText = '⚠️ Превышение на ${(spent - limit)} $currency!';
        summaryText = 'Лимит: $limit | Потрачено: $spent';
      } else {
        contentText = 'Осталось: $remaining $currency';
        summaryText = 'Лимит: $limit | Потрачено: $spent';
      }
    } else {
      // Multiple categories mode
      title = 'Неделя: $dateRange';
      
      final buffer = StringBuffer();
      for (var item in items) {
        final name = item['name'];
        final spent = (item['spent'] as double).toInt();
        final limit = (item['limit'] as double).toInt();
        final isOver = item['spent'] > item['limit'];
        
        final icon = isOver ? '⚠️' : (spent / limit > 0.8 ? '🟡' : '🟢');
        buffer.writeln('$icon $name: $spent / $limit');
      }
      
      contentText = buffer.toString().trim();
      summaryText = 'Всего: ${totalSpent.toInt()} / ${totalLimit.toInt()}';
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'weekly_status_channel',
      'Weekly Status',
      channelDescription: 'Shows ongoing weekly spending summary',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      enableVibration: false,
      playSound: false,
      styleInformation: BigTextStyleInformation(
        contentText,
        contentTitle: title,
        summaryText: summaryText,
      ),
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      888,
      title,
      contentText,
      details,
    );
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
