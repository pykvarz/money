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

  @override
  String toString() {
    return 'WeeklyLimit(categoryId: $categoryId, limit: $limitAmount, weekStart: $weekStartDate, active: $isActive)';
  }
}
