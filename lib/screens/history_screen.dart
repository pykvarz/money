import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../providers/expense_provider.dart'; // We might need a provider that loads ALL transactions, or just use DB helper directly?
// ExpenseProvider currently loads current month. 
// We should probably extend ExpenseProvider or create a HistoryProvider.
// For simplicity, let's load all transactions in this screen using FutureBuilder from DB Helper, or add getAllTransactions to ExpenseProvider.
import '../services/database_helper.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/transaction_dialog.dart';
import '../utils/currency_formatter.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Transaction> _allTransactions = [];
  List<Transaction> _filteredTransactions = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterTransactions);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    // Note: This might be heavy if thousands of transactions. Pagination recommended for production.
    final list = _db.getAllTransactions();
    // Sort by date desc
    list.sort((a, b) => b.date.compareTo(a.date));
    
    if (mounted) {
      setState(() {
        _allTransactions = list;
        _filteredTransactions = list;
        _isLoading = false;
      });
    }
  }

  void _filterTransactions() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredTransactions = _allTransactions);
      return;
    }

    setState(() {
      _filteredTransactions = _allTransactions.where((txn) {
        final noteMatch = txn.note?.toLowerCase().contains(query) ?? false;
        final amountMatch = txn.amount.toString().contains(query);
        // We could also filter by category name if we fetch category
        // But we need to resolve category ID first.
        // Let's stick to basic search for now.
        return noteMatch || amountMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История транзакций'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по заметкам или сумме',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                    ? Center(
                        child: Text(
                          _allTransactions.isEmpty
                              ? 'История пуста'
                              : 'Ничего не найдено',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = _filteredTransactions[index];
                          // We need category for display.
                          // ExpenseProvider has categories loaded.
                          final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
                          final category = expenseProvider.getCategoryById(transaction.categoryId);

                          // Group headers by Month/Year could be nice, but simple list for now.
                          return TransactionListItem(
                            transaction: transaction,
                            category: category,
                            onTap: () async {
                               // Open edit dialog
                               // We reuse the existing dialog logic
                               await _showTransactionDialog(context, transaction);
                               // Reload list after return (incase of update/delete)
                               _loadData();
                               // Also refresh main provider to update home screen
                               if (mounted) {
                                 context.read<ExpenseProvider>().loadTransactions();
                               }
                            },
                            onDelete: () async {
                               await _db.deleteTransaction(transaction.id);
                               _loadData();
                               if (mounted) {
                                  context.read<ExpenseProvider>().loadTransactions();
                               }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTransactionDialog(
    BuildContext context,
    Transaction transaction,
  ) async {
    final expenseProvider = context.read<ExpenseProvider>();
    final result = await showDialog<Transaction>(
      context: context,
      builder: (context) => TransactionDialog(
        categories: expenseProvider.categories,
        transaction: transaction,
      ),
    );

    if (result != null) {
       await expenseProvider.updateTransaction(result);
    }
  }
}
