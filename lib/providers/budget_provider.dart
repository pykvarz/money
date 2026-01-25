import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/monthly_budget.dart';
import '../models/weekly_limit.dart';
import '../models/monthly_limit.dart';
import '../models/transaction.dart';
import '../models/savings_goal.dart';
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
  List<SavingsGoal> _savingsGoals = [];

  MonthlyBudget? get currentBudget => _currentBudget;
  List<WeeklyLimit> get weeklyLimits => _weeklyLimits;
  List<MonthlyLimit> get monthlyLimits => _monthlyLimits;
  List<SavingsGoal> get savingsGoals => _savingsGoals;

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
    await loadSavingsGoals();
    notifyListeners();
  }

  Future<void> _checkAndMigrateFixedExpenses() async {
    // Only run if we have active fixed expenses currently
    final currentTotal = _db.getTotalFixedExpensesForMonth();
    if (currentTotal == 0) return;

    final allBudgets = _db.getAllMonthlyBudgets();
    bool changed = false;

    for (var budget in allBudgets) {
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
    
    await loadWeeklyLimits();
    
    if (_currentBudget != null) {
      await _migratedWeeklyLimitsIfNeeded(_currentBudget!.month, _currentBudget!.year);
    }

    await loadWeeklyLimits(); // Reload after potential migration
    await loadMonthlyLimits();
    
    notifyListeners();
  }
  
  Future<void> _migratedWeeklyLimitsIfNeeded(int month, int year) async {
    final firstOfMonth = DateTime(year, month, 1);
    final weekStart = _getWeekStart(firstOfMonth);
    
    final existingLimits = _db.getAllWeeklyLimits().where((l) => 
      l.weekStartDate.year == weekStart.year &&
      l.weekStartDate.month == weekStart.month &&
      l.weekStartDate.day == weekStart.day
    ).toList();
    
    if (existingLimits.isNotEmpty) return;
    
    final prevWeekStart = weekStart.subtract(const Duration(days: 7));
    final prevLimits = _db.getAllWeeklyLimits().where((l) => 
      l.weekStartDate.year == prevWeekStart.year &&
      l.weekStartDate.month == prevWeekStart.month &&
      l.weekStartDate.day == prevWeekStart.day &&
      l.isActive
    ).toList();
    
    if (prevLimits.isEmpty) return;
    
    for (var limit in prevLimits) {
       final newLimit = WeeklyLimit(
         id: const Uuid().v4(),
         categoryId: limit.categoryId,
         limitAmount: limit.limitAmount,
         weekStartDate: weekStart,
         isActive: true,
       );
       await _db.addWeeklyLimit(newLimit);
    }
  }

  // Update persistent notification with latest stats
  Future<void> updateWeeklyNotification(ExpenseProvider expenseProvider) async {
    final activeLimits = _weeklyLimits.where((l) => l.isActive).toList();
    if (activeLimits.isEmpty) {
      await NotificationService().cancelAll();
      return;
    }

    final totalLimit = activeLimits.fold(0.0, (sum, l) => sum + l.limitAmount);

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

  // ==================== SAVINGS GOAL OPERATIONS ====================

  Future<void> loadSavingsGoals() async {
    _savingsGoals = _db.getAllSavingsGoals();
    notifyListeners();
  }

  Future<void> addSavingsGoal(SavingsGoal goal) async {
    await _db.addSavingsGoal(goal);
    await loadSavingsGoals();
  }

  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    await _db.updateSavingsGoal(goal);
    await loadSavingsGoals();
  }

  Future<void> deleteSavingsGoal(String id) async {
    await _db.deleteSavingsGoal(id);
    await loadSavingsGoals();
  }

  Future<void> addFundsToGoal(String id, double amount) async {
    final goal = _savingsGoals.firstWhere((g) => g.id == id);
    goal.currentAmount += amount;
    
    if (goal.currentAmount >= goal.targetAmount) {
      goal.isCompleted = true;
    }
    
    await _db.updateSavingsGoal(goal);
    await loadSavingsGoals();
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
    
    final baseBalance = _db.getCurrentBalanceForMonth(
      _currentBudget!.month,
      _currentBudget!.year,
      _currentBudget!.initialBalance,
    );
    
    double fixedDeduction = 0.0;
    if (_currentBudget!.isCurrentMonth()) {
      fixedDeduction = _db.getTotalFixedExpensesForMonth();
    } else {
      fixedDeduction = _currentBudget!.projectedFixedExpenses;
    }
    
    return baseBalance - fixedDeduction;
  }

  // Calculate safe daily budget
  double getSafeDailyBudget() {
    if (_currentBudget == null) return 0.0;
    
    final currentBalance = getCurrentBalance();
    return _currentBudget!.calculateSafeDailyBudget(
      currentBalance,
      fixedExpensesTotal: 0.0,
    );
  }

  // Calculate safe daily budget accounting for Limits
  double getSmartSafeDailyBudget(ExpenseProvider expenseProvider) {
    if (_currentBudget == null) return 0.0;
    
    final daysInMonth = _currentBudget!.getTotalDaysInMonth();
    final currentBalance = getCurrentBalance();
    
    double reservedForLimits = 0.0;
    
    for (var limit in _weeklyLimits.where((l) => l.isActive)) {
       final monthlyQuota = (limit.limitAmount / 7.0) * daysInMonth;
       final spentThisMonth = expenseProvider.transactions
           .where((t) => t.categoryId == limit.categoryId && t.type == TransactionType.expense)
           .fold(0.0, (sum, t) => sum + t.amount);
       final remainingReserved = (monthlyQuota - spentThisMonth).clamp(0.0, double.infinity);
       reservedForLimits += remainingReserved;
    }
    
    for (var limit in _monthlyLimits.where((l) => l.isActive)) {
       final spentThisMonth = expenseProvider.transactions
           .where((t) => t.categoryId == limit.categoryId && t.type == TransactionType.expense)
           .fold(0.0, (sum, t) => sum + t.amount);
       final remaining = (limit.limitAmount - spentThisMonth).clamp(0.0, double.infinity);
       reservedForLimits += remaining;
     }
     
     return _currentBudget!.calculateSafeDailyBudget(currentBalance, fixedExpensesTotal: reservedForLimits);
  }

  // Calculate total monthly quota for all active limits
  double getTotalLimitsQuota() {
    if (_currentBudget == null) return 0.0;
    final daysInMonth = _currentBudget!.getTotalDaysInMonth();
    
    double total = 0.0;
    for (var limit in _weeklyLimits.where((l) => l.isActive)) {
      total += (limit.limitAmount / 7.0) * daysInMonth;
    }
    for (var limit in _monthlyLimits.where((l) => l.isActive)) {
      total += limit.limitAmount;
    }
    return total;
  }

  // Get breakdown of reserved amounts per category
  Map<String, double> getReservedLimitsBreakdown(ExpenseProvider expenseProvider) {
    if (_currentBudget == null) return {};
    final daysInMonth = _currentBudget!.getTotalDaysInMonth();
    final Map<String, double> breakdown = {};

    for (var limit in _weeklyLimits.where((l) => l.isActive)) {
      final category = _db.getCategoryById(limit.categoryId);
      final monthlyQuota = (limit.limitAmount / 7.0) * daysInMonth;
      final spentThisMonth = expenseProvider.transactions
          .where((t) => t.categoryId == limit.categoryId && t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);
      final remaining = (monthlyQuota - spentThisMonth).clamp(0.0, double.infinity);
      if (remaining > 0) {
        final name = category?.name ?? 'Unknown';
        breakdown[name] = (breakdown[name] ?? 0) + remaining;
      }
    }

    for (var limit in _monthlyLimits.where((l) => l.isActive)) {
      final category = _db.getCategoryById(limit.categoryId);
      final spentThisMonth = expenseProvider.transactions
          .where((t) => t.categoryId == limit.categoryId && t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);
      final remaining = (limit.limitAmount - spentThisMonth).clamp(0.0, double.infinity);
      if (remaining > 0) {
        final name = category?.name ?? 'Unknown';
        breakdown[name] = (breakdown[name] ?? 0) + remaining;
      }
    }

    return breakdown;
  }

  // Get budget status
  BudgetStatus getBudgetStatus(double todayExpense) {
    if (_currentBudget == null) return BudgetStatus.neutral;
    final currentBalance = getCurrentBalance();
    return _currentBudget!.getBudgetStatus(
      currentBalance,
      todayExpense,
      fixedExpensesTotal: 0.0,
    );
  }

  // Check budget status and update notifications
  Future<void> checkBudgetStatus(ExpenseProvider expenseProvider) async {
    if (_currentBudget == null) return;
    
    double totalSpent = 0;
    double totalLimit = 0;
    
    for (var limit in _weeklyLimits.where((l) => l.isActive && l.isCurrentWeek())) {
       totalLimit += limit.getEffectiveLimit(_currentBudget!.month, _currentBudget!.year);
       totalSpent += expenseProvider.getWeeklySpendingInMonth(
         limit.categoryId, 
         limit.weekStartDate, 
         _currentBudget!.month, 
         _currentBudget!.year
       );
    }
    
    await NotificationService().updateWeeklySummaryContent(totalSpent, totalLimit);
  }

  // Get all monthly budgets (for library)
  List<MonthlyBudget> getAllBudgets() {
    return _db.getAllMonthlyBudgets();
  }

  // Calculate total savings from past weeks' limits
  double getWeeklySavingsThisMonth(ExpenseProvider expenseProvider) {
    double totalSavings = 0.0;
    final now = DateTime.now();
    final activeLimits = _weeklyLimits.where((limit) => limit.isActive).toList();
    if (activeLimits.isEmpty) return 0.0;
    
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final currentWeekStart = _getWeekStart(now);
    DateTime weekStart = _getWeekStart(firstDayOfMonth);
    
    while (weekStart.isBefore(currentWeekStart)) {
      for (var limit in activeLimits) {
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
      weekStart = weekStart.add(const Duration(days: 7));
    }
    return totalSavings;
  }
  
  double getAllTimePiggyBankSavings() {
    return _db.calculateAllTimeSavings();
  }

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
