import 'package:surfspot/Utils/compass.dart';

/// One hour of parsed forecast data for a spot.
class HourlyReading {
  final DateTime time;
  final double waveHeight;
  final double wavePeriod;
  final double swellDirection;
  final double? windSpeed;
  final double? windDirection;

  const HourlyReading({
    required this.time,
    required this.waveHeight,
    required this.wavePeriod,
    required this.swellDirection,
    required this.windSpeed,
    required this.windDirection,
  });
}

enum SurfRating { good, fair, poor }

extension SurfRatingLabel on SurfRating {
  String get label {
    switch (this) {
      case SurfRating.good:
        return 'Good';
      case SurfRating.fair:
        return 'Fair';
      case SurfRating.poor:
        return 'Poor';
    }
  }
}

/// An hour of forecast data plus its computed surf-quality score.
class ScoredHour {
  final HourlyReading reading;
  final int points;
  final SurfRating rating;

  const ScoredHour({required this.reading, required this.points, required this.rating});
}

double _asDouble(dynamic value) => (value as num).toDouble();
double? _asDoubleOrNull(dynamic value) => value == null ? null : (value as num).toDouble();

/// Parses the merged `hourly` map returned by fetchSurfForecast into a
/// typed, null-safe list.
List<HourlyReading> parseHourlyReadings(Map<String, dynamic> hourly) {
  final times = hourly['time'] as List<dynamic>;
  final heights = hourly['swell_wave_height'] as List<dynamic>;
  final periods = hourly['swell_wave_period'] as List<dynamic>;
  final swellDirections = hourly['swell_wave_direction'] as List<dynamic>;
  final windSpeeds = hourly['wind_speed_10m'] as List<dynamic>;
  final windDirections = hourly['wind_direction_10m'] as List<dynamic>;

  return List.generate(times.length, (i) {
    return HourlyReading(
      time: DateTime.parse(times[i]),
      waveHeight: _asDouble(heights[i]),
      wavePeriod: _asDouble(periods[i]),
      swellDirection: _asDouble(swellDirections[i]),
      windSpeed: _asDoubleOrNull(windSpeeds[i]),
      windDirection: _asDoubleOrNull(windDirections[i]),
    );
  });
}

/// Scores an hour of conditions against a spot's known best swell/wind
/// direction and its difficulty rating, rather than one fixed threshold for
/// every spot. Swell direction and wind are the biggest levers on whether a
/// given height/period actually produces a clean, rideable wave at THIS
/// spot, so a mismatch there can outweigh otherwise "good" numbers.
ScoredHour scoreHour(
  HourlyReading reading, {
  required String bestSwell,
  required String bestWind,
  required int difficultyRating,
}) {
  int points = 0;

  // Ideal wave height band scales with the spot's difficulty rating -
  // beginner-friendly beach breaks want smaller, softer swell than
  // advanced reef/point breaks.
  final idealMin = 0.4 + (difficultyRating - 1) * 0.4;
  final idealMax = 1.2 + (difficultyRating - 1) * 0.65;
  if (reading.waveHeight >= idealMin && reading.waveHeight <= idealMax) {
    points += 2;
  } else if (reading.waveHeight >= idealMin * 0.5 && reading.waveHeight <= idealMax * 1.5) {
    points += 1;
  }

  // Longer period swells are more organised groundswell energy rather
  // than short-interval wind swell.
  if (reading.wavePeriod > 10) {
    points += 2;
  } else if (reading.wavePeriod > 7) {
    points += 1;
  }

  // Swell arriving from well outside the spot's ideal window will refract,
  // close out, or simply not reach the break cleanly.
  if (directionMatches(reading.swellDirection, bestSwell, tolerance: 35)) {
    points += 2;
  } else if (!directionMatches(reading.swellDirection, bestSwell, tolerance: 70)) {
    points -= 2;
  }

  // Wind is the biggest factor in whether a swell is clean or blown out.
  final windSpeed = reading.windSpeed;
  final windDirection = reading.windDirection;
  if (windSpeed != null && windDirection != null) {
    final isOffshore = directionMatches(windDirection, bestWind, tolerance: 45);
    if (windSpeed < 10) {
      points += 1; // light wind rarely spoils a session regardless of direction
    } else if (isOffshore) {
      points += windSpeed < 25 ? 2 : 1;
    } else {
      points -= windSpeed > 20 ? 2 : 1;
    }
  }

  final rating = points >= 6 ? SurfRating.good : (points >= 3 ? SurfRating.fair : SurfRating.poor);
  return ScoredHour(reading: reading, points: points, rating: rating);
}

/// Groups a chronological list of scored hours into one list per calendar day.
List<List<ScoredHour>> groupByDay(List<ScoredHour> hours) {
  if (hours.isEmpty) return [];
  final List<List<ScoredHour>> days = [];
  List<ScoredHour> currentDay = [hours.first];
  DateTime currentDayStart = hours.first.reading.time;

  for (final hour in hours.skip(1)) {
    if (hour.reading.time.day == currentDayStart.day) {
      currentDay.add(hour);
    } else {
      days.add(currentDay);
      currentDay = [hour];
      currentDayStart = hour.reading.time;
    }
  }
  days.add(currentDay);
  return days;
}

/// The best contiguous [windowSize]-hour stretch within [hours], scored by
/// total points. Used to find "the best few hours to surf today" per spot.
class SurfWindow {
  final ScoredHour start;
  final ScoredHour end;
  final ScoredHour bestHour;
  final int totalPoints;

  const SurfWindow({required this.start, required this.end, required this.bestHour, required this.totalPoints});
}

SurfWindow? bestWindowInDay(List<ScoredHour> dayHours, {int windowSize = 3}) {
  // Only consider daylight hours - surf reports about the middle of the
  // night aren't useful to a user deciding when to go.
  final daylight = dayHours.where((h) => h.reading.time.hour >= 6 && h.reading.time.hour <= 19).toList();
  if (daylight.length < windowSize) return null;

  SurfWindow? best;
  for (int i = 0; i <= daylight.length - windowSize; i++) {
    final window = daylight.sublist(i, i + windowSize);
    final total = window.fold<int>(0, (sum, h) => sum + h.points);
    final bestHour = window.reduce((a, b) => a.points >= b.points ? a : b);
    if (best == null || total > best.totalPoints) {
      best = SurfWindow(start: window.first, end: window.last, bestHour: bestHour, totalPoints: total);
    }
  }
  return best;
}
