import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'fixed_expense.g.dart';

@HiveType(typeId: 6)
class FixedExpense extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name; // e.g., "Аренда", "Интернет"

  @HiveField(2)
  double amount;

  // Index 3 was dueDay - skipped to maintain compatibility
  
  @HiveField(4)
  bool isActive;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  String? note;

  FixedExpense({
    required this.id,
    required this.name,
    required this.amount,
    this.isActive = true,
    required this.createdAt,
    this.note,
  });

  factory FixedExpense.create({
    required String name,
    required double amount,
    String? note,
  }) {
    return FixedExpense(
      id: const Uuid().v4(),
      name: name,
      amount: amount,
      isActive: true,
      createdAt: DateTime.now(),
      note: note,
    );
  }

  FixedExpense copyWith({
    String? name,
    double? amount,
    bool? isActive,
    String? note,
  }) {
    return FixedExpense(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      note: note ?? this.note,
    );
  }
}
