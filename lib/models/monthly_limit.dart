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

  @HiveField(4, defaultValue: true)
  late bool showInNotification;

  MonthlyLimit({
    required this.id,
    required this.categoryId,
    required this.limitAmount,
    this.isActive = true,
    this.showInNotification = true,
  });

  @override
  String toString() {
    return 'MonthlyLimit(categoryId: $categoryId, limit: $limitAmount, active: $isActive)';
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'limitAmount': limitAmount,
      'isActive': isActive,
      'showInNotification': showInNotification,
    };
  }

  factory MonthlyLimit.fromJson(Map<String, dynamic> json) {
    return MonthlyLimit(
      id: json['id'],
      categoryId: json['categoryId'],
      limitAmount: json['limitAmount'],
      isActive: json['isActive'] ?? true,
      showInNotification: json['showInNotification'] ?? true,
    );
  }
}
