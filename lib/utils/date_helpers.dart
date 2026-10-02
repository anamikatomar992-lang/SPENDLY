import 'package:intl/intl.dart';

/// Helper methods for handling date formatting and periods
class DateHelpers {
  DateHelpers._();

  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _shortDateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _dayMonthFormat = DateFormat('d MMM');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');

  /// Formats date into relative friendly format (Today, Yesterday, or "d MMM")
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final aDate = DateTime(date.year, date.month, date.day);

    if (aDate == today) {
      return 'Today, ${_timeFormat.format(date)}';
    } else if (aDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${_timeFormat.format(date)}';
    } else {
      return '${_dayMonthFormat.format(date)}, ${_timeFormat.format(date)}';
    }
  }

  /// Formats current month and year: e.g. "October 2026"
  static String formatMonthYear([DateTime? date]) {
    return _monthYearFormat.format(date ?? DateTime.now());
  }

  /// Short formatted date: e.g. "Oct 1, 2026"
  static String formatShort(DateTime date) {
    return _shortDateFormat.format(date);
  }

  /// Returns start of the current month
  static DateTime startOfMonth([DateTime? date]) {
    final d = date ?? DateTime.now();
    return DateTime(d.year, d.month, 1);
  }

  /// Returns end of the current month
  static DateTime endOfMonth([DateTime? date]) {
    final d = date ?? DateTime.now();
    return DateTime(d.year, d.month + 1, 0, 23, 59, 59);
  }
}
