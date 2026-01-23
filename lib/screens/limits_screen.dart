import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';
import '../models/weekly_limit.dart';
import '../models/monthly_limit.dart';
import '../widgets/weekly_limit_card.dart';
import '../widgets/monthly_limit_card.dart';

class LimitsScreen extends StatelessWidget {
  const LimitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Лимиты трат'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'На неделю'),
              Tab(text: 'На месяц'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            WeeklyLimitsTab(),
            MonthlyLimitsTab(),
          ],
        ),
      ),
    );
  }
}

class WeeklyLimitsTab extends StatelessWidget {
  const WeeklyLimitsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showWeeklyLimitDialog(context),
        heroTag: 'weekly_fab',
        child: const Icon(Icons.add),
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, budgetProvider, child) {
          final limits = budgetProvider.weeklyLimits;
          final expenseProvider = Provider.of<ExpenseProvider>(context);

          if (limits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_view_week, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Нет недельных лимитов',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80, top: 16),
            itemCount: limits.length,
            itemBuilder: (context, index) {
              final limit = limits[index];
              final category = expenseProvider.getCategoryById(limit.categoryId);
              
              // Calculate spending for this limit's week (needs logic from provider if complex, but simple version here)
              // Actually we need BudgetProvider to give us the spending because it knows the week start
              // But we don't have a public method in BudgetProvider exposed for "spending for checking limits" cleanly
              // Wait, we have _getSpendingForWeek in BudgetProvider but it's private.
              // Let's rely on ExpenseProvider to calculate current week.
              // Or better, add helper in BudgetProvider.
              // We added `getCurrentWeekSpending(categoryId)` to ExpenseProvider earlier!
              
              final spending = expenseProvider.getCurrentWeekSpending(limit.categoryId);

              return Dismissible(
                key: Key(limit.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) => _confirmDelete(context),
                onDismissed: (_) {
                  budgetProvider.deleteWeeklyLimit(limit.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Лимит удален')),
                  );
                },
                child: WeeklyLimitProgressCard(
                  limit: limit,
                  category: category,
                  currentSpending: spending,
                  onTap: () => _showWeeklyLimitDialog(context, existingLimit: limit),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showWeeklyLimitDialog(BuildContext context, {WeeklyLimit? existingLimit}) async {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

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

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить лимит?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
        ],
      ),
    ) ?? false;
  }
}

class MonthlyLimitsTab extends StatelessWidget {
  const MonthlyLimitsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMonthlyLimitDialog(context),
        heroTag: 'monthly_fab',
        child: const Icon(Icons.add),
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, budgetProvider, child) {
          final limits = budgetProvider.monthlyLimits;
          final expenseProvider = Provider.of<ExpenseProvider>(context);

          if (limits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Нет месячных лимитов',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80, top: 16),
            itemCount: limits.length,
            itemBuilder: (context, index) {
              final limit = limits[index];
              final category = expenseProvider.getCategoryById(limit.categoryId);
              
              // Helper we added to BudgetProvider
              final spending = budgetProvider.getMonthlySpending(limit.categoryId);

              return Dismissible(
                key: Key(limit.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) => _confirmDelete(context),
                onDismissed: (_) {
                  budgetProvider.deleteMonthlyLimit(limit.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Лимит удален')),
                  );
                },
                child: MonthlyLimitCard(
                  limit: limit,
                  category: category,
                  currentSpending: spending,
                  onTap: () => _showMonthlyLimitDialog(context, existingLimit: limit),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showMonthlyLimitDialog(BuildContext context, {MonthlyLimit? existingLimit}) async {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

    final result = await showDialog<MonthlyLimit>(
      context: context,
      builder: (context) => MonthlyLimitDialog(
        categories: expenseProvider.categories,
        existingLimit: existingLimit,
      ),
    );

    if (result != null) {
      await budgetProvider.setMonthlyLimit(result);
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить лимит?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
        ],
      ),
    ) ?? false;
  }
}
