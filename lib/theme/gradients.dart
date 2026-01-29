import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  // Purple to Blue (SafeDailyBudgetCard) - всегда яркий для контраста
  static const LinearGradient purpleBlue = LinearGradient(
    colors: [AppColors.primaryPurple, AppColors.primaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Green to Emerald (SavingsAccumulatorCard) - всегда яркий
  static const LinearGradient greenEmerald = LinearGradient(
    colors: [AppColors.successGreen, AppColors.emerald],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Adaptive gradient for MonthSummaryCard based on theme
  static LinearGradient lightBlueAdaptive(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (isDark) {
      // Темная тема: ЗНАЧИТЕЛЬНО светлее для контраста с темным фоном
      return const LinearGradient(
        colors: [Color(0xFF334155), Color(0xFF1E293B)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else {
      // Светлая тема: белый с легким голубым
      return const LinearGradient(
        colors: [Color(0xFFFAFAFA), Color(0xFFEFF6FF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
  }
  
  // Progress Bar Gradient (Green → Yellow → Red)
  static LinearGradient progressGradient(double percent) {
    if (percent < 0.7) {
      return const LinearGradient(colors: [AppColors.successGreen, AppColors.successGreen]);
    } else if (percent < 0.9) {
      return const LinearGradient(colors: [AppColors.warning, AppColors.warning]);
    } else {
      return const LinearGradient(colors: [AppColors.error, AppColors.error]);
    }
  }
}
