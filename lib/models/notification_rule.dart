import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'notification_rule.g.dart';

@HiveType(typeId: 10)
class NotificationRule {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String keyword;

  @HiveField(2)
  late String categoryId;

  @HiveField(3)
  late bool isActive;

  NotificationRule({
    String? id,
    required this.keyword,
    required this.categoryId,
    this.isActive = true,
  }) {
    this.id = id ?? const Uuid().v4();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'keyword': keyword,
      'categoryId': categoryId,
      'isActive': isActive,
    };
  }

  factory NotificationRule.fromJson(Map<String, dynamic> json) {
    return NotificationRule(
      id: json['id'],
      keyword: json['keyword'],
      categoryId: json['categoryId'],
      isActive: json['isActive'] ?? true,
    );
  }
}
