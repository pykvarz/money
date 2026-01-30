import 'package:flutter/material.dart';

class AppDesign {
  // Border Radii
  static const double radiusXS = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 16.0;
  static const double radiusL = 24.0;
  static const double radiusXL = 32.0;

  static BorderRadius get brS => BorderRadius.circular(radiusS);
  static BorderRadius get brM => BorderRadius.circular(radiusM);
  static BorderRadius get brL => BorderRadius.circular(radiusL);
  static BorderRadius get brXL => BorderRadius.circular(radiusXL);

  // Padding & Margins
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  // Shadows
  static List<BoxShadow> get shadowStandard => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowDeep => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> shadowGlow(Color color) => [
     BoxShadow(
      color: color.withOpacity(0.3),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  // Colors helpers
  static Color getCardColor(BuildContext context) {
    return Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;
  }
}
