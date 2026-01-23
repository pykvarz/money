import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';

class MonthSummaryCard extends StatelessWidget {
  final double income;
  final double expense;
  final double balance;
  final double fixedExpenses; // New parameter

  const MonthSummaryCard({
    super.key,
    required this.income,
    required this.expense,
    required this.balance,
    this.fixedExpenses = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final gap = income - expense;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Сводка за месяц',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildRow(
              context,
              icon: Icons.arrow_downward,
              iconColor: Colors.green,
              label: 'Доходы',
              amount: income,
              amountColor: Colors.green[700]!,
            ),
            const SizedBox(height: 12),
            _buildRow(
              context,
              icon: Icons.arrow_upward,
              iconColor: Colors.red,
              label: 'Расходы',
              amount: expense,
              amountColor: Colors.red[700]!,
            ),
            const Divider(height: 24),
            _buildRow(
              context,
              icon: Icons.account_balance_wallet,
              iconColor: Colors.blue,
              label: 'Баланс',
              amount: balance,
              amountColor: balance >= 0 ? Colors.blue[700]! : Colors.red[700]!,
              isBold: true,
            ),
            const SizedBox(height: 8),
            _buildRow(
              context,
              icon: gap >= 0 ? Icons.trending_up : Icons.trending_down,
              iconColor: gap >= 0 ? Colors.green : Colors.red,
              label: 'Разница',
              amount: gap,
              amountColor: gap >= 0 ? Colors.green[700]! : Colors.red[700]!,
            ),
            
            if (fixedExpenses > 0) ...[
              const Divider(height: 24),
              _buildRow(
                context,
                icon: Icons.assignment_turned_in,
                iconColor: Colors.orange,
                label: 'Свободно (после счетов)',
                amount: balance - fixedExpenses,
                amountColor: (balance - fixedExpenses) >= 0 ? Colors.blue[800]! : Colors.red[800]!,
                isBold: true,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 32),
                child: Text(
                  'За вычетом ${CurrencyFormatter.formatKZT(fixedExpenses)} обязательных расходов',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required double amount,
    required Color amountColor,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          CurrencyFormatter.formatKZT(amount.abs()),
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: amountColor,
          ),
        ),
      ],
    );
  }
}
