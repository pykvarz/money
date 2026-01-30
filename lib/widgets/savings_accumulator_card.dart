import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';
import '../theme/gradients.dart';

class SavingsAccumulatorCard extends StatelessWidget {
  final double weeklySavings;
  final double totalPiggyBank;

  const SavingsAccumulatorCard({
    super.key,
    required this.weeklySavings,
    required this.totalPiggyBank,
  });

  @override
  Widget build(BuildContext context) {
    if (weeklySavings <= 0 && totalPiggyBank <= 0) {
      return const SizedBox.shrink(); 
    }

    return Card(
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: AppGradients.greenEmerald,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Row 1: Piggy Bank (Total)
            if (totalPiggyBank > 0) ...[
              Row(
                children: [
                  const Icon(Icons.savings, color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Моя Копилка',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatKZT(totalPiggyBank),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (weeklySavings > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: Colors.white.withOpacity(0.3), height: 1),
                ),
            ],

            // Row 2: Weekly Savings (Current Month Potential)
            if (weeklySavings > 0)
              Row(
                children: [
                   Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.trending_up, color: Colors.white, size: 20),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           'Экономия на лимитах (в этом мес.)',
                           style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                         ),
                         Text(
                           '+ ${CurrencyFormatter.formatKZT(weeklySavings)}',
                           style: const TextStyle(
                             color: Colors.white, 
                             fontSize: 16, 
                             fontWeight: FontWeight.w600,
                           ),
                         ),
                       ],
                     ),
                   )
                ],
              ),
          ],
        ),
      ),
    );
  }
}
