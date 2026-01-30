import 'package:flutter/material.dart';

class AppColors {
  // Seed Color
  static const Color seedDeepPurple = Colors.deepPurple;
  static const Color primary = seedDeepPurple; // Primary brand color

  // Custom semantics to ensure consistency across the app
  static const Color expense = Color(0xFFB3261E); // Material 3 Error equivalent
  static const Color income = Color(0xFF2E7D32);  // Standard Green
  
  // Gradients
  static const List<Color> savingsGradient = [
    Color(0xFF9D50DD),
    Color(0xFFE01CD5),
  ];
  
  static const List<Color> cardGradient = [
    Color(0xFF6750A4),
    Color(0xFF7E57C2),
  ];
}
