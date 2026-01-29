import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../utils/currency_formatter.dart';
import 'category_icon_circle.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final Category? category;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionListItem({
    super.key,
    required this.transaction,
    this.category,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (onDelete != null) {
          onDelete!();
        }
        return false; // Let parent handle deletion to avoid premature UI removal
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          onTap: onTap,
          leading: CategoryIconCircle(
            icon: category?.icon ?? Icons.question_mark,
            color: category?.color ?? Theme.of(context).colorScheme.primary,
            size: 48,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  category?.name ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${isIncome ? '+' : '-'}${CurrencyFormatter.formatKZT(transaction.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isIncome ? Colors.green[700] : Colors.red[700],
                  fontSize: 16,
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (transaction.note != null && transaction.note!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    transaction.note!,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  CurrencyFormatter.formatDate(transaction.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
