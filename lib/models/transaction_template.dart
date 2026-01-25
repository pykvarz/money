import 'package:hive/hive.dart';
import 'category.dart';

part 'transaction_template.g.dart';

@HiveType(typeId: 8)
class TransactionTemplate extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name; // e.g., "Coffee", "Bus"

  @HiveField(2)
  late double amount;

  @HiveField(3)
  late String categoryId;

  @HiveField(4)
  String? note;

  TransactionTemplate({
    required this.id,
    required this.name,
    required this.amount,
    required this.categoryId,
    this.note,
  });
}
