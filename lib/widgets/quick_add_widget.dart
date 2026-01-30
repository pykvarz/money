import 'package:flutter/material.dart';
import '../utils/custom_toast.dart';
import 'package:provider/provider.dart';
import '../models/transaction_template.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';
import '../services/database_helper.dart';
import 'transaction_template_dialog.dart';
import 'package:uuid/uuid.dart';

class QuickAddWidget extends StatefulWidget {
  const QuickAddWidget({super.key});

  @override
  State<QuickAddWidget> createState() => _QuickAddWidgetState();
}

class _QuickAddWidgetState extends State<QuickAddWidget> {
  final DatabaseHelper _db = DatabaseHelper();
  List<TransactionTemplate> _templates = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final list = _db.getAllTransactionTemplates();
    if (mounted) {
      setState(() {
        _templates = list;
      });
    }
  }

  Future<void> _addTemplate() async {
    final expenseProvider = context.read<ExpenseProvider>();
    final result = await showDialog<TransactionTemplate>(
      context: context,
      builder: (context) => TransactionTemplateDialog(
        categories: expenseProvider.categories,
      ),
    );

    if (result != null) {
      await _db.addTransactionTemplate(result);
      _loadTemplates();
    }
  }

  Future<void> _editTemplate(TransactionTemplate template) async {
    final expenseProvider = context.read<ExpenseProvider>();
    final result = await showDialog<TransactionTemplate>(
      context: context,
      builder: (context) => TransactionTemplateDialog(
        categories: expenseProvider.categories,
        existingTemplate: template,
      ),
    );

    if (result != null) {
      await _db.addTransactionTemplate(result); // Update (same ID)
      _loadTemplates();
    }
  }
  
  Future<void> _deleteTemplate(TransactionTemplate template) async {
     final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить шаблон?'),
        content: Text('Удалить "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _db.deleteTransactionTemplate(template.id);
      _loadTemplates();
    }
  }

  Future<void> _useTemplate(TransactionTemplate template) async {
     final expenseProvider = context.read<ExpenseProvider>();
     
     // Current Date
     final now = DateTime.now();
     
     // Create Transaction
     final transaction = Transaction(
       id: const Uuid().v4(),
       amount: template.amount,
       type: TransactionType.expense, // Templates are usually expenses
       categoryId: template.categoryId,
       date: now,
       createdAt: now,
       note: template.note ?? '',
     );
     
     await expenseProvider.addTransaction(transaction);
     
     if (context.mounted) {
       context.read<BudgetProvider>().checkBudgetStatus(expenseProvider);
     }
     
     if (mounted) {
       CustomToast.show(context, 'Добавлено: ${template.name}');
     }
  }

  @override
  Widget build(BuildContext context) {
    // If no templates, show nothing (managed in Settings now)
    if (_templates.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Быстрые расходы',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _templates.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final template = _templates[index];
              
              // Use Selector to efficiently listen to changes for this specific category
              // This avoids unsafe context.read in build and rebuilds only if this category changes (unlikely but correct)
              // Or simply access data if we treat categories as static for this view
              return Selector<ExpenseProvider, Category?>(
                selector: (_, provider) => provider.getCategoryById(template.categoryId),
                builder: (context, category, child) {
                  return InkWell(
                    onLongPress: () => _showOptions(template),
                    borderRadius: BorderRadius.circular(20),
                    child: ActionChip(
                      avatar: category != null 
                          ? Icon(category.icon, size: 16, color: category.color) 
                          : null,
                      label: Text(template.name),
                      backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor, // Use card color (lighter in dark mode)
                      side: BorderSide.none,
                      onPressed: () => _useTemplate(template),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  void _showOptions(TransactionTemplate template) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Изменить'),
              onTap: () {
                Navigator.pop(context);
                _editTemplate(template);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Удалить', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteTemplate(template);
              },
            ),
          ],
        ),
      ),
    );
  }
}
