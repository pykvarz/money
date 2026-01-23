import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/category.dart' as models;
import '../services/database_helper.dart';

class ExpenseProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<Transaction> _transactions = [];
  List<models.Category> _categories = [];
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;

  List<Transaction> get transactions => _transactions;
  List<models.Category> get categories => _categories;
  int get currentMonth => _currentMonth;
  int get currentYear => _currentYear;

  ExpenseProvider() {
    loadData();
  }

  // Load all data
  Future<void> loadData() async {
    await loadCategories();
    await loadTransactions();
  }

  // Load categories
  Future<void> loadCategories() async {
    _categories = _db.getAllCategories();
    notifyListeners();
  }

  // Load transactions for current month
  Future<void> loadTransactions() async {
    _transactions = _db.getTransactionsForMonth(_currentMonth, _currentYear);
    notifyListeners();
  }

  // Change viewed month
  void setMonth(int month, int year) {
    _currentMonth = month;
    _currentYear = year;
    loadTransactions();
  }

  // Add transaction
  Future<void> addTransaction(Transaction transaction) async {
    await _db.addTransaction(transaction);
    await loadTransactions();
  }

  // Update transaction
  Future<void> updateTransaction(Transaction transaction) async {
    await _db.updateTransaction(transaction);
    await loadTransactions();
  }

  // Delete transaction
  Future<void> deleteTransaction(String id) async {
    await _db.deleteTransaction(id);
    await loadTransactions();
  }

  // Add custom category
  Future<void> addCategory(models.Category category) async {
    await _db.addCategory(category);
    await loadCategories();
  }

  // Update category
  Future<void> updateCategory(models.Category category) async {
    await _db.updateCategory(category);
    await loadCategories();
  }

  // Delete category
  Future<void> deleteCategory(String id) async {
    await _db.deleteCategory(id);
    await loadCategories();
  }

  // Get category by ID
  models.Category? getCategoryById(String id) {
    return _db.getCategoryById(id);
  }

  // Analytics: Get total income
  double getTotalIncome() {
    return _db.getTotalIncomeForMonth(_currentMonth, _currentYear);
  }

  // Analytics: Get total expense
  double getTotalExpense() {
    return _db.getTotalExpenseForMonth(_currentMonth, _currentYear);
  }

  // Analytics: Get spending by category
  Map<String, double> getSpendingByCategory() {
    return _db.getSpendingByCategory(_currentMonth, _currentYear);
  }

  // Get current week spending for a category
  double getCurrentWeekSpending(String categoryId) {
    final weekTransactions = _db.getCurrentWeekTransactions(categoryId);
    return weekTransactions
        .where((txn) => txn.type == TransactionType.expense)
        .fold(0.0, (sum, txn) => sum + txn.amount);
  }
}
