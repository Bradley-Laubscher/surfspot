String formatHour(DateTime time) {
  int hour = time.hour;
  final period = hour >= 12 ? 'PM' : 'AM';
  hour = hour % 12;
  if (hour == 0) hour = 12;
  return '$hour $period';
}

const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

String dayLabel(DateTime time) {
  final now = DateTime.now();
  if (time.year == now.year && time.month == now.month && time.day == now.day) {
    return 'Today';
  }
  return _weekdays[time.weekday - 1];
}
