import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Add Hive
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
    final now = DateTime.now();
    final weekStart = _getWeekStart(now);
    final weekEnd = weekStart.add(const Duration(days: 7)); // Mon-Sun full week logic
    
    // Active Limits (that are enabled for notifications)
    final activeWeeklyLimits = _weeklyLimits.where((l) => l.isActive && l.showInNotification).toList();
    final activeMonthlyLimits = _monthlyLimits.where((l) => l.isActive && l.showInNotification).toList();

    if (activeWeeklyLimits.isEmpty && activeMonthlyLimits.isEmpty) {
      // Show a persistent notification prompting user to create limits
      await NotificationService().showWeeklySummaryPersistent(
        weeklyItems: [],
        monthlyItems: [],
        totalSpent: 0,
        totalLimit: 0,
        weekRange: null,
      );
      return;
    }

    final currentMonth = now.month;
    final currentYear = now.year;
    
    // Display Dates Logic
    final monthStart = DateTime(currentYear, currentMonth, 1);
    final monthEnd = DateTime(currentYear, currentMonth + 1, 0);
    final displayStart = weekStart.isBefore(monthStart) ? monthStart : weekStart;
    final displayEnd = weekEnd.subtract(const Duration(days: 1)).isAfter(monthEnd) 
        ? monthEnd 
        : weekEnd.subtract(const Duration(days: 1)); // End is inclusive for display

    double totalSpent = 0.0;
    double totalCombinedLimit = 0.0;
    
    // 1. Process Weekly Limits
    List<Map<String, dynamic>> weeklyItems = [];
    for (var limit in activeWeeklyLimits) {
       final effectiveLimit = limit.getEffectiveLimit(currentMonth, currentYear);
       final spending = expenseProvider.getWeeklySpendingInMonth(
          limit.categoryId,
          limit.weekStartDate,
          currentMonth,
          currentYear
       );
       
       totalSpent += spending;
       totalCombinedLimit += effectiveLimit;
      
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
      
       weeklyItems.add({
         'id': limit.categoryId, // ID added for unique notification tagging
         'name': category.name,
         'spent': spending,
         'limit': effectiveLimit,
         'isOver': spending > effectiveLimit,
       });
    }

    // 2. Process Monthly Limits
    List<Map<String, dynamic>> monthlyItems = [];
    for (var limit in activeMonthlyLimits) {
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

      final spending = getMonthlySpending(limit.categoryId);
      
      // Add to totals
      totalSpent += spending;
      totalCombinedLimit += limit.limitAmount;

      monthlyItems.add({
        'id': limit.categoryId, // ID added for unique notification tagging
        'name': category.name,
        'spent': spending,
        'limit': limit.limitAmount,
        'isOver': spending > limit.limitAmount,
      });
    }

    // Format date range: "26.01 - 31.01"
    final startStr = '${displayStart.day.toString().padLeft(2, '0')}.${displayStart.month.toString().padLeft(2, '0')}';
    final endStr = '${displayEnd.day.toString().padLeft(2, '0')}.${displayEnd.month.toString().padLeft(2, '0')}';
    final weekRange = '$startStr - $endStr';

    await NotificationService().showWeeklySummary(
      weeklyItems: weeklyItems,
      monthlyItems: monthlyItems,
      totalSpent: totalSpent,
      totalLimit: totalCombinedLimit,
      currency: '₸',
      weekRange: weekRange,
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
  Future<void> setWeeklyLimit(WeeklyLimit limit, ExpenseProvider expenseProvider) async {
    await _db.addWeeklyLimit(limit);
    await loadWeeklyLimits();
    await updateWeeklyNotification(expenseProvider);
  }
  
  // Add or update monthly limit
  Future<void> setMonthlyLimit(MonthlyLimit limit, ExpenseProvider expenseProvider) async {
    await _db.addMonthlyLimit(limit);
    await loadMonthlyLimits();
    await updateWeeklyNotification(expenseProvider);
  }

  // Delete weekly limit
  Future<void> deleteWeeklyLimit(String id, ExpenseProvider expenseProvider) async {
    // Get the limit to find its categoryId before deletion
    final limit = _db.getWeeklyLimitById(id);
    
    await _db.deleteWeeklyLimit(id);
    await loadWeeklyLimits();
    
    // Cancel the notification for this category
    if (limit != null) {
      await NotificationService().cancelLimitNotification(limit.categoryId);
    }
    
    await updateWeeklyNotification(expenseProvider);
  }

  // Delete monthly limit
  Future<void> deleteMonthlyLimit(String id, ExpenseProvider expenseProvider) async {
    // Get the limit to find its categoryId before deletion
    final limit = _db.getMonthlyLimitById(id);
    
    await _db.deleteMonthlyLimit(id);
    await loadMonthlyLimits();
    
    // Cancel the notification for this category
    if (limit != null) {
      await NotificationService().cancelLimitNotification(limit.categoryId);
    }
    
    await updateWeeklyNotification(expenseProvider);
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

  // Calculate actual wallet balance (Initial + Income - Expense)
  double getCurrentBalance() {
    if (_currentBudget == null) return 0.0;
    
    return _db.getCurrentBalanceForMonth(
      _currentBudget!.month,
      _currentBudget!.year,
      _currentBudget!.initialBalance,
    );
  }

  // Calculate effective balance (ОСТАТОК = Wallet - Reserved Limits - Unpaid Fixed)
  double getEffectiveBalance(ExpenseProvider expenseProvider) {
    final walletBalance = getCurrentBalance();
    final reservedLimits = getTotalReservedLimits(expenseProvider);
    final unpaidFixed = getUnpaidFixedExpenses();
    return walletBalance - reservedLimits - unpaidFixed;
  }

  // Calculate safe daily budget
  double getSafeDailyBudget(ExpenseProvider expenseProvider) {
    if (_currentBudget == null) return 0.0;
    
    final currentBalance = getCurrentBalance();
    return _currentBudget!.calculateSafeDailyBudget(
      currentBalance,
      fixedExpensesTotal: getUnpaidFixedExpenses(),
    );
  }

  // Calculate safe daily budget accounting for Limits
  double getSmartSafeDailyBudget(ExpenseProvider expenseProvider) {
    if (_currentBudget == null) return 0.0;
    
    // Valid balance (already deducted fixed & reserved)
    final effectiveBalance = getEffectiveBalance(expenseProvider);
     
     return _currentBudget!.calculateSafeDailyBudget(effectiveBalance, fixedExpensesTotal: 0.0);
  }

  // Calculate total reserved amount (limit - spent)
  double getTotalReservedLimits(ExpenseProvider expenseProvider) {
    if (_currentBudget == null) return 0.0;
    final daysInMonth = _currentBudget!.getTotalDaysInMonth();
    double reserved = 0.0;
    
    for (var limit in _weeklyLimits.where((l) => l.isActive)) {
       final monthlyQuota = (limit.limitAmount / 7.0) * daysInMonth;
       final spentThisMonth = expenseProvider.transactions
           .where((t) => t.categoryId == limit.categoryId && t.type == TransactionType.expense)
           .fold(0.0, (sum, t) => sum + t.amount);
       final remainingReserved = (monthlyQuota - spentThisMonth).clamp(0.0, double.infinity);
       reserved += remainingReserved;
    }
    
    for (var limit in _monthlyLimits.where((l) => l.isActive)) {
       final spentThisMonth = expenseProvider.transactions
           .where((t) => t.categoryId == limit.categoryId && t.type == TransactionType.expense)
           .fold(0.0, (sum, t) => sum + t.amount);
       final remaining = (limit.limitAmount - spentThisMonth).clamp(0.0, double.infinity);
       reserved += remaining;
     }
     
     return reserved;
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

  // Calculate total spent against active limits
  double getTotalLimitsSpent(ExpenseProvider expenseProvider) {
    if (_currentBudget == null) return 0.0;
    final daysInMonth = _currentBudget!.getTotalDaysInMonth();
    double totalSpent = 0.0;

    // Weekly Limits
    for (var limit in _weeklyLimits.where((l) => l.isActive)) {
       // We only care about spending in THIS month for the limit categories
       // Ideally we sum up all expenses in that category for the whole month
       // Because 'Quota' is estimated for the whole month.
       final spentInMonth = expenseProvider.transactions
           .where((t) => t.categoryId == limit.categoryId && t.type == TransactionType.expense)
           .fold(0.0, (sum, t) => sum + t.amount);
       totalSpent += spentInMonth;
    }

    // Monthly Limits
    for (var limit in _monthlyLimits.where((l) => l.isActive)) {
       // Avoid double counting if category implies both (though unlikely)
        if (_weeklyLimits.any((wl) => wl.isActive && wl.categoryId == limit.categoryId)) continue;

       final spentInMonth = expenseProvider.transactions
           .where((t) => t.categoryId == limit.categoryId && t.type == TransactionType.expense)
           .fold(0.0, (sum, t) => sum + t.amount);
       totalSpent += spentInMonth;
    }
    
    return totalSpent;
  }

  // Calculate limits stats for a specific historical month
  // Returns { 'quota': double, 'spent': double, 'breakdown': List<Map> }
  Map<String, dynamic> getLimitsStatsForMonth(int month, int year, ExpenseProvider expenseProvider) {
    // Approximation: Use CURRENT active limits applied to historical data.
    double limitsQuota = 0.0;
    double limitsSpent = 0.0;
    
    final List<Map<String, dynamic>> breakdown = [];

    // Monthly Limits
    final monthlyLimits = _db.getAllMonthlyLimits().where((l) => l.isActive).toList();
    for (var limit in monthlyLimits) {
       limitsQuota += limit.limitAmount;
       final limitSpent = _db.getTransactionsForMonth(month, year)
         .where((t) => t.categoryId == limit.categoryId && t.type == TransactionType.expense)
         .fold(0.0, (sum, t) => sum + t.amount);
       limitsSpent += limitSpent;
       
       final category = _db.getCategoryById(limit.categoryId);
       breakdown.add({
         'name': category?.name ?? 'Unknown',
         'spent': limitSpent,
         'quota': limit.limitAmount,
         'color': category?.color,
         'icon': category?.icon,
       });
    }

    // Weekly Limits
    final weeklyLimits = _db.getAllWeeklyLimits().where((l) => l.isActive).toList();
    // Estimate monthly quota for weekly limits
    int daysInMonth = DateTime(year, month + 1, 0).day;
    
    for (var limit in weeklyLimits) {
      if (monthlyLimits.any((ml) => ml.categoryId == limit.categoryId)) continue; 
      
      final monthlyEquivalent = (limit.limitAmount / 7.0) * daysInMonth;
      limitsQuota += monthlyEquivalent;
      
      final limitSpent = _db.getTransactionsForMonth(month, year)
         .where((t) => t.categoryId == limit.categoryId && t.type == TransactionType.expense)
         .fold(0.0, (sum, t) => sum + t.amount);
      limitsSpent += limitSpent;

      final category = _db.getCategoryById(limit.categoryId);
      breakdown.add({
         'name': category?.name ?? 'Unknown',
         'spent': limitSpent,
         'quota': monthlyEquivalent,
         'color': category?.color,
         'icon': category?.icon,
      });
    }
    
    return {
      'quota': limitsQuota,
      'spent': limitsSpent,
      'breakdown': breakdown,
    };
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
  BudgetStatus getBudgetStatus(double todayExpense, ExpenseProvider expenseProvider) {
    if (_currentBudget == null) return BudgetStatus.neutral;
    final effectiveBalance = getEffectiveBalance(expenseProvider);
    return _currentBudget!.getBudgetStatus(
      effectiveBalance,
      todayExpense,
      fixedExpensesTotal: 0.0,
    );
  }

  // Check budget status and update notifications
  Future<void> checkBudgetStatus(ExpenseProvider expenseProvider) async {
    if (_currentBudget == null) return;
    
    // Redirect to the full update logic which handles the 'Widget' (Persistent notification)
    await updateWeeklyNotification(expenseProvider);
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
  
  // Toggle paid status
  Future<void> toggleFixedExpensePaid(String id) async {
    if (_currentBudget == null) return;
    
    final isPaid = _db.isFixedExpensePaid(id, _currentBudget!.month, _currentBudget!.year);
    await _db.setFixedExpensePaid(id, _currentBudget!.month, _currentBudget!.year, !isPaid);
    notifyListeners();
  }

  // Check paid status
  bool isFixedExpensePaid(String id) {
     if (_currentBudget == null) return false;
     return _db.isFixedExpensePaid(id, _currentBudget!.month, _currentBudget!.year);
  }

  // Get total fixed expenses
  double getTotalFixedExpenses() {
    return _db.getTotalFixedExpensesForMonth();
  }
  
  // Get ONLY unpaid fixed expenses
  double getUnpaidFixedExpenses() {
    if (_currentBudget == null) return 0.0;
    return _db.getUnpaidFixedExpensesTotal(_currentBudget!.month, _currentBudget!.year);
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
