/// Small date/format helpers so the app doesn't need an extra package.
library;

extension DateHelpers on DateTime {
  static const List<String> _monthNames = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static const List<String> _dayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  String get monthShort => _monthNames[month];

  String get dayName => _dayNames[weekday - 1];

  String get dayShort => dayName.substring(0, 3);

  /// e.g. "7 Sep 2026"
  String get formatted => '$day $monthShort $year';

  /// e.g. "Sep 7"
  String get shortFormatted => '$monthShort $day';

  /// e.g. "14:30" — [minute] defaults to 0.
  String timeLabel([int minute = 0]) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// Whole days from now until this date (negative if in the past).
  int get daysFromNow {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(year, month, day);
    return target.difference(today).inDays;
  }
}
