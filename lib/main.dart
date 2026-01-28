import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:home_widget/home_widget.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'models/transaction.dart';
import 'models/category.dart';
import 'models/monthly_budget.dart';
import 'models/weekly_limit.dart';
import 'providers/expense_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'services/notification_service.dart';
import 'services/database_helper.dart';
import 'widgets/transaction_dialog.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive and DatabaseHelper (opens all boxes)
  await DatabaseHelper().init();

  final categoryBox = Hive.box<Category>('categories');
  final transactionBox = Hive.box<Transaction>('transactions');
  // boxes are already opened by init()

  // Initialize Notification Service
  await NotificationService().init(navigatorKey);
  
  // Request permissions (Android 13+)
  await NotificationService().requestPermission();

  // Create providers
  final expenseProvider = ExpenseProvider();
  final budgetProvider = BudgetProvider();
  final themeProvider = ThemeProvider();

  // Sync data to SQLite for analytics
  await DatabaseHelper.syncFromHiveToSqlite(categoryBox, transactionBox);

  // Check budget status periodically or on app start
  budgetProvider.checkBudgetStatus(expenseProvider);

  // Initialize date formatting
  await initializeDateFormatting('ru', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: expenseProvider),
        ChangeNotifierProvider.value(value: budgetProvider),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const ExpenseBookApp(),
    ),
  );
}

class ExpenseBookApp extends StatelessWidget {
  const ExpenseBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Expense Book',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
             colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
             ),
          ),
          themeMode: themeProvider.themeMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English
            Locale('ru', ''), // Russian
          ],
          locale: const Locale('ru', ''), // Force Russian for now or from settings
          home: const MainNavigationScreen(),
          navigatorKey: navigatorKey, // Required for NotificationService navigation
        );
      },
    );
  }
}

// --- Quick Add Entry Point ---

@pragma('vm:entry-point')
void quickAddMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  // Initialize Hive consistently using DatabaseHelper
  await DatabaseHelper().init();

  // Get opened boxes
  final categoryBox = Hive.box<Category>('categories');
  final transactionBox = Hive.box<Transaction>('transactions');

  // Initialize providers
  final expenseProvider = ExpenseProvider();
  final budgetProvider = BudgetProvider();
  final themeProvider = ThemeProvider();

  // Sync with DB
  await DatabaseHelper.syncFromHiveToSqlite(categoryBox, transactionBox);

  // Get launch payload
  Uri? initialUri;
  try {
     initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
  } catch (e) {
     debugPrint('Error getting initial URI: $e');
  }

  String? initialCategoryId;
  if (initialUri != null && initialUri.scheme == 'expensebook' && initialUri.host == 'add_expense') {
      initialCategoryId = initialUri.queryParameters['categoryId'];
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: expenseProvider),
        ChangeNotifierProvider.value(value: budgetProvider),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: QuickAddApp(initialCategoryId: initialCategoryId),
    ),
  );
}

class QuickAddApp extends StatelessWidget {
  final String? initialCategoryId;

  const QuickAddApp({super.key, this.initialCategoryId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: QuickAddScreen(initialCategoryId: initialCategoryId),
    );
  }
}

class QuickAddScreen extends StatefulWidget {
  final String? initialCategoryId;
  
  const QuickAddScreen({super.key, this.initialCategoryId});

  @override
  State<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends State<QuickAddScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDialog();
    });
  }

  Future<void> _showDialog() async {
      final provider = context.read<ExpenseProvider>();
      
      await showDialog(
        context: context,
        barrierDismissible: true, // Allow clicking outside to close
        builder: (ctx) => TransactionDialog(
            categories: provider.categories,
            initialCategoryId: widget.initialCategoryId,
        ),
      ).then((result) async {
          if (result != null) {
              // Save
              if (result is Transaction) { // Ensure it is a transaction
                  await provider.addTransaction(result);
                  
                  // Also update SQL if needed
                   await DatabaseHelper.syncFromHiveToSqlite(
                       Hive.box<Category>('categories'), 
                       Hive.box<Transaction>('transactions')
                   );
              }
          }
          // Exit app
          SystemNavigator.pop();
      });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        backgroundColor: Colors.transparent,
        body: SizedBox.shrink(),
    );
  }
}
