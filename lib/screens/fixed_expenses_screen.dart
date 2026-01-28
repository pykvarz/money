import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/fixed_expense.dart';
import '../providers/budget_provider.dart';
import '../widgets/fixed_expense_dialog.dart';
import '../services/database_helper.dart';
import '../utils/currency_formatter.dart';

class FixedExpensesScreen extends StatefulWidget {
  const FixedExpensesScreen({super.key});

  @override
  State<FixedExpensesScreen> createState() => _FixedExpensesScreenState();
}

class _FixedExpensesScreenState extends State<FixedExpensesScreen> {
  @override
  Widget build(BuildContext context) {
    // Consumer allows us to rebuild when Provider notifies (i.e. after Add/Edit/Delete)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Обязательные расходы'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, child) {
          return FutureBuilder<List<FixedExpense>>(
            future: _loadFixedExpenses(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Список пуст',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Добавьте регулярные платежи,\nчтобы учитывать их в бюджете',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              final expenses = snapshot.data!;
              final total = expenses.fold(0.0, (sum, e) => sum + e.amount);

              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Ежемесячная сумма',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.formatKZT(total),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: expenses.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final expense = expenses[index];
                        final colorScheme = Theme.of(context).colorScheme;
                        
                        return Card(
                          elevation: 0,
                          color: colorScheme.surfaceContainer, // Theme-aware
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showFixedExpenseDialog(context, existingExpense: expense),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHighest, // Theme-aware
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.receipt_long,
                                      color: Colors.deepPurple,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          expense.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: colorScheme.onSurface, // Theme-aware
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          CurrencyFormatter.formatKZT(expense.amount),
                                          style: TextStyle(
                                            color: colorScheme.onSurfaceVariant, // Theme-aware
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                    onPressed: () => _showFixedExpenseDialog(context, existingExpense: expense),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _deleteFixedExpense(context, expense.id),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFixedExpenseDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<List<FixedExpense>> _loadFixedExpenses() async {
    final db = DatabaseHelper();
    return db.getAllFixedExpenses();
  }

  Future<void> _showFixedExpenseDialog(
    BuildContext context, {
    FixedExpense? existingExpense,
  }) async {
    final result = await showDialog<FixedExpense>(
      context: context,
      builder: (context) => FixedExpenseDialog(
        existingExpense: existingExpense,
      ),
    );

    if (result != null) {
      if (context.mounted) {
        final provider = Provider.of<BudgetProvider>(context, listen: false);
        if (existingExpense != null) {
           await provider.updateFixedExpense(result);
        } else {
           await provider.addFixedExpense(result);
        }
      }
    }
  }

  Future<void> _deleteFixedExpense(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить расход?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final provider = Provider.of<BudgetProvider>(context, listen: false);
      await provider.deleteFixedExpense(id);
    }
  }
}
