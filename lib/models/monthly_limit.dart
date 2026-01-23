import 'package:hive/hive.dart';

part 'monthly_limit.g.dart';

@HiveType(typeId: 7)
class MonthlyLimit extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String categoryId;

  @HiveField(2)
  late double limitAmount;

  @HiveField(3)
  late bool isActive;

  MonthlyLimit({
    required this.id,
    required this.categoryId,
    required this.limitAmount,
    this.isActive = true,
  });

  @override
  String toString() {
    return 'MonthlyLimit(categoryId: $categoryId, limit: $limitAmount, active: $isActive)';
  }
}
