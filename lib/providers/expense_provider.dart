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

  // Get spending for a specific week slice within a month
  double getWeeklySpendingInMonth(String categoryId, DateTime weekStart, int month, int year) {
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 0);
    final weekEnd = weekStart.add(const Duration(days: 6));

    final effectiveStart = weekStart.isBefore(monthStart) ? monthStart : weekStart;
    final effectiveEnd = weekEnd.isAfter(monthEnd) ? monthEnd : weekEnd;

    final transactions = _db.getTransactionsInRange(
      effectiveStart,
      effectiveEnd,
      categoryId: categoryId,
    );

    return transactions
        .where((txn) => txn.type == TransactionType.expense)
        .fold(0.0, (sum, txn) => sum + txn.amount);
  }
  // Analytics: Get 6-month spending trend
  // Returns list of {month: 'Jan', amount: 50000, year: 2024, monthIndex: 1}
  List<Map<String, dynamic>> getSixMonthTrend() {
    final List<Map<String, dynamic>> trend = [];
    final now = DateTime.now();
    
    // Iterate backwards from current month
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final total = _db.getTotalExpenseForMonth(date.month, date.year);
      
      trend.add({
        'month': _getMonthName(date.month),
        'amount': total,
        'year': date.year,
        'monthIndex': date.month,
      });
    }
    
    return trend;
  }

  String _getMonthName(int month) {
    const months = ['Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн', 'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'];
    return months[month - 1];
  }
}
