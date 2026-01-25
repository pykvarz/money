import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'savings_goal.g.dart';

@HiveType(typeId: 9)
class SavingsGoal extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late double targetAmount;

  @HiveField(3)
  late double currentAmount;

  @HiveField(4)
  late int iconCodePoint; // Store IconData.codePoint

  @HiveField(5)
  late int colorValue; // Store Color.value

  @HiveField(6)
  late bool isCompleted;

  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.iconCodePoint,
    required this.colorValue,
    this.isCompleted = false,
  });

  // Helper to get IconData
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  // Helper to get Color
  Color get color => Color(colorValue);
  
  // Progress percentage (0.0 to 1.0)
  double get progress {
    if (targetAmount <= 0) return 0.0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }
}
