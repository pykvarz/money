import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';
import 'settings_screen.dart';
import '../widgets/safe_daily_budget_card.dart';
import '../widgets/month_summary_card.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/transaction_dialog.dart';
import '../widgets/weekly_limit_card.dart';
import '../widgets/savings_accumulator_card.dart';
import '../widgets/savings_accumulator_card.dart';
import '../utils/currency_formatter.dart';
import '../utils/currency_formatter.dart';
import 'history_screen.dart';
import '../widgets/quick_add_widget.dart';
import '../widgets/budget_limit_card.dart';
import 'package:home_widget/home_widget.dart';
import '../theme/app_design.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh notification coverage on launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final expense = context.read<ExpenseProvider>();
        context.read<BudgetProvider>().checkBudgetStatus(expense);
      }
      _checkForWidgetLaunch();
    });
  }

  void _checkForWidgetLaunch() {
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetLaunch);
    HomeWidget.widgetClicked.listen(_handleWidgetLaunch);
  }

  void _handleWidgetLaunch(Uri? uri) {
    if (uri != null && uri.scheme == 'expensebook' && uri.host == 'add_expense') {
      final categoryId = uri.queryParameters['categoryId'];
      // Wait for providers to be ready if needed, or just show dialog
      if (mounted) {
         // Add a small delay to ensure UI is ready if coming from cold start
         Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
                final provider = context.read<ExpenseProvider>();
                // Ensure data is loaded? It usually is by proper provider init.
                _showTransactionDialog(context, provider, preselectedCategoryId: categoryId);
            }
         });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<ExpenseProvider>(
          builder: (context, expenseProvider, _) {
            return Text(
              CurrencyFormatter.formatMonthYear(
                expenseProvider.currentMonth,
                expenseProvider.currentYear,
              ),
            );
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer2<ExpenseProvider, BudgetProvider>(
        builder: (context, expenseProvider, budgetProvider, _) {
          
          final currentBalance = budgetProvider.getEffectiveBalance(expenseProvider);
          final todayExpense = _getTodayExpense(expenseProvider);

          return RefreshIndicator(
            onRefresh: () async {
              await expenseProvider.loadData();
              await budgetProvider.loadCurrentBudget();
            },
            child: ListView(
              padding: const EdgeInsets.all(AppDesign.paddingM),
              children: [
                // Safe Daily Budget Card
                SafeDailyBudgetCard(
                  budget: budgetProvider.currentBudget,
                  safeDailyBudget: (budgetProvider.currentBudget?.getDaysLeftInMonth() ?? 0) > 0 
                      ? currentBalance / (budgetProvider.currentBudget!.getDaysLeftInMonth()) 
                      : 0.0,
                  totalDisposable: currentBalance, // Pass Total (User: don't subtract target)
                  currentBalance: currentBalance,
                  todayExpense: todayExpense,
                  onSetTarget: () => _showSetTargetDialog(budgetProvider),
                ),
                const SizedBox(height: AppDesign.paddingM),

                // Savings Accumulator Card
                // Savings Accumulator Card
                SavingsAccumulatorCard(
                  weeklySavings: budgetProvider.getWeeklySavingsThisMonth(expenseProvider),
                  totalPiggyBank: budgetProvider.getAllTimePiggyBankSavings(),
                ),
                const SizedBox(height: AppDesign.paddingM),

                  // Month Summary
                MonthSummaryCard(
                  income: expenseProvider.getTotalIncome(),
                  expense: expenseProvider.getTotalExpense(),
                  balance: currentBalance,
                  daysLeft: budgetProvider.currentBudget?.getDaysLeftInMonth() ?? 0, // Pass Days Left
                  fixedExpenses: budgetProvider.getTotalFixedExpenses(),
                  reservedLimits: budgetProvider.getTotalLimitsQuota(),
                  limitsBreakdown: budgetProvider.getReservedLimitsBreakdown(expenseProvider),
                  limitsQuota: budgetProvider.getTotalLimitsQuota(), // Restore
                  limitsSpent: budgetProvider.getTotalLimitsSpent(expenseProvider), // Restore
                  showRollover: false, // Hide on Home Screen
                ),
                const SizedBox(height: 16),

                // Weekly Limits Progress
                if (budgetProvider.weeklyLimits.where((l) => l.isActive && l.isCurrentWeek()).isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Недельные лимиты',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...budgetProvider.weeklyLimits
                      .where((limit) => limit.isActive && limit.isCurrentWeek())
                      .map((limit) {
                    final category = expenseProvider.getCategoryById(limit.categoryId);
                    
                    if (category == null) {
                       return const SizedBox.shrink();
                    }

                    // Correct spending for the portion of the week in the current month
                    final spending = expenseProvider.getWeeklySpendingInMonth(
                      limit.categoryId, 
                      limit.weekStartDate, 
                      expenseProvider.currentMonth, 
                      expenseProvider.currentYear
                    );

                    final effectiveLimit = limit.getEffectiveLimit(
                      expenseProvider.currentMonth, 
                      expenseProvider.currentYear
                    );

                    final dates = limit.getEffectiveDates(
                      expenseProvider.currentMonth, 
                      expenseProvider.currentYear
                    );
                    
                    return BudgetLimitCard(
                      categoryName: category.name,
                      icon: IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                      color: Color(category.colorValue),
                      spent: spending,
                      limit: effectiveLimit,
                      startDate: dates['start']!,
                      endDate: dates['end']!,
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                ],

                // MONTHLY LIMITS SECTION
                if (budgetProvider.monthlyLimits.where((l) => l.isActive).isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Месячные лимиты',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...budgetProvider.monthlyLimits
                      .where((limit) => limit.isActive)
                      .map((limit) {
                    final category = expenseProvider.getCategoryById(limit.categoryId);
                    
                    if (category == null) {
                       return const SizedBox.shrink();
                    }

                    final spending = budgetProvider.getMonthlySpending(limit.categoryId);
                    
                    // Month start and end
                    final now = DateTime.now();
                    final monthStart = DateTime(now.year, now.month, 1);
                    final monthEnd = DateTime(now.year, now.month + 1, 0);

                    return BudgetLimitCard(
                      categoryName: category.name,
                      icon: IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                      color: Color(category.colorValue),
                      spent: spending,
                      limit: limit.limitAmount,
                      startDate: monthStart,
                      endDate: monthEnd,
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                ],

                // Quick Add Templates
                const QuickAddWidget(),
                const SizedBox(height: 16),

                // Recent Transactions Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Недавние транзакции',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (expenseProvider.transactions.length > 10)
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HistoryScreen(),
                            ),
                          );
                        },
                        child: const Text('Все'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Transactions List
                if (expenseProvider.transactions.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Нет транзакций',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Нажмите + чтобы добавить',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...expenseProvider.transactions
                      .take(10)
                      .map((transaction) {
                    final category =
                        expenseProvider.getCategoryById(transaction.categoryId);
                    return TransactionListItem(
                      transaction: transaction,
                      category: category,
                      onTap: () => _showTransactionDialog(
                        context,
                        expenseProvider,
                        transaction: transaction,
                      ),
                      onDelete: () => _deleteTransaction(
                        expenseProvider,
                        transaction.id,
                      ),
                    );
                  }).toList(),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTransactionDialog(
          context,
          context.read<ExpenseProvider>(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Транзакция'),
      ),
    );
  }

  double _getTodayExpense(ExpenseProvider provider) {
    final today = DateTime.now();
    return provider.transactions
        .where((txn) =>
            txn.type == TransactionType.expense &&
            txn.date.year == today.year &&
            txn.date.month == today.month &&
            txn.date.day == today.day)
        .fold(0.0, (sum, txn) => sum + txn.amount);
  }

  Future<void> _showTransactionDialog(
    BuildContext context,
    ExpenseProvider provider, {
    Transaction? transaction,
    String? preselectedCategoryId,
  }) async {
    final result = await showDialog<Transaction>(
      context: context,
      builder: (context) => TransactionDialog(
        categories: provider.categories,
        transaction: transaction,
        initialCategoryId: preselectedCategoryId,
      ),
    );

    if (result != null) {
      if (transaction == null) {
        await provider.addTransaction(result);
      } else {
        await provider.updateTransaction(result);
      }
      // Update notifications
      if (context.mounted) {
        context.read<BudgetProvider>().checkBudgetStatus(provider);
      }
    }
  }

  Future<void> _deleteTransaction(ExpenseProvider provider, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить транзакцию?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.deleteTransaction(id);
      if (mounted) {
        context.read<BudgetProvider>().checkBudgetStatus(provider);
      }
    }
  }

  Future<void> _showSetTargetDialog(BudgetProvider provider) async {
    final controller = TextEditingController(
      text: provider.currentBudget?.targetRemainingBalance?.toString() ?? '',
    );

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Установить цель'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Целевой остаток',
            suffixText: '₸',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              Navigator.pop(context, value);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result != null) {
      await provider.updateTargetBalance(result);
    }

    controller.dispose();
  }
}
