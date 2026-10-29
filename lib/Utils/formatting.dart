String formatHour(DateTime time) {
  int hour = time.hour;
  final period = hour >= 12 ? 'PM' : 'AM';
  hour = hour % 12;
  if (hour == 0) hour = 12;
  return '$hour $period';
}

const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

String dayLabel(DateTime time) {
  if (isToday(time)) {
    return 'Today';
  }
  return _weekdays[time.weekday - 1];
}

String shortWeekday(DateTime time) => _weekdays[time.weekday - 1].substring(0, 3);

/// Midnight at the start of [time]'s calendar day, for comparing/keying days.
DateTime dateOnly(DateTime time) => DateTime(time.year, time.month, time.day);

bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

bool isToday(DateTime time) => isSameDay(time, DateTime.now());
