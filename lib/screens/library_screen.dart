import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/monthly_budget.dart';
import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';
import 'settings_screen.dart';
import '../services/database_helper.dart';
import '../utils/currency_formatter.dart';
import '../widgets/month_summary_card.dart'; // Import

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Архив месяцев'),
        centerTitle: true,
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
      body: FutureBuilder<List<MonthlyBudget>>(
        future: _loadAllBudgets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Ошибка загрузки: ${snapshot.error}'),
                ],
              ),
            );
          }

          final budgets = snapshot.data ?? [];
          
          if (budgets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Нет сохраненных месяцев',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'История появится после добавления транзакций',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          // Sort by date descending (newest first)
          budgets.sort((a, b) {
            final dateA = DateTime(a.year, a.month);
            final dateB = DateTime(b.year, b.month);
            return dateB.compareTo(dateA);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: budgets.length,
            itemBuilder: (context, index) {
              final budget = budgets[index];
              final isCurrentMonth = budget.month == DateTime.now().month &&
                  budget.year == DateTime.now().year;

              return MonthBudgetCard(
                budget: budget,
                isCurrentMonth: isCurrentMonth,
                onTap: () => _navigateToMonthDetails(context, budget),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<MonthlyBudget>> _loadAllBudgets() async {
    final db = DatabaseHelper();
    return db.getAllMonthlyBudgets();
  }

  void _navigateToMonthDetails(BuildContext context, MonthlyBudget budget) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MonthDetailScreen(budget: budget),
      ),
    );
  }
}

class MonthBudgetCard extends StatelessWidget {
  final MonthlyBudget budget;
  final bool isCurrentMonth;
  final VoidCallback onTap;

  const MonthBudgetCard({
    super.key,
    required this.budget,
    required this.isCurrentMonth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final db = DatabaseHelper();
    final totalIncome = db.getTotalIncomeForMonth(budget.month, budget.year);
    final totalExpense = db.getTotalExpenseForMonth(budget.month, budget.year);
    final balance = budget.initialBalance + totalIncome - totalExpense;
    final gap = balance - (budget.targetRemainingBalance ?? 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isCurrentMonth ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrentMonth
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        color: isCurrentMonth
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        CurrencyFormatter.formatMonthYear(
                          budget.month,
                          budget.year,
                        ),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isCurrentMonth
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    ],
                  ),
                  if (isCurrentMonth)
                    Chip(
                      label: const Text('Текущий'),
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),

              // Removed stats and goal rows as per user request
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// Detailed view for a specific month
class MonthDetailScreen extends StatelessWidget {
  final MonthlyBudget budget;

  const MonthDetailScreen({super.key, required this.budget});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseHelper();
    final transactions = db.getTransactionsForMonth(budget.month, budget.year);
    final totalIncome = db.getTotalIncomeForMonth(budget.month, budget.year);
    final totalExpense = db.getTotalExpenseForMonth(budget.month, budget.year);
    final balance = budget.initialBalance + totalIncome - totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          CurrencyFormatter.formatMonthYear(budget.month, budget.year),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary Card
          // Summary Card
          Consumer2<ExpenseProvider, BudgetProvider>(
            builder: (context, expenseProvider, budgetProvider, _) {
              final limitsStats = budgetProvider.getLimitsStatsForMonth(budget.month, budget.year, expenseProvider);
              final limitsQuota = limitsStats['quota'] as double;
              final limitsSpent = limitsStats['spent'] as double;
              final breakdown = limitsStats['breakdown'] as List<Map<String, dynamic>>?;
              
              return MonthSummaryCard(
                income: totalIncome,
                expense: totalExpense,
                balance: balance,
                daysLeft: 0, // Past month
                fixedExpenses: budget.projectedFixedExpenses,
                target: budget.targetRemainingBalance ?? 0.0,
                limitsQuota: limitsQuota,
                limitsSpent: limitsSpent,
                limitsPerformanceBreakdown: breakdown,
              );
            },
          ),
          const SizedBox(height: 16),

          // Transactions
          Text(
            'Транзакции (${transactions.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          if (transactions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Нет транзакций'),
              ),
            )
          else
            ...transactions.map((txn) {
              final category = db.getCategoryById(txn.categoryId);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: category?.color.withOpacity(0.2),
                    child: Icon(category?.icon, color: category?.color),
                  ),
                  title: Text(category?.name ?? 'Unknown'),
                  subtitle: Text(
                    CurrencyFormatter.formatDate(txn.date),
                  ),
                  trailing: Text(
                    '${txn.type.name == 'income' ? '+' : '-'}${CurrencyFormatter.formatKZT(txn.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: txn.type.name == 'income' ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          CurrencyFormatter.formatKZT(value),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
