import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.seedDeepPurple,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      // cardTheme: CardTheme(
      //   elevation: 2,
      //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      //   clipBehavior: Clip.antiAlias,
      //   margin: EdgeInsets.zero, // We control margin via padding usually
      // ),
      // Enhance Dialogs
      // dialogTheme: DialogTheme(
      //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      // ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.seedDeepPurple,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      // cardTheme: CardTheme(
      //   elevation: 2,
      //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      //   clipBehavior: Clip.antiAlias,
      //    margin: EdgeInsets.zero,
      // ),
       // dialogTheme: DialogTheme(
       //  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
       // ),
    );
  }
}
