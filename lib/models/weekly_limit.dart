import 'package:hive/hive.dart';

part 'weekly_limit.g.dart';

@HiveType(typeId: 2)
class WeeklyLimit extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String categoryId;

  @HiveField(2)
  late double limitAmount;

  @HiveField(3)
  late DateTime weekStartDate;

  @HiveField(4)
  late bool isActive;

  WeeklyLimit({
    required this.id,
    required this.categoryId,
    required this.limitAmount,
    required this.weekStartDate,
    this.isActive = true,
  });

  // Check if this limit is for the current week
  bool isCurrentWeek() {
    final now = DateTime.now();
    final currentWeekStart = _getWeekStart(now);
    return weekStartDate.year == currentWeekStart.year &&
        weekStartDate.month == currentWeekStart.month &&
        weekStartDate.day == currentWeekStart.day;
  }

  // Get Monday of a given week
  static DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday; // Monday = 1, Sunday = 7
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  // Factory to create limit for current week
  static WeeklyLimit forCurrentWeek({
    required String id,
    required String categoryId,
    required double limitAmount,
  }) {
    return WeeklyLimit(
      id: id,
      categoryId: categoryId,
      limitAmount: limitAmount,
      weekStartDate: _getWeekStart(DateTime.now()),
      isActive: true,
    );
  }

  // Calculate effective limit for a specific month and year
  double getEffectiveLimit(int month, int year) {
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 0);
    
    final weekStart = weekStartDate;
    final weekEnd = weekStartDate.add(const Duration(days: 6));
    
    // Find intersection of week and month
    final effectiveStart = weekStart.isBefore(monthStart) ? monthStart : weekStart;
    final effectiveEnd = weekEnd.isAfter(monthEnd) ? monthEnd : weekEnd;
    
    if (effectiveStart.isAfter(effectiveEnd)) return 0.0;
    
    final activeDaysInMonth = effectiveEnd.difference(effectiveStart).inDays + 1;
    return (limitAmount / 7.0) * activeDaysInMonth;
  }

  // Get the effective start and end dates for this week within a specific month
  Map<String, DateTime> getEffectiveDates(int month, int year) {
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 0);
    
    final weekStart = weekStartDate;
    final weekEnd = weekStartDate.add(const Duration(days: 6));
    
    final effectiveStart = weekStart.isBefore(monthStart) ? monthStart : weekStart;
    final effectiveEnd = weekEnd.isAfter(monthEnd) ? monthEnd : weekEnd;
    
    return {
      'start': effectiveStart,
      'end': effectiveEnd,
    };
  }

  @override
  String toString() {
    return 'WeeklyLimit(categoryId: $categoryId, limit: $limitAmount, weekStart: $weekStartDate, active: $isActive)';
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'limitAmount': limitAmount,
      'weekStartDate': weekStartDate.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory WeeklyLimit.fromJson(Map<String, dynamic> json) {
    return WeeklyLimit(
      id: json['id'],
      categoryId: json['categoryId'],
      limitAmount: json['limitAmount'],
      weekStartDate: DateTime.parse(json['weekStartDate']),
      isActive: json['isActive'] ?? true,
    );
  }
}
