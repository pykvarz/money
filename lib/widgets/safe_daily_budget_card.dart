import 'package:flutter/material.dart';
import '../models/monthly_budget.dart';
import '../utils/currency_formatter.dart';

class SafeDailyBudgetCard extends StatelessWidget {
  final MonthlyBudget? budget;
  final double currentBalance;
  final double todayExpense;
  final VoidCallback? onSetTarget;

  const SafeDailyBudgetCard({
    super.key,
    required this.budget,
    required this.currentBalance,
    required this.todayExpense,
    this.onSetTarget,
  });

  @override
  Widget build(BuildContext context) {
    // No target set
    if (budget == null || budget!.targetRemainingBalance == null) {
      return _buildNoTargetCard(context);
    }

    final safeDailyBudget = budget!.calculateSafeDailyBudget(currentBalance);
    final daysLeft = budget!.getDaysLeftInMonth();
    final status = budget!.getBudgetStatus(currentBalance, todayExpense);

    return _buildStatusCard(
      context,
      safeDailyBudget: safeDailyBudget,
      daysLeft: daysLeft,
      status: status,
      target: budget!.targetRemainingBalance!,
    );
  }

  Widget _buildNoTargetCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.grey[100]!, Colors.grey[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.info_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'Установите целевой баланс',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'для включения умного планирования бюджета',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
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
    required double safeDailyBudget,
    required int daysLeft,
    required BudgetStatus status,
    required double target,
  }) {
    final colors = _getStatusColors(status);
    final icon = _getStatusIcon(status);
    final message = _getStatusMessage(status);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [colors['bg']!, colors['bgLight']!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status header
            Row(
              children: [
                Icon(icon, color: colors['text'], size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors['text'],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Daily budget amount
            Center(
              child: Column(
                children: [
                  Text(
                    CurrencyFormatter.formatKZTWithDecimals(safeDailyBudget),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: colors['text'],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'безопасно потратить сегодня',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors['text']!.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailItem(
                  'Осталось дней',
                  daysLeft.toString(),
                  colors['text']!,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: colors['text']!.withOpacity(0.3),
                ),
                _buildDetailItem(
                  'Цель',
                  CurrencyFormatter.formatKZT(target),
                  colors['text']!,
                ),
              ],
            ),
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

  Map<String, Color> _getStatusColors(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.good:
        return {
          'bg': Colors.green[100]!,
          'bgLight': Colors.green[50]!,
          'text': Colors.green[900]!,
        };
      case BudgetStatus.warning:
        return {
          'bg': Colors.amber[100]!,
          'bgLight': Colors.amber[50]!,
          'text': Colors.amber[900]!,
        };
      case BudgetStatus.danger:
        return {
          'bg': Colors.red[100]!,
          'bgLight': Colors.red[50]!,
          'text': Colors.red[900]!,
        };
      case BudgetStatus.neutral:
        return {
          'bg': Colors.grey[100]!,
          'bgLight': Colors.grey[50]!,
          'text': Colors.grey[800]!,
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
