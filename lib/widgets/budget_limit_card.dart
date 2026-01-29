import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BudgetLimitCard extends StatelessWidget {
  final String categoryName;
  final IconData icon;
  final Color color;
  final double spent;
  final double limit;
  final DateTime startDate;
  final DateTime endDate;

  const BudgetLimitCard({
    super.key,
    required this.categoryName,
    required this.icon,
    required this.color,
    required this.spent,
    required this.limit,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = limit > 0 ? (spent / limit * 100).clamp(0, 100) : 0.0;
    final remaining = limit - spent;
    final dateFormat = DateFormat('d MMM', 'ru');

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${spent.toInt()} / ${limit.toInt()}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      remaining >= 0 ? 'Осталось ${remaining.toInt()}' : 'Превышение ${(-remaining).toInt()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: remaining >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage >= 100 ? Colors.red : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
