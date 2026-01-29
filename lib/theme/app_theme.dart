import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // Color Scheme
    colorScheme: ColorScheme.light(
      primary: AppColors.primaryPurple,
      secondary: AppColors.primaryBlue,
      tertiary: AppColors.successGreen,
      surface: Colors.white, // Карточки белые
      surfaceContainerHighest: AppColors.lightBackground, // Фон приложения светло-серый
      background: AppColors.lightBackground, // Фон экранов светло-серый (#F9FAFB)
      error: AppColors.error,
    ),
    
    // Background
    scaffoldBackgroundColor: AppColors.lightBackground, // Светло-серый фон для контраста с белыми карточками
    
    // Typography
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold),
      displayMedium: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold),
      displaySmall: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold),
      headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.normal),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.normal),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.normal),
    ),
    
    // Card Theme
    cardTheme: CardThemeData(
      color: Colors.white, // Явно белый цвет для карточек
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.black.withOpacity(0.1),
    ),
    
    // App Bar Theme
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),
    
    // FAB Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
  
  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    
    // Color Scheme
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryPurple,
      secondary: AppColors.primaryBlue,
      tertiary: AppColors.successGreen,
      surface: AppColors.darkSurface, // #334155
      surfaceContainerHighest: AppColors.darkSurfaceContainer,
      background: AppColors.darkBackground, // #1E293B
      error: AppColors.error,
    ),
    
    // Background
    scaffoldBackgroundColor: AppColors.darkBackground, // #1E293B
    
    // Typography (Google Fit style - brighter text)
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
      displayMedium: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
      displaySmall: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
      titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), // Жирнее
      titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white), // Полностью белый
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.white),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.grey[200]), // МАКСИМАЛЬНО ярко! Grey[200]
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.grey[300]), // Ярче - Grey[300]
    ),
    
    // Card Theme - increased elevation for depth
    cardTheme: CardThemeData(
      color: AppColors.darkSurface, // #334155 (СВЕТЛЕЕ фона для контраста)
      elevation: 4, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.black.withOpacity(0.3),
    ),
    
    // App Bar Theme
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0, // Не менять цвет при скролле
      backgroundColor: AppColors.darkBackground, // Цвет фона (#1E293B)
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    
    // FAB Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkInputFill, // Осветлено с #374151 до #4A5568
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}
