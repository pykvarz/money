import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_template.dart';
import '../providers/expense_provider.dart';
import '../services/database_helper.dart';
import '../widgets/transaction_template_dialog.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Шаблоны'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _templates.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Нет шаблонов',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                final template = _templates[index];
                final category = context
                    .read<ExpenseProvider>()
                    .getCategoryById(template.categoryId);

                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          (category?.color ?? Colors.grey).withOpacity(0.2),
                      child: Icon(
                        category?.icon ?? Icons.help_outline,
                        color: category?.color ?? Colors.grey,
                      ),
                    ),
                    title: Text(
                      template.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${template.amount.toStringAsFixed(0)} ₸' +
                          (template.note?.isNotEmpty == true
                              ? ' • ${template.note}'
                              : ''),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteTemplate(template),
                    ),
                    onTap: () => _editTemplate(template),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTemplate,
        child: const Icon(Icons.add),
      ),
    );
  }
}
