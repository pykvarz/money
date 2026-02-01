import 'package:flutter/material.dart';

class AppColors {
  // Seed Color
  static const Color seedDeepPurple = Colors.deepPurple;
  static const Color primary = seedDeepPurple; // Primary brand color

  // Semantic Colors
  static const Color primaryPurple = Color(0xFF6750A4);
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color emerald = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFFBC02D);
  static const Color error = Color(0xFFB3261E);

  // Custom semantics to ensure consistency across the app
  static const Color expense = error; 
  static const Color income = successGreen;
  
  // Gradients
  static const List<Color> savingsGradient = [
    Color(0xFF9D50DD),
    Color(0xFFE01CD5),
  ];
  
  static const List<Color> cardGradient = [
    primaryPurple,
    Color(0xFF7E57C2),
  ];
}
