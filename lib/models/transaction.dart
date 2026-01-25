import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 4)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
}

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late double amount;

  @HiveField(2)
  late TransactionType type;

  @HiveField(3)
  late String categoryId;

  @HiveField(4)
  late DateTime date;

  @HiveField(5)
  String? note;

  @HiveField(6)
  late DateTime createdAt;

  Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    this.note,
    required this.createdAt,
  });

  // Helper to check if transaction belongs to a specific month
  bool isInMonth(int month, int year) {
    return date.month == month && date.year == year;
  }

  // Helper to get week start date (Monday)
  DateTime getWeekStartDate() {
    final weekday = date.weekday; // Monday = 1, Sunday = 7
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  @override
  String toString() {
    return 'Transaction(id: $id, amount: $amount, type: $type, date: $date, note: $note)';
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type.index, // Store enum index
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      amount: json['amount'],
      type: TransactionType.values[json['type']],
      categoryId: json['categoryId'],
      date: DateTime.parse(json['date']),
      note: json['note'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
