import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';

class MonthSummaryCard extends StatelessWidget {
  final double income;
  final double expense;
  final double balance;
  final double fixedExpenses;
  final double reservedLimits;
  final Map<String, double>? limitsBreakdown; 
  final double limitsQuota; // New
  final double limitsSpent; // New
  final double target;      // New
  final bool showRollover;  // New
  final List<Map<String, dynamic>>? limitsPerformanceBreakdown; // New

  final int daysLeft;

  const MonthSummaryCard({
    super.key,
    required this.income,
    required this.expense,
    required this.balance,
    required this.daysLeft,
    this.fixedExpenses = 0.0,
    this.reservedLimits = 0.0,
    this.limitsBreakdown,
    this.limitsQuota = 0.0, // Default 0
    this.limitsSpent = 0.0, // Default 0
    this.target = 0.0,      // Default 0
    this.showRollover = true, // Default true
    this.limitsPerformanceBreakdown,
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
            // Days Left instead of Balance
            // Days Left row removed by user request
            const SizedBox(height: 8),
            _buildRow(
              context,
              icon: gap >= 0 ? Icons.trending_up : Icons.trending_down,
              iconColor: gap >= 0 ? Colors.green : Colors.red,
              label: 'Итог',
              amount: gap,
              amountColor: gap >= 0 ? Colors.green[700]! : Colors.red[700]!,
            ),
            
            if (fixedExpenses > 0 || reservedLimits > 0 || limitsQuota > 0) ...[
              const Divider(height: 24),
              // Limits Performance (New)
              if (limitsQuota > 0) ...[
                 Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Лимиты',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${CurrencyFormatter.formatKZT(limitsSpent)} / ${CurrencyFormatter.formatKZT(limitsQuota)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: limitsSpent > limitsQuota 
                            ? Colors.red 
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (limitsSpent / limitsQuota).clamp(0.0, 1.0),
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    color: limitsSpent > limitsQuota ? Colors.red : Colors.green,
                    minHeight: 6,
                  ),
                ),
                
                // Detailed Breakdown (New)
                if (limitsPerformanceBreakdown != null && limitsPerformanceBreakdown!.isNotEmpty) ...[
                   const SizedBox(height: 12),
                   ...limitsPerformanceBreakdown!.map((item) {
                     final spent = item['spent'] as double;
                     final quota = item['quota'] as double;
                     final color = item['color'] as Color? ?? Colors.grey;
                     final icon = item['icon'] as IconData? ?? Icons.category;
                     final name = item['name'] as String;
                     final ratio = (spent / quota).clamp(0.0, 1.0);
                     
                     return Padding(
                       padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Row(
                             children: [
                               Icon(icon, size: 16, color: color),
                               const SizedBox(width: 8),
                               Expanded(
                                 child: Text(
                                   name,
                                   style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                 ),
                               ),
                               Text(
                                 '${CurrencyFormatter.formatKZT(spent)} / ${CurrencyFormatter.formatKZT(quota)}',
                                 style: TextStyle(
                                   fontSize: 11,
                                   color: spent > quota ? Colors.red : Colors.grey[700],
                                   fontWeight: spent > quota ? FontWeight.bold : FontWeight.normal,
                                 ),
                               ),
                             ],
                           ),
                           const SizedBox(height: 4),
                           ClipRRect(
                             borderRadius: BorderRadius.circular(2),
                             child: LinearProgressIndicator(
                               value: ratio,
                               backgroundColor: color.withOpacity(0.1),
                               color: spent > quota ? Colors.red : color,
                               minHeight: 3,
                             ),
                           ),
                         ],
                       ),
                     );
                   }),
                ],

                const SizedBox(height: 16),
              ],

              if (fixedExpenses > 0)
                _buildRow(
                  context,
                  icon: Icons.assignment_turned_in,
                  iconColor: Colors.orange,
                  label: 'Обязательные расходы',
                  amount: fixedExpenses,
                  amountColor: Colors.orange[800]!,
                ),
                
               // Rollover / Savings (New)
               if (showRollover && balance > 0) ...[
                 const SizedBox(height: 12),
                 _buildRow(
                   context,
                   icon: Icons.savings,
                   iconColor: Colors.purple,
                   label: 'Переходит на след. месяц',
                   amount: (target > 0 && balance > target) ? (balance - target) : balance, 
                   amountColor: Colors.purple[700]!,
                   subtitle: target > 0 
                      ? 'Сверх цели (${CurrencyFormatter.formatCompact(target)})' 
                      : null,
                 ),
               ],
               
               // Target Status (If exists)
               if (target > 0) ...[
                  const SizedBox(height: 12),
                  _buildRow(
                    context,
                    icon: Icons.flag,
                    iconColor: Colors.blue,
                    label: 'Цель накоплений',
                    amount: target,
                    amountColor: Colors.blue[700]!,
                    subtitle: balance >= target ? 'Достигнута! 🎉' : 'Осталось: ${CurrencyFormatter.formatCompact(target - balance)}',
                  ),
               ],
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
    String? subtitle, // New
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Adjust colors for dark mode to ensure visibility
    final effectiveAmountColor = isDark 
        ? (amountColor == Colors.green[700] ? Colors.green[300]! : 
           amountColor == Colors.red[700] ? Colors.red[300]! : 
           amountColor == Colors.orange[800] ? Colors.orange[300]! :
           amountColor == Colors.purple[700] ? Colors.purple[300]! : 
           amountColor == Colors.blue[700] ? Colors.blue[300]! : amountColor)
        : amountColor;

    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isBold ? 16 : 14,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
        Text(
          CurrencyFormatter.formatKZT(amount.abs()),
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: effectiveAmountColor,
          ),
        ),
      ],
    );
  }
}
