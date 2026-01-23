import 'package:flutter/material.dart';
import '../models/monthly_budget.dart';
import '../models/weekly_limit.dart';
import '../models/monthly_limit.dart';
import '../models/transaction.dart';
import '../models/category.dart' as models;
import '../models/fixed_expense.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';
import 'expense_provider.dart';

class BudgetProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  MonthlyBudget? _currentBudget;
  List<WeeklyLimit> _weeklyLimits = [];
  List<MonthlyLimit> _monthlyLimits = [];

  MonthlyBudget? get currentBudget => _currentBudget;
  List<WeeklyLimit> get weeklyLimits => _weeklyLimits;
  List<MonthlyLimit> get monthlyLimits => _monthlyLimits;

  BudgetProvider() {
    loadCurrentBudget();
  }

  // Load budget for current month
  Future<void> loadCurrentBudget() async {
    final now = DateTime.now();
    _currentBudget = await _db.getOrCreateMonthlyBudget(now.month, now.year);
    
    // Migration: Check if we need to back-fill validation for older budgets
    await _checkAndMigrateFixedExpenses();

    await loadWeeklyLimits();
    await loadMonthlyLimits();
    notifyListeners();
  }

  Future<void> _checkAndMigrateFixedExpenses() async {
    // Only run if we have active fixed expenses currently
    final currentTotal = _db.getTotalFixedExpensesForMonth();
    if (currentTotal == 0) return;

    final allBudgets = _db.getAllMonthlyBudgets();
    bool changed = false;

    for (var budget in allBudgets) {
      // If snapshot is 0 but we have global expenses, likely a pre-migration budget
      // We explicitly check for 0.0 to avoid overwriting legitimate 0s if possible,
      // but since previously it was dynamic, defaulting to currentTotal is the safest bet for history.
      if (budget.projectedFixedExpenses == 0.0) {
        budget.projectedFixedExpenses = currentTotal;
        await _db.updateMonthlyBudget(budget);
        changed = true;
      }
    }
    
    // Reload current if it was changed
    if (changed && _currentBudget != null) {
      _currentBudget = await _db.getOrCreateMonthlyBudget(_currentBudget!.month, _currentBudget!.year);
    }
  }

  // Load budget for specific month
  Future<void> loadBudgetForMonth(int month, int year) async {
    _currentBudget = await _db.getOrCreateMonthlyBudget(month, year);
    
    // If loading CURRENT month, ensure snapshot is up to date
    if (_currentBudget!.isCurrentMonth()) {
      final currentTotal = _db.getTotalFixedExpensesForMonth();
      if (_currentBudget!.projectedFixedExpenses != currentTotal) {
        _currentBudget!.projectedFixedExpenses = currentTotal;
        await _db.updateMonthlyBudget(_currentBudget!);
      }
    }
    
    await loadWeeklyLimits(); // TODO: Weekly limits are actually global/recurring right now. 
    // They are not per-month in current implementation, they just reset every week.
    // Monthly limits should function similarly (recurring).
    await loadMonthlyLimits();
    
    notifyListeners();
  }

  // Update persistent notification with latest stats
  Future<void> updateWeeklyNotification(ExpenseProvider expenseProvider) async {
    // 1. Calculate total active weekly limit
    final activeLimits = _weeklyLimits.where((l) => l.isActive).toList();
    if (activeLimits.isEmpty) {
      await NotificationService().cancelAll();
      return;
    }

    final totalLimit = activeLimits.fold(0.0, (sum, l) => sum + l.limitAmount);

    // 2. Calculate total spending AND details
    final now = DateTime.now();
    final weekStart = _getWeekStart(now);
    final weekEnd = weekStart.add(const Duration(days: 7));
    
    double totalSpent = 0.0;
    List<Map<String, dynamic>> items = [];
    
    for (var limit in activeLimits) {
      final spending = _getSpendingForWeek(
        weekStart,
        weekEnd,
        limit.categoryId,
        expenseProvider,
      );
      totalSpent += spending;
      
      // Get category name
      final category = expenseProvider.categories.firstWhere(
        (c) => c.id == limit.categoryId,
        orElse: () => models.Category(
          id: 'unknown', 
          name: 'Неизвестно', 
          iconCodePoint: Icons.error.codePoint, 
          colorValue: Colors.grey.value, 
          type: models.CategoryType.expense
        ),
      );
      
      items.add({
        'name': category.name,
        'spent': spending,
        'limit': limit.limitAmount,
        'isOver': spending > limit.limitAmount,
      });
    }

    // 3. Show notification
    await NotificationService().showWeeklySummary(
      items: items,
      totalSpent: totalSpent,
      totalLimit: totalLimit,
      currency: 'KZT',
    );
  }

  // Load weekly limits
  Future<void> loadWeeklyLimits() async {
    _weeklyLimits = _db.getAllWeeklyLimits();
    notifyListeners();
  }

  // Update target balance
  Future<void> updateTargetBalance(double? target) async {
    if (_currentBudget == null) return;
    
    _currentBudget!.targetRemainingBalance = target;
    await _db.updateMonthlyBudget(_currentBudget!);
    notifyListeners();
  }

  // Update initial balance
  Future<void> updateInitialBalance(double initialBalance) async {
    if (_currentBudget == null) return;
    
    _currentBudget!.initialBalance = initialBalance;
    await _db.updateMonthlyBudget(_currentBudget!);
    notifyListeners();
  }

  // Load monthly limits
  Future<void> loadMonthlyLimits() async {
    _monthlyLimits = _db.getAllMonthlyLimits();
    notifyListeners();
  }

  // Add or update weekly limit
  Future<void> setWeeklyLimit(WeeklyLimit limit) async {
    await _db.addWeeklyLimit(limit);
    await loadWeeklyLimits();
  }
  
  // Add or update monthly limit
  Future<void> setMonthlyLimit(MonthlyLimit limit) async {
    await _db.addMonthlyLimit(limit);
    await loadMonthlyLimits();
  }

  // Delete weekly limit
  Future<void> deleteWeeklyLimit(String id) async {
    await _db.deleteWeeklyLimit(id);
    await loadWeeklyLimits();
  }

  // Delete monthly limit
  Future<void> deleteMonthlyLimit(String id) async {
    await _db.deleteMonthlyLimit(id);
    await loadMonthlyLimits();
  }

  // Get active weekly limit for category
  WeeklyLimit? getActiveWeeklyLimit(String categoryId) {
    return _db.getActiveWeeklyLimitForCategory(categoryId);
  }

  // Get active monthly limit for category
  MonthlyLimit? getActiveMonthlyLimit(String categoryId) {
    return _db.getActiveMonthlyLimitForCategory(categoryId);
  }

  // Get current spending for monthly limit
  double getMonthlySpending(String categoryId) {
    if (_currentBudget == null) return 0.0;
    
    final transactions = _db.getTransactionsForMonth(_currentBudget!.month, _currentBudget!.year);
    return transactions
        .where((txn) => txn.type == TransactionType.expense && txn.categoryId == categoryId)
        .fold(0.0, (sum, txn) => sum + txn.amount);
  }

  // Calculate current balance
  double getCurrentBalance() {
    if (_currentBudget == null) return 0.0;
    
    return _db.getCurrentBalanceForMonth(
      _currentBudget!.month,
      _currentBudget!.year,
      _currentBudget!.initialBalance,
    );
  }

  // Calculate safe daily budget
  double getSafeDailyBudget() {
    if (_currentBudget == null) return 0.0;
    
    final currentBalance = getCurrentBalance();
    
    // Use projected expenses from budget snapshot (preserving history)
    // If it's 0 (legacy data), fallback to current total, but ideal is to have it set.
    // Logic: 
    // - For current month, we keep it synced (see loadCurrentBudget)
    // - For past months, we trust the value in _currentBudget
    
    return _currentBudget!.calculateSafeDailyBudget(
      currentBalance,
      fixedExpensesTotal: _currentBudget!.projectedFixedExpenses,
    );
  }

  // Get budget status
  BudgetStatus getBudgetStatus(double todayExpense) {
    if (_currentBudget == null) return BudgetStatus.neutral;
    
    final currentBalance = getCurrentBalance();
    final db = DatabaseHelper();
    final fixedExpensesTotal = db.getTotalFixedExpensesForMonth();
    
    return _currentBudget!.getBudgetStatus(
      currentBalance,
      todayExpense,
      fixedExpensesTotal: fixedExpensesTotal,
    );
  }

  // Get all monthly budgets (for library)
  List<MonthlyBudget> getAllBudgets() {
    return _db.getAllMonthlyBudgets();
  }

  // Calculate total savings from past weeks' limits
  double getTotalSavingsThisMonth(ExpenseProvider expenseProvider) {
    double totalSavings = 0.0;
    final now = DateTime.now();
    
    // Get all active weekly limits
    final activeLimits = _weeklyLimits.where((limit) => limit.isActive).toList();
    
    if (activeLimits.isEmpty) return 0.0;
    
    // Find all completed weeks in the current month
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final currentWeekStart = _getWeekStart(now);
    
    // Iterate through weeks from start of month until current week
    DateTime weekStart = _getWeekStart(firstDayOfMonth);
    
    while (weekStart.isBefore(currentWeekStart)) {
      // This is a completed week
      for (var limit in activeLimits) {
        // Calculate spending for this specific week
        final weekEnd = weekStart.add(const Duration(days: 7));
        final spending = _getSpendingForWeek(
          weekStart,
          weekEnd,
          limit.categoryId,
          expenseProvider,
        );
        
        final saved = limit.limitAmount - spending;
        if (saved > 0) {
          totalSavings += saved;
        }
      }
      
      // Move to next week
      weekStart = weekStart.add(const Duration(days: 7));
    }
    
    return totalSavings;
  }

  // ==================== FIXED EXPENSE ACTIONS ====================

  // ==================== FIXED EXPENSE ACTIONS ====================

  Future<void> _syncCurrentMonthFixed() async {
    if (_currentBudget != null && _currentBudget!.isCurrentMonth()) {
      _currentBudget!.projectedFixedExpenses = _db.getTotalFixedExpensesForMonth();
      await _db.updateMonthlyBudget(_currentBudget!);
    }
  }

  Future<void> addFixedExpense(FixedExpense expense) async {
    await _db.addFixedExpense(expense);
    await _syncCurrentMonthFixed();
    notifyListeners(); 
  }

  Future<void> updateFixedExpense(FixedExpense expense) async {
    await _db.updateFixedExpense(expense);
    await _syncCurrentMonthFixed();
    notifyListeners();
  }

  Future<void> deleteFixedExpense(String id) async {
    await _db.deleteFixedExpense(id);
    await _syncCurrentMonthFixed();
    notifyListeners();
  }

  // Get total fixed expenses
  double getTotalFixedExpenses() {
    return _db.getTotalFixedExpensesForMonth();
  }

  DateTime _getWeekStart(DateTime date) {
    // Monday is day 1, Sunday is day 7
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: weekday - 1));
  }

  double _getSpendingForWeek(
    DateTime weekStart,
    DateTime weekEnd,
    String categoryId,
    ExpenseProvider expenseProvider,
  ) {
    return expenseProvider.transactions
        .where((txn) =>
            txn.type == TransactionType.expense &&
            txn.categoryId == categoryId &&
            txn.date.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
            txn.date.isBefore(weekEnd))
        .fold(0.0, (sum, txn) => sum + txn.amount);
  }
}
