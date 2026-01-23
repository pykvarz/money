import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _kztFormat = NumberFormat.currency(
    symbol: 'KZT',
    decimalDigits: 0,
    locale: 'kk_KZ',
  );

  static final NumberFormat _kztFormatWithDecimals = NumberFormat.currency(
    symbol: 'KZT',
    decimalDigits: 2,
    locale: 'kk_KZ',
  );

  // Format amount as KZT without decimals (e.g., "5,000 KZT")
  static String formatKZT(double amount) {
    return _kztFormat.format(amount).replaceAll('KZT', '').trim() + ' KZT';
  }

  // Format amount with decimals (e.g., "2,062.50 KZT")
  static String formatKZTWithDecimals(double amount) {
    return _kztFormatWithDecimals.format(amount).replaceAll('KZT', '').trim() + ' KZT';
  }

  // Format compact (e.g., "5K", "1.2M")
  static String formatCompact(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M KZT';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K KZT';
    }
    return formatKZT(amount);
  }

  // Format date (e.g., "23 Jan 2026")
  static String formatDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  // Format month year (e.g., "January 2026")
  static String formatMonthYear(int month, int year) {
    return DateFormat('MMMM yyyy').format(DateTime(year, month));
  }

  // Format time (e.g., "14:30")
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }
}
