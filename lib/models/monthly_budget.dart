import 'package:hive/hive.dart';

part 'monthly_budget.g.dart';

@HiveType(typeId: 3)
class MonthlyBudget extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late int month;

  @HiveField(2)
  late int year;

  @HiveField(3)
  double? targetRemainingBalance;

  @HiveField(4)
  late double initialBalance;

  @HiveField(5)
  late DateTime createdAt;

  @HiveField(6, defaultValue: 0.0)
  double projectedFixedExpenses;

  MonthlyBudget({
    required this.id,
    required this.month,
    required this.year,
    this.targetRemainingBalance,
    this.initialBalance = 0.0,
    required this.createdAt,
    this.projectedFixedExpenses = 0.0,
  });

  // Check if this is the current month's budget
  bool isCurrentMonth() {
    final now = DateTime.now();
    return month == now.month && year == now.year;
  }

  // Get total days in this month
  int getTotalDaysInMonth() {
    return DateTime(year, month + 1, 0).day;
  }

  // Get days remaining in month (including today)
  int getDaysLeftInMonth() {
    if (!isCurrentMonth()) return 0;
    
    final now = DateTime.now();
    final lastDay = DateTime(year, month + 1, 0);
    return lastDay.day - now.day + 1; // +1 to include today
  }

  // Calculate safe daily budget
  // Formula: (currentBalance - targetRemaining - fixedExpenses) / daysLeft
  // This reserves money for both target savings AND fixed monthly bills
  double calculateSafeDailyBudget(double currentBalance, {double fixedExpensesTotal = 0.0}) {
    if (targetRemainingBalance == null) return 0.0;
    
    final daysLeft = getDaysLeftInMonth();
    if (daysLeft <= 0) return 0.0; // No days left or not current month
    
    // Reserve money for target AND fixed expenses (rent, utilities, etc.)
    final availableToSpend = currentBalance - targetRemainingBalance! - fixedExpensesTotal;
    return availableToSpend / daysLeft;
  }

  // Get status indicator for UI (Green/Yellow/Red)
  // Based on whether we're on track with our target
  BudgetStatus getBudgetStatus(double currentBalance, double totalExpenseToday, {double fixedExpensesTotal = 0.0}) {
    if (targetRemainingBalance == null) return BudgetStatus.neutral;
    
    final safeDailyBudget = calculateSafeDailyBudget(currentBalance, fixedExpensesTotal: fixedExpensesTotal);
    
    if (totalExpenseToday <= safeDailyBudget * 0.8) {
      return BudgetStatus.good; // Under 80% of safe budget - GREEN
    } else if (totalExpenseToday <= safeDailyBudget) {
      return BudgetStatus.warning; // Between 80-100% - YELLOW
    } else {
      return BudgetStatus.danger; // Over safe budget - RED
    }
  }

  @override
  String toString() {
    return 'MonthlyBudget(month: $month/$year, target: $targetRemainingBalance, initial: $initialBalance)';
  }
}

enum BudgetStatus {
  good,    // Green
  warning, // Yellow
  danger,  // Red
  neutral, // No target set
}
