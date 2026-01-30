import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _kztFormat = NumberFormat.currency(
    symbol: '₸',
    decimalDigits: 0,
    locale: 'kk_KZ',
  );

  static final NumberFormat _kztFormatWithDecimals = NumberFormat.currency(
    symbol: '₸',
    decimalDigits: 2,
    locale: 'kk_KZ',
  );

  // Format amount as ₸ without decimals (e.g., "5,000 ₸")
  static String formatKZT(double amount) {
    return _kztFormat.format(amount).replaceAll('₸', '').trim() + ' ₸';
  }

  // Format amount with decimals (e.g., "2,062.50 ₸")
  static String formatKZTWithDecimals(double amount) {
    return _kztFormatWithDecimals.format(amount).replaceAll('₸', '').trim() + ' ₸';
  }

  // Format compact (e.g., "5K", "1.2M")
  static String formatCompact(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M ₸';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K ₸';
    }
    return formatKZT(amount);
  }

  // Format date (e.g., "23 января 2026")
  static String formatDate(DateTime date) {
    return DateFormat('d MMM yyyy', 'ru_RU').format(date);
  }

  // Format month year (e.g., "Январь 2026")
  static String formatMonthYear(int month, int year) {
    final date = DateTime(year, month);
    final monthName = DateFormat('MMMM', 'ru_RU').format(date);
    // Capitalize first letter
    return '${monthName[0].toUpperCase()}${monthName.substring(1)} ${year}';
  }

  // Format time (e.g., "14:30")
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }
}
