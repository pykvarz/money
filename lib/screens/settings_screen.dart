import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/weekly_limit.dart';
import '../models/fixed_expense.dart';
import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/weekly_limit_card.dart';
import '../widgets/fixed_expense_dialog.dart';
import '../services/database_helper.dart';
import '../utils/currency_formatter.dart';
import 'categories_screen.dart';
import 'limits_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, budgetProvider, _) {
          final budget = budgetProvider.currentBudget;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Target Balance Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flag, color: Colors.deepPurple),
                          const SizedBox(width: 8),
                          Text(
                            'Целевой баланс',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (budget?.targetRemainingBalance != null)
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Текущая цель:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.formatKZT(
                                    budget!.targetRemainingBalance!,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Безопасный дневной бюджет:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.formatKZTWithDecimals(
                                    budgetProvider.getSafeDailyBudget(),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Цель не установлена',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      FilledButton.icon(
                        onPressed: () => _showSetTargetDialog(context, budgetProvider),
                        icon: const Icon(Icons.edit),
                        label: Text(
                          budget?.targetRemainingBalance != null
                              ? 'Изменить цель'
                              : 'Установить цель',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Initial Balance Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Начальный баланс',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Баланс на начало месяца:',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatKZT(
                              budget?.initialBalance ?? 0,
                            ),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () =>
                            _showSetInitialBalanceDialog(context, budgetProvider),
                        icon: const Icon(Icons.edit),
                        label: const Text('Изменить начальный баланс'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Categories Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.category, color: Colors.purple),
                  title: const Text('Категории'),
                  subtitle: const Text('Управление категориями расходов и доходов'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Limits Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.speed, color: Colors.orange),
                  title: const Text('Лимиты трат'),
                  subtitle: const Text('Недельные и месячные лимиты'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LimitsScreen()),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Fixed Expenses Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.receipt_long, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Обязательные расходы',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Регулярные ежемесячные платежи (аренда, коммуналка, подписки)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _showFixedExpenseDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Добавить расход'),
                      ),
                      FutureBuilder<List<FixedExpense>>(
                        future: _loadFixedExpenses(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          
                          final expenses = snapshot.data!;
                          final total = expenses.fold(0.0, (sum, e) => sum + e.amount);
                          
                          return Column(
                            children: [
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Итого в месяц:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red.shade900,
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.formatKZT(total),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 24),
                              ...expenses.map((expense) {
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.receipt,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(expense.name),
                                  subtitle: const Text('Оплата: 1 число каждого месяца'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        CurrencyFormatter.formatKZT(expense.amount),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () => _showFixedExpenseDialog(
                                          context,
                                          existingExpense: expense,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => _deleteFixedExpense(context, expense.id),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Info Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Установите целевой баланс для активации умного планирования бюджета',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // App Info
              Center(
                child: Column(
                  children: [
                    Text(
                      'ExpenseBook',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Версия 1.0.0',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyFormatter.formatMonthYear(
                        budget?.month ?? DateTime.now().month,
                        budget?.year ?? DateTime.now().year,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showSetTargetDialog(
    BuildContext context,
    BudgetProvider provider,
  ) async {
    final controller = TextEditingController(
      text: provider.currentBudget?.targetRemainingBalance?.toString() ?? '',
    );

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Установить целевой баланс'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Укажите сумму, которую хотите сохранить к концу месяца',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Целевой остаток',
                suffixText: 'KZT',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag),
              ),
            ),
          ],
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

  Future<void> _showSetInitialBalanceDialog(
    BuildContext context,
    BudgetProvider provider,
  ) async {
    final controller = TextEditingController(
      text: provider.currentBudget?.initialBalance.toString() ?? '0',
    );

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Установить начальный баланс'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Укажите баланс на начало текущего месяца',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Начальный баланс',
                suffixText: 'KZT',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance_wallet),
              ),
            ),
          ],
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
      await provider.updateInitialBalance(result);
    }

    controller.dispose();
  }

  Future<void> _showWeeklyLimitDialog(
    BuildContext context,
    BudgetProvider budgetProvider, {
    WeeklyLimit? existingLimit,
  }) async {
    final expenseProvider = context.read<ExpenseProvider>();
    final result = await showDialog<WeeklyLimit>(
      context: context,
      builder: (context) => WeeklyLimitDialog(
        categories: expenseProvider.categories,
        existingLimit: existingLimit,
      ),
    );

    if (result != null) {
      await budgetProvider.setWeeklyLimit(result);
    }
  }

  Future<void> _deleteWeeklyLimit(
    BuildContext context,
    BudgetProvider provider,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить лимит?'),
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
      await provider.deleteWeeklyLimit(id);
    }
  }

  Future<List<FixedExpense>> _loadFixedExpenses() async {
    final db = DatabaseHelper();
    return db.getAllFixedExpenses();
  }

  Future<void> _showFixedExpenseDialog(
    BuildContext context, {
    FixedExpense? existingExpense,
  }) async {
    final result = await showDialog<FixedExpense>(
      context: context,
      builder: (context) => FixedExpenseDialog(
        existingExpense: existingExpense,
      ),
    );

    if (result != null) {
      // Use Provider to ensure UI updates via notifyListeners
      if (context.mounted) {
        final provider = Provider.of<BudgetProvider>(context, listen: false);
        if (existingExpense != null) {
           await provider.updateFixedExpense(result);
        } else {
           await provider.addFixedExpense(result);
        }
      }
    }
  }

  Future<void> _deleteFixedExpense(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить расход?'),
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

    if (confirmed == true && context.mounted) {
      final provider = Provider.of<BudgetProvider>(context, listen: false);
      await provider.deleteFixedExpense(id);
    }
  }
}
