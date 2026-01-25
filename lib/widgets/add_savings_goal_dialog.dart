import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/savings_goal.dart';
import '../providers/budget_provider.dart';

class AddSavingsGoalDialog extends StatefulWidget {
  final SavingsGoal? goal;

  const AddSavingsGoalDialog({super.key, this.goal});

  @override
  State<AddSavingsGoalDialog> createState() => _AddSavingsGoalDialogState();
}

class _AddSavingsGoalDialogState extends State<AddSavingsGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late int _selectedIconCode;
  late int _selectedColorValue;

  final List<IconData> _icons = [
    Icons.savings,
    Icons.directions_car,
    Icons.home,
    Icons.flight,
    Icons.laptop,
    Icons.phone_android,
    Icons.watch,
    Icons.videogame_asset,
    Icons.shopping_bag,
    Icons.celebration,
    Icons.favorite,
    Icons.star,
  ];

  final List<Color> _colors = [
    Colors.deepPurple,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.pink,
    Colors.teal,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal?.name ?? '');
    _amountController = TextEditingController(
      text: widget.goal?.targetAmount.toInt().toString() ?? '',
    );
    _selectedIconCode = widget.goal?.iconCodePoint ?? Icons.savings.codePoint;
    _selectedColorValue = widget.goal?.colorValue ?? Colors.deepPurple.value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final budgetProvider = context.read<BudgetProvider>();
      final name = _nameController.text;
      final amount = double.parse(_amountController.text);

      if (widget.goal == null) {
        final newGoal = SavingsGoal(
          id: const Uuid().v4(),
          name: name,
          targetAmount: amount,
          iconCodePoint: _selectedIconCode,
          colorValue: _selectedColorValue,
        );
        budgetProvider.addSavingsGoal(newGoal);
      } else {
        widget.goal!.name = name;
        widget.goal!.targetAmount = amount;
        widget.goal!.iconCodePoint = _selectedIconCode;
        widget.goal!.colorValue = _selectedColorValue;
        budgetProvider.updateSavingsGoal(widget.goal!);
      }

      Navigator.pop(context);
    }
  }

  void _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить цель?'),
        content: Text('Вы действительно хотите удалить цель "${widget.goal!.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      context.read<BudgetProvider>().deleteSavingsGoal(widget.goal!.id);
      Navigator.pop(context); // Close the edit dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.goal == null ? 'Новая цель' : 'Редактировать цель'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  hintText: 'Например: Новый ноутбук',
                ),
                validator: (value) => 
                    value == null || value.isEmpty ? 'Введите название' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Целевая сумма',
                  suffixText: '₸',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Введите сумму';
                  if (double.tryParse(value) == null) return 'Некорректная сумма';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text('Иконка', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _icons.map((icon) {
                  final isSelected = _selectedIconCode == icon.codePoint;
                  return InkWell(
                    onTap: () => setState(() => _selectedIconCode = icon.codePoint),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Color(_selectedColorValue).withOpacity(0.2) 
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? Color(_selectedColorValue) : Colors.grey.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? Color(_selectedColorValue) : Colors.grey,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text('Цвет', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colors.map((color) {
                  final isSelected = _selectedColorValue == color.value;
                  return InkWell(
                    onTap: () => setState(() => _selectedColorValue = color.value),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected 
                            ? Border.all(color: Colors.white, width: 2) 
                            : null,
                        boxShadow: isSelected 
                            ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4, spreadRadius: 2)] 
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.goal != null)
          TextButton(
            onPressed: _delete,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
