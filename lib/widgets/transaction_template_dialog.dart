import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_template.dart';
import '../models/category.dart';

class TransactionTemplateDialog extends StatefulWidget {
  final List<Category> categories;
  final TransactionTemplate? existingTemplate;

  const TransactionTemplateDialog({
    super.key,
    required this.categories,
    this.existingTemplate,
  });

  @override
  State<TransactionTemplateDialog> createState() => _TransactionTemplateDialogState();
}

class _TransactionTemplateDialogState extends State<TransactionTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingTemplate?.name);
    _amountController = TextEditingController(
      text: widget.existingTemplate?.amount.toString(),
    );
    _noteController = TextEditingController(text: widget.existingTemplate?.note);
    _selectedCategoryId = widget.existingTemplate?.categoryId;
    
    // Default to first category if none selected and creating new
    if (_selectedCategoryId == null && widget.categories.isNotEmpty) {
      // Prefer "Food" if exists, else first
      try {
        _selectedCategoryId = widget.categories.firstWhere((c) => c.id == 'cat_food').id;
      } catch (_) {
        _selectedCategoryId = widget.categories.first.id;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingTemplate == null ? 'Новый шаблон' : 'Изменить шаблон'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Template Name (e.g. "Coffee")
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  hintText: 'Например: Кофе, Такси',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              
              // Amount
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Сумма',
                  suffixText: 'KZT',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите сумму';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Некорректная сумма';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Категория',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: widget.categories.where((c) => c.type.index == 1).map((category) { // Expense only
                  return DropdownMenuItem(
                    value: category.id,
                    child: Row(
                      children: [
                        Icon(category.icon, color: category.color, size: 20),
                        const SizedBox(width: 8),
                        Text(category.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
                validator: (value) => value == null ? 'Выберите категорию' : null,
              ),
              const SizedBox(height: 16),
              
              // Note (Optional)
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Заметка (необязательно)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final template = TransactionTemplate(
        id: widget.existingTemplate?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        amount: double.parse(_amountController.text),
        categoryId: _selectedCategoryId!,
        note: _noteController.text.trim(),
      );
      
      Navigator.pop(context, template);
    }
  }
}
