import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class TransactionDialog extends StatefulWidget {
  final List<Category> categories;
  final Transaction? transaction; // null for new, existing for edit

  const TransactionDialog({
    super.key,
    required this.categories,
    this.transaction,
    this.initialCategoryId,
  });

  final String? initialCategoryId;

  @override
  State<TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<TransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _uuid = const Uuid();

  late TransactionType _type;
  late String _selectedCategoryId;
  late DateTime _selectedDate;

  bool get _isQuickAdd => widget.initialCategoryId != null;

  @override
  void initState() {
    super.initState();

    if (widget.transaction != null) {
      // Editing existing transaction
      _type = widget.transaction!.type;
      _selectedCategoryId = widget.transaction!.categoryId;
      _selectedDate = widget.transaction!.date;
      _amountController.text = widget.transaction!.amount.toString();
      _noteController.text = widget.transaction!.note ?? '';
    } else {
      // New transaction
      _selectedDate = DateTime.now();

      if (widget.initialCategoryId != null) {
        // Pre-select category and type
        final category = widget.categories.firstWhere(
          (c) => c.id == widget.initialCategoryId,
          orElse: () => widget.categories.first,
        );
        _type = category.type == CategoryType.expense 
            ? TransactionType.expense 
            : TransactionType.income;
        _selectedCategoryId = category.id;
      } else {
        _type = TransactionType.expense;
        // Find first category of expense type
        final expenseCategories = widget.categories
            .where((c) => c.type == CategoryType.expense)
            .toList();
        _selectedCategoryId = expenseCategories.isNotEmpty
            ? expenseCategories.first.id
            : widget.categories.first.id;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.transaction != null;

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
                  isEdit ? 'Редактировать' : (_isQuickAdd ? 'Быстрая запись' : 'Добавить транзакцию'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),

                // Type selector
                if (!_isQuickAdd) ...[
                  Text('Тип', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  SegmentedButton<TransactionType>(
                    segments: const [
                      ButtonSegment(
                        value: TransactionType.expense,
                        label: Text('Расход'),
                        icon: Icon(Icons.arrow_upward),
                      ),
                      ButtonSegment(
                        value: TransactionType.income,
                        label: Text('Доход'),
                        icon: Icon(Icons.arrow_downward),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (Set<TransactionType> newSelection) {
                      setState(() {
                        _type = newSelection.first;
                        // Update category selection based on type
                        _updateCategoryForType();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Amount field
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  autofocus: _isQuickAdd, // Auto-focus in quick add mode
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Сумма',
                    suffixText: 'KZT',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  textInputAction: _isQuickAdd ? TextInputAction.done : TextInputAction.next,
                  onFieldSubmitted: _isQuickAdd ? (_) => _save() : null,
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

                if (!_isQuickAdd) ...[
                  // Category dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Категория',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _getFilteredCategories()
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

                  // Date picker
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Дата',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Note field
                  TextFormField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Заметка (необязательно)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                    ),
                  ),
                ],
                if (_isQuickAdd) ...[
                   // Show selected category as info
                   Row(
                     children: [
                       const Text('Категория: ', style: TextStyle(color: Colors.grey)),
                       Builder(builder: (context) {
                          final cat = widget.categories.firstWhere((c) => c.id == _selectedCategoryId);
                          return Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold));
                       }),
                     ],
                   ),
                ],
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
                      child: Text(isEdit ? 'Изменить' : 'Добавить'),
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

  List<Category> _getFilteredCategories() {
    final categoryType = _type == TransactionType.expense
        ? CategoryType.expense
        : CategoryType.income;
    return widget.categories.where((c) => c.type == categoryType).toList();
  }

  void _updateCategoryForType() {
    final filteredCategories = _getFilteredCategories();
    if (filteredCategories.isNotEmpty &&
        !filteredCategories.any((c) => c.id == _selectedCategoryId)) {
      _selectedCategoryId = filteredCategories.first.id;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      final note = _noteController.text.trim();

      final transaction = Transaction(
        id: widget.transaction?.id ?? _uuid.v4(),
        amount: amount,
        type: _type,
        categoryId: _selectedCategoryId,
        date: _selectedDate,
        note: note.isEmpty ? null : note,
        createdAt: widget.transaction?.createdAt ?? DateTime.now(),
      );

      Navigator.pop(context, transaction);
    }
  }
}
