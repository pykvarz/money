import 'package:flutter/material.dart';
import '../models/monthly_budget.dart';
import '../utils/currency_formatter.dart';
import '../theme/gradients.dart';

class SafeDailyBudgetCard extends StatelessWidget {
  final MonthlyBudget? budget;
  final double totalDisposable; // New parameter
  final double safeDailyBudget; // Restored
  final double currentBalance;
  final double todayExpense;
  final VoidCallback? onSetTarget;

  const SafeDailyBudgetCard({
    super.key,
    required this.budget,
    required this.safeDailyBudget,
    required this.totalDisposable, // Required
    required this.currentBalance,
    required this.todayExpense,
    this.onSetTarget,
  });

  @override
  Widget build(BuildContext context) {
    if (budget == null || budget!.targetRemainingBalance == null) {
      return _buildNoTargetCard(context);
    }
    
    // Status logic remains the same (based on daily health)
    // Or should it be based on total? 
    // Let's keep status as "Daily Spending Health" but show "Total Available" as the big number.
    // Status logic based on the Passed Safe Daily Budget (which now matches the displayed Total)
    final daysLeft = budget!.getDaysLeftInMonth();
    
    BudgetStatus status = BudgetStatus.neutral;
    if (safeDailyBudget > 0) {
      if (todayExpense <= safeDailyBudget * 0.8) {
        status = BudgetStatus.good;
      } else if (todayExpense <= safeDailyBudget) {
        status = BudgetStatus.warning;
      } else {
        status = BudgetStatus.danger;
      }
    } else {
       // If budget is 0 or negative
       status = todayExpense > 0 ? BudgetStatus.danger : BudgetStatus.warning;
    }

    return _buildStatusCard(
      context,
      mainValue: totalDisposable, // Show Total
      daysLeft: daysLeft,
      status: status,
      target: budget!.targetRemainingBalance!,
      key: const ValueKey('status_card'),
    );
  }

  Widget _buildNoTargetCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      key: const ValueKey('no_target_card'),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
               colorScheme.surfaceContainerHighest,
               colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isDark 
                ? Colors.white.withOpacity(0.1) 
                : Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'Установите целевой баланс',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'для включения умного планирования бюджета',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onSetTarget,
              icon: const Icon(Icons.flag),
              label: const Text('Установить цель'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context, {
    Key? key,
    required double mainValue,
    required int daysLeft,
    required BudgetStatus status,
    required double target,
  }) {
    return Card(
      key: key,
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: AppGradients.purpleBlue,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // Total Disposable amount
            Center(
              child: Column(
                children: [
                  Text(
                    CurrencyFormatter.formatKZTWithDecimals(mainValue),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'доступно до конца месяца',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailItem(
                  'Баланс',
                  CurrencyFormatter.formatKZT(currentBalance),
                  Colors.white,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildDetailItem(
                  'Цель',
                  CurrencyFormatter.formatKZT(target),
                  Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
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

  Map<String, Color> _getStatusColors(BuildContext context, BudgetStatus status) {
     final isDark = Theme.of(context).brightness == Brightness.dark;
     
    switch (status) {
      case BudgetStatus.good:
        return {
          'bg': isDark ? Colors.green[900]! : Colors.green[100]!,
          'bgLight': isDark ? Colors.green[800]! : Colors.green[50]!,
          'text': isDark ? Colors.green[100]! : Colors.green[900]!,
        };
      case BudgetStatus.warning:
        return {
          'bg': isDark ? Colors.amber[900]! : Colors.amber[100]!,
          'bgLight': isDark ? Colors.amber[800]! : Colors.amber[50]!,
          'text': isDark ? Colors.amber[100]! : Colors.amber[900]!,
        };
      case BudgetStatus.danger:
        return {
          'bg': isDark ? Colors.red[900]! : Colors.red[100]!,
          'bgLight': isDark ? Colors.red[800]! : Colors.red[50]!,
          'text': isDark ? Colors.red[100]! : Colors.red[900]!,
        };
      case BudgetStatus.neutral:
        return {
          'bg': isDark ? Colors.grey[800]! : Colors.grey[100]!,
          'bgLight': isDark ? Colors.grey[700]! : Colors.grey[50]!,
          'text': isDark ? Colors.grey[100]! : Colors.grey[800]!,
        };
    }
  }

  IconData _getStatusIcon(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.good:
        return Icons.check_circle;
      case BudgetStatus.warning:
        return Icons.warning;
      case BudgetStatus.danger:
        return Icons.error;
      case BudgetStatus.neutral:
        return Icons.info;
    }
  }

  String _getStatusMessage(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.good:
        return 'Отлично! Вы в рамках бюджета';
      case BudgetStatus.warning:
        return 'Внимание: следите за расходами';
      case BudgetStatus.danger:
        return 'Превышение бюджета!';
      case BudgetStatus.neutral:
        return 'Нейтрально';
    }
  }
}
