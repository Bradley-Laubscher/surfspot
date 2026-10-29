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

/// One contributing reason behind an hour's score, e.g. "Offshore North-East
/// wind (15 km/h)" worth +2. Recorded during scoring so recommendations can
/// explain themselves without re-deriving the thresholds.
class ScoreFactor {
  final String label;
  final int points;

  const ScoreFactor(this.label, this.points);
}

/// An hour of forecast data plus its computed surf-quality score.
class ScoredHour {
  final HourlyReading reading;
  final int points;
  final SurfRating rating;
  final List<ScoreFactor> factors;

  const ScoredHour({required this.reading, required this.points, required this.rating, this.factors = const []});
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
  final factors = <ScoreFactor>[];
  void add(String label, int value) {
    points += value;
    factors.add(ScoreFactor(label, value));
  }

  // Ideal wave height band scales with the spot's difficulty rating -
  // beginner-friendly beach breaks want smaller, softer swell than
  // advanced reef/point breaks.
  final idealMin = 0.4 + (difficultyRating - 1) * 0.4;
  final idealMax = 1.2 + (difficultyRating - 1) * 0.65;
  final height = "${reading.waveHeight.toStringAsFixed(1)}m swell";
  final sizeWord = reading.waveHeight < idealMin ? "small" : "big";
  if (reading.waveHeight >= idealMin && reading.waveHeight <= idealMax) {
    add("$height - ideal size for this spot", 2);
  } else if (reading.waveHeight >= idealMin * 0.5 && reading.waveHeight <= idealMax * 1.5) {
    add("$height - a bit $sizeWord for this spot", 1);
  } else {
    add("$height - too $sizeWord for this spot", 0);
  }

  // Longer period swells are more organised groundswell energy rather
  // than short-interval wind swell.
  final period = "${reading.wavePeriod.toStringAsFixed(0)}s";
  if (reading.wavePeriod > 10) {
    add("Long-period groundswell ($period)", 2);
  } else if (reading.wavePeriod > 7) {
    add("Moderate swell period ($period)", 1);
  } else {
    add("Short-period wind swell ($period)", 0);
  }

  // Swell arriving from well outside the spot's ideal window will refract,
  // close out, or simply not reach the break cleanly.
  final swellFrom = nearestCardinal(reading.swellDirection);
  if (directionMatches(reading.swellDirection, bestSwell, tolerance: 35)) {
    add("$swellFrom swell - this spot's ideal direction", 2);
  } else if (!directionMatches(reading.swellDirection, bestSwell, tolerance: 70)) {
    add("$swellFrom swell - wrong direction for this spot", -2);
  } else {
    add("$swellFrom swell - slightly off-angle", 0);
  }

  // Wind is the biggest factor in whether a swell is clean or blown out.
  final windSpeed = reading.windSpeed;
  final windDirection = reading.windDirection;
  if (windSpeed != null && windDirection != null) {
    final isOffshore = directionMatches(windDirection, bestWind, tolerance: 45);
    final wind = "${nearestCardinal(windDirection)} wind (${windSpeed.toStringAsFixed(0)} km/h)";
    if (windSpeed < 10) {
      add("Light $wind", 1); // light wind rarely spoils a session regardless of direction
    } else if (isOffshore) {
      add(windSpeed < 25 ? "Offshore $wind" : "Strong offshore $wind", windSpeed < 25 ? 2 : 1);
    } else {
      add("Onshore/cross-shore $wind", windSpeed > 20 ? -2 : -1);
    }
  }

  final rating = points >= 6 ? SurfRating.good : (points >= 3 ? SurfRating.fair : SurfRating.poor);
  return ScoredHour(reading: reading, points: points, rating: rating, factors: factors);
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
