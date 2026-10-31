import 'package:flutter_test/flutter_test.dart';
import 'package:surfspot/Providers/surf_conditions_provider.dart';
import 'package:surfspot/Utils/surf_scoring.dart';

HourlyReading _reading(DateTime time, {double height = 1.0, double period = 12, double swell = 225, double? windSpeed = 15, double? windDir = 315}) {
  return HourlyReading(
    time: time,
    waveHeight: height,
    wavePeriod: period,
    swellDirection: swell,
    windSpeed: windSpeed,
    windDirection: windDir,
  );
}

ScoredHour _score(HourlyReading r) => scoreHour(r, bestSwell: "South-West", bestWind: "North-West", difficultyRating: 1);

SpotForecast _spot(String name, DateTime day, {required double swell, int difficulty = 1}) {
  final hours = [
    for (int h = 0; h < 24; h++)
      scoreHour(
        _reading(day.add(Duration(hours: h)), swell: swell),
        bestSwell: "South-West",
        bestWind: "North-West",
        difficultyRating: difficulty,
      ),
  ];
  return SpotForecast(spot: {"name": name, "difficultyRating": difficulty}, hours: hours);
}

void main() {
  test('score factors add up to the total points', () {
    final readings = [
      _reading(DateTime(2030, 1, 5, 9)),
      _reading(DateTime(2030, 1, 5, 9), height: 4, period: 6, swell: 45, windSpeed: 30, windDir: 135),
      _reading(DateTime(2030, 1, 5, 9), windSpeed: null, windDir: null),
    ];
    for (final reading in readings) {
      final scored = _score(reading);
      expect(scored.factors.fold<int>(0, (sum, f) => sum + f.points), scored.points);
    }
  });

  test('ideal conditions are rated good and explained', () {
    final scored = _score(_reading(DateTime(2030, 1, 5, 9)));
    expect(scored.rating, SurfRating.good);
    expect(scored.factors.map((f) => f.label), contains("Offshore North-West wind (15 km/h)"));
    expect(scored.factors.map((f) => f.label), contains("South-West swell - this spot's ideal direction"));
  });

  test('wrong swell direction and onshore wind are penalised', () {
    final scored = _score(_reading(DateTime(2030, 1, 5, 9), swell: 45, windSpeed: 30, windDir: 135));
    expect(scored.factors.where((f) => f.points < 0).length, 2);
    expect(scored.rating, isNot(SurfRating.good));
  });

  test('bestWindowOn only looks at the requested day', () {
    final saturday = DateTime(2030, 1, 5);
    final forecast = _spot("A", saturday, swell: 225);
    expect(forecast.bestWindowOn(saturday), isNotNull);
    expect(forecast.bestWindowOn(saturday.add(const Duration(days: 1))), isNull);
  });

  test('bestWindowOn skips hours that have already passed', () {
    final today = DateTime.now();
    final forecast = _spot("A", DateTime(today.year, today.month, today.day), swell: 225);
    final window = forecast.bestWindowOn(today);
    if (window != null) {
      expect(window.start.reading.time.isAfter(today.subtract(const Duration(hours: 1))), isTrue);
    }
  });

  test('windowAt returns exactly the requested hour', () {
    final saturday = DateTime(2030, 1, 5);
    final forecast = _spot("A", saturday, swell: 225);
    final window = forecast.windowAt(saturday, 9)!;
    expect(window.start.reading.time, DateTime(2030, 1, 5, 9));
    expect(identical(window.start, window.end), isTrue);
    expect(window.totalPoints, window.bestHour.points);
    expect(window.timeLabel, "9 AM");
    expect(forecast.windowAt(saturday.add(const Duration(days: 1)), 9), isNull);
  });

  test('windowFor falls back to the best window when no hour is picked', () {
    final saturday = DateTime(2030, 1, 5);
    final forecast = _spot("A", saturday, swell: 225);
    final window = forecast.windowFor(saturday)!;
    expect(window.end.reading.time.difference(window.start.reading.time), const Duration(hours: 2));
    expect(window.timeLabel, contains(" - "));
  });
}
