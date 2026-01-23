import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';
import '../widgets/safe_daily_budget_card.dart';
import '../widgets/month_summary_card.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/transaction_dialog.dart';
import '../widgets/weekly_limit_card.dart';
import '../widgets/savings_accumulator_card.dart';
import '../utils/currency_formatter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer2<ExpenseProvider, BudgetProvider>(
        builder: (context, expenseProvider, budgetProvider, _) {
          // Update notification whenever data changes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            budgetProvider.updateWeeklyNotification(expenseProvider);
          });

          final currentBalance = budgetProvider.getCurrentBalance();
          final todayExpense = _getTodayExpense(expenseProvider);

          return RefreshIndicator(
            onRefresh: () async {
              await expenseProvider.loadData();
              await budgetProvider.loadCurrentBudget();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Safe Daily Budget Card
                SafeDailyBudgetCard(
                  budget: budgetProvider.currentBudget,
                  currentBalance: currentBalance,
                  todayExpense: todayExpense,
                  onSetTarget: () => _showSetTargetDialog(budgetProvider),
                ),
                const SizedBox(height: 16),

                // Savings Accumulator Card
                SavingsAccumulatorCard(
                  totalSavings: budgetProvider.getTotalSavingsThisMonth(expenseProvider),
                ),
                const SizedBox(height: 16),

                // Month Summary
                MonthSummaryCard(
                  income: expenseProvider.getTotalIncome(),
                  expense: expenseProvider.getTotalExpense(),
                  balance: currentBalance,
                  fixedExpenses: budgetProvider.getTotalFixedExpenses(),
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
                    final spending = expenseProvider.getCurrentWeekSpending(limit.categoryId);
                    return WeeklyLimitProgressCard(
                      limit: limit,
                      category: category,
                      currentSpending: spending,
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                ],

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
                          // TODO: Navigate to all transactions
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
  }) async {
    final result = await showDialog<Transaction>(
      context: context,
      builder: (context) => TransactionDialog(
        categories: provider.categories,
        transaction: transaction,
      ),
    );

    if (result != null) {
      if (transaction == null) {
        await provider.addTransaction(result);
      } else {
        await provider.updateTransaction(result);
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
            suffixText: 'KZT',
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
