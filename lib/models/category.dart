import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 5)
enum CategoryType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
}

@HiveType(typeId: 1)
class Category extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late int iconCodePoint;

  @HiveField(3)
  late int colorValue;

  @HiveField(4)
  late CategoryType type;

  @HiveField(5)
  late bool isCustom;

  Category({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    required this.type,
    this.isCustom = false,
  });

  // Getters for UI usage
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  @override
  String toString() {
    return 'Category(id: $id, name: $name, type: $type, isCustom: $isCustom)';
  }

  // Predefined categories factory
  static List<Category> getDefaultCategories() {
    return [
      // Expense categories
      Category(
        id: 'cat_food',
        name: 'Food',
        iconCodePoint: Icons.restaurant.codePoint,
        colorValue: Colors.orange.toARGB32(),
        type: CategoryType.expense,
        isCustom: false,
      ),
      Category(
        id: 'cat_transport',
        name: 'Transport',
        iconCodePoint: Icons.directions_car.codePoint,
        colorValue: Colors.blue.toARGB32(),
        type: CategoryType.expense,
        isCustom: false,
      ),
      Category(
        id: 'cat_utilities',
        name: 'Utilities',
        iconCodePoint: Icons.lightbulb.codePoint,
        colorValue: Colors.yellow.toARGB32(),
        type: CategoryType.expense,
        isCustom: false,
      ),
      Category(
        id: 'cat_entertainment',
        name: 'Entertainment',
        iconCodePoint: Icons.movie.codePoint,
        colorValue: Colors.purple.toARGB32(),
        type: CategoryType.expense,
        isCustom: false,
      ),
      Category(
        id: 'cat_health',
        name: 'Health',
        iconCodePoint: Icons.medical_services.codePoint,
        colorValue: Colors.red.toARGB32(),
        type: CategoryType.expense,
        isCustom: false,
      ),
      Category(
        id: 'cat_shopping',
        name: 'Shopping',
        iconCodePoint: Icons.shopping_bag.codePoint,
        colorValue: Colors.pink.toARGB32(),
        type: CategoryType.expense,
        isCustom: false,
      ),
      // Income category
      Category(
        id: 'cat_salary',
        name: 'Salary',
        iconCodePoint: Icons.attach_money.codePoint,
        colorValue: Colors.green.toARGB32(),
        type: CategoryType.income,
        isCustom: false,
      ),
    ];
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      'type': type.index,
      'isCustom': isCustom,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      iconCodePoint: json['iconCodePoint'],
      colorValue: json['colorValue'],
      type: CategoryType.values[json['type']],
      isCustom: json['isCustom'] ?? false,
    );
  }
}
