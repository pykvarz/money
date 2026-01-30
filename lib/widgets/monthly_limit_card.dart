import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/monthly_limit.dart';
import '../models/category.dart' as models;
import '../utils/currency_formatter.dart';
import 'category_icon_circle.dart';
import 'animated_progress_bar.dart';

class MonthlyLimitCard extends StatelessWidget {
  final MonthlyLimit limit;
  final models.Category? category;
  final double currentSpending;
  final VoidCallback? onTap;

  const MonthlyLimitCard({
    super.key,
    required this.limit,
    this.category,
    required this.currentSpending,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (currentSpending / limit.limitAmount * 100).clamp(0, 100);
    final remaining = (limit.limitAmount - currentSpending).clamp(0.0, limit.limitAmount);
    final isOverLimit = currentSpending > limit.limitAmount;
    final isNearLimit = percentage >= 80 && !isOverLimit;

    Color progressColor;
    if (isOverLimit) {
      progressColor = Colors.red;
    } else if (isNearLimit) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (category != null)
                    CategoryIconCircle(
                      icon: category!.icon,
                      color: category!.color,
                      size: 44,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category?.name ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                         Text(
                           'Месячный лимит',
                           style: TextStyle(
                             fontSize: 12,
                             color: Colors.grey[300],
                             fontWeight: FontWeight.w500,
                           ),
                         ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.formatKZT(currentSpending),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: progressColor,
                        ),
                      ),
                      Text(
                        'из ${CurrencyFormatter.formatKZT(limit.limitAmount)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedProgressBar(
                value: percentage / 100,
                color: progressColor,
                height: 10,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${percentage.toStringAsFixed(0)}% использовано',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (isOverLimit)
                    Row(
                      children: [
                        const Icon(Icons.warning, size: 14, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          'Превышен на ${CurrencyFormatter.formatKZT(currentSpending - limit.limitAmount)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'Осталось: ${CurrencyFormatter.formatKZT(remaining)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MonthlyLimitDialog extends StatefulWidget {
  final List<models.Category> categories;
  final MonthlyLimit? existingLimit;

  const MonthlyLimitDialog({
    super.key,
    required this.categories,
    this.existingLimit,
  });

  @override
  State<MonthlyLimitDialog> createState() => _MonthlyLimitDialogState();
}

class _MonthlyLimitDialogState extends State<MonthlyLimitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _uuid = const Uuid();
  
  late String _selectedCategoryId;
  late bool _isActive;
  late bool _showInNotification;

  @override
  void initState() {
    super.initState();
    
    if (widget.existingLimit != null) {
      _selectedCategoryId = widget.existingLimit!.categoryId;
      _amountController.text = widget.existingLimit!.limitAmount.toString();
      _isActive = widget.existingLimit!.isActive;
      _showInNotification = widget.existingLimit!.showInNotification;
    } else {
      final expenseCategories = widget.categories
          .where((c) => c.type == models.CategoryType.expense)
          .toList();
      _selectedCategoryId = expenseCategories.isNotEmpty
          ? expenseCategories.first.id
          : widget.categories.first.id;
      _isActive = true;
      _showInNotification = true;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingLimit != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Редактировать лимит' : 'Добавить месячный лимит',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Установите максимальную сумму расходов на месяц для выбранной категории',
                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),

                // Category dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Категория',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: widget.categories
                      .where((c) => c.type == models.CategoryType.expense)
                      .map((category) => DropdownMenuItem(
                            value: category.id,
                            child: Row(
                              children: [
                                Icon(category.icon, color: category.color, size: 20),
                                const SizedBox(width: 12),
                                Text(category.name),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Amount field
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Лимит на месяц',
                    suffixText: '₸',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.payments),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите сумму';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Сумма должна быть больше 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Active switch
                SwitchListTile(
                  title: const Text('Активен'),
                  subtitle: const Text('Отслеживать расходы по этому лимиту'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                
                 // Show in widget switch
                SwitchListTile(
                  title: const Text('Показывать в виджете'),
                  subtitle: const Text('Отображать в панели уведомлений'),
                  value: _showInNotification,
                  onChanged: (value) {
                    setState(() {
                      _showInNotification = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Отмена'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _save,
                      child: Text(isEdit ? 'Сохранить' : 'Добавить'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);

      final limit = MonthlyLimit(
        id: widget.existingLimit?.id ?? _uuid.v4(),
        categoryId: _selectedCategoryId,
        limitAmount: amount,
        isActive: _isActive,
        showInNotification: _showInNotification,
      );

      Navigator.pop(context, limit);
    }
  }
}
