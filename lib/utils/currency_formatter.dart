import 'package:intl/intl.dart';

/// Clean utility class for formatting financial amounts across Spendly
class CurrencyFormatter {
  CurrencyFormatter._();

  static const String defaultCurrencySymbol = '\$';
  static final NumberFormat _standardFormat = NumberFormat.currency(
    symbol: defaultCurrencySymbol,
    decimalDigits: 2,
  );

  static final NumberFormat _wholeNumberFormat = NumberFormat.currency(
    symbol: defaultCurrencySymbol,
    decimalDigits: 0,
  );

  static final NumberFormat _compactFormat = NumberFormat.compactSimpleCurrency(
    name: 'USD',
  );

  /// Formats amount into standard currency string: e.g. $1,250.00
  static String format(double amount, {bool showDecimals = true, String? symbol}) {
    if (symbol != null && symbol != defaultCurrencySymbol) {
      final customFormat = NumberFormat.currency(
        symbol: symbol,
        decimalDigits: showDecimals ? 2 : 0,
      );
      return customFormat.format(amount);
    }
    return showDecimals ? _standardFormat.format(amount) : _wholeNumberFormat.format(amount);
  }

  /// Formats amount with explicit sign: e.g. +$1,250.00 or -$45.20
  static String formatSigned(double amount, {bool isExpense = false}) {
    final absFormatted = format(amount.abs());
    if (isExpense || amount < 0) {
      return '-$absFormatted';
    } else {
      return '+$absFormatted';
    }
  }

  /// Formats large numbers compactly: e.g. $12.4K, $1.2M
  static String formatCompact(double amount) {
    return _compactFormat.format(amount);
  }
}
