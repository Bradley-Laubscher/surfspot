import 'package:flutter/material.dart';
import 'package:surfspot/API/fetch_surf_forecast.dart';
import 'package:surfspot/Globals/config.dart';
import 'package:surfspot/Utils/formatting.dart';
import 'package:surfspot/Utils/surf_scoring.dart';

/// A spot's forecast, scored against its own best swell/wind/difficulty.
class SpotForecast {
  final Map<String, dynamic> spot;
  final List<ScoredHour> hours;

  SpotForecast({required this.spot, required this.hours});

  String get name => spot["name"] as String;
  int get difficultyRating => spot["difficultyRating"] as int;

  List<List<ScoredHour>> get byDay => groupByDay(hours);

  /// The best 3-hour daylight surf window on [day]. Hours that have already
  /// passed are skipped, so asking about today never recommends a window
  /// that ended this morning.
  SurfWindow? bestWindowOn(DateTime day) {
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));
    final dayHours = hours.where((h) => isSameDay(h.reading.time, day) && h.reading.time.isAfter(cutoff)).toList();
    if (dayHours.isEmpty) return null;
    return bestWindowInDay(dayHours);
  }

  /// Conditions at exactly [hour] o'clock on [day], as a single-hour window
  /// so it can be ranked and displayed like a regular surf window. Null if
  /// that hour isn't in the forecast or has already passed.
  SurfWindow? windowAt(DateTime day, int hour) {
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));
    for (final h in hours) {
      final time = h.reading.time;
      if (isSameDay(time, day) && time.hour == hour && time.isAfter(cutoff)) {
        return SurfWindow(start: h, end: h, bestHour: h, totalPoints: h.points);
      }
    }
    return null;
  }

  /// The window to show for [day]: conditions at [hour] if the user picked
  /// a specific time, otherwise the best 3-hour stretch of the day.
  SurfWindow? windowFor(DateTime day, {int? hour}) => hour == null ? bestWindowOn(day) : windowAt(day, hour);
}

/// A spot paired with its best surf window on a particular day.
class SpotRecommendation {
  final SpotForecast forecast;
  final SurfWindow window;

  const SpotRecommendation({required this.forecast, required this.window});
}

/// Fetches forecasts for every configured spot once, scores them, and
/// ranks spots for whichever day the user is planning to surf, so the whole
/// app shares a single set of network calls instead of every widget
/// re-fetching.
class SurfConditionsProvider with ChangeNotifier {
  final Map<String, SpotForecast> _forecasts = {};
  List<DateTime> _plannableDays = [];
  DateTime? _selectedDay;
  int? _selectedHour;
  bool _isLoading = true;
  String? _error;

  SurfConditionsProvider() {
    loadAll();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, SpotForecast> get forecasts => _forecasts;

  SpotForecast? forecastFor(String spotName) => _forecasts[spotName];

  /// Days in the forecast where at least one spot still has a daylight
  /// surf window - i.e. the days the user can plan a session for.
  List<DateTime> get plannableDays => _plannableDays;

  /// The day the user is planning to surf. Defaults to the first plannable
  /// day (normally today, or tomorrow once today's daylight has run out).
  DateTime get selectedDay {
    final selected = _selectedDay;
    if (selected != null && _plannableDays.any((d) => isSameDay(d, selected))) return selected;
    return _plannableDays.isNotEmpty ? _plannableDays.first : dateOnly(DateTime.now());
  }

  void selectDay(DateTime day) {
    _selectedDay = dateOnly(day);
    notifyListeners();
  }

  /// The hour the user wants to surf on [selectedDay], or null for "any
  /// time" (recommend the best window of the day). Falls back to null if
  /// the picked hour isn't available on the selected day, e.g. it has
  /// already passed today.
  int? get selectedHour {
    final hour = _selectedHour;
    return hour != null && selectableHoursFor(selectedDay).contains(hour) ? hour : null;
  }

  void selectHour(int? hour) {
    _selectedHour = hour;
    notifyListeners();
  }

  /// Daylight hours on [day] that at least one spot still has forecast data
  /// for - the same daylight range the best-window search considers.
  List<int> selectableHoursFor(DateTime day) {
    return [
      for (int hour = 6; hour <= 19; hour++)
        if (_forecasts.values.any((f) => f.windowAt(day, hour) != null)) hour,
    ];
  }

  /// The window to show for [forecast] given the user's selected day and hour.
  SurfWindow? selectedWindowFor(SpotForecast forecast) => forecast.windowFor(selectedDay, hour: selectedHour);

  /// Every spot with a surf window on [day], best first. With no [hour],
  /// ranked by total points across each spot's best 3 daylight hours; with
  /// an [hour], by that hour's points alone. Ties go to the higher single
  /// hour, then to the more accessible (lower difficulty) spot.
  List<SpotRecommendation> rankingFor(DateTime day, {int? hour}) {
    final ranking = <SpotRecommendation>[
      for (final forecast in _forecasts.values)
        if (forecast.windowFor(day, hour: hour) case final window?) SpotRecommendation(forecast: forecast, window: window),
    ];
    ranking.sort((a, b) {
      final byTotal = b.window.totalPoints.compareTo(a.window.totalPoints);
      if (byTotal != 0) return byTotal;
      final byPeak = b.window.bestHour.points.compareTo(a.window.bestHour.points);
      if (byPeak != 0) return byPeak;
      return a.forecast.difficultyRating.compareTo(b.forecast.difficultyRating);
    });
    return ranking;
  }

  /// The best spot to surf on [day] (at [hour], if given), if any spot has
  /// a window then.
  SpotRecommendation? recommendationFor(DateTime day, {int? hour}) {
    final ranking = rankingFor(day, hour: hour);
    return ranking.isEmpty ? null : ranking.first;
  }

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait(locations.map((spot) async {
        final lat = double.parse(spot["latitude"]);
        final lon = double.parse(spot["longitude"]);
        final data = await fetchSurfForecast(lat, lon);
        final readings = parseHourlyReadings(data['hourly']);
        final scored = readings
            .map((r) => scoreHour(
                  r,
                  bestSwell: spot["bestSwell"],
                  bestWind: spot["bestWind"],
                  difficultyRating: spot["difficultyRating"],
                ))
            .toList();
        return SpotForecast(spot: spot, hours: scored);
      }));

      _forecasts.clear();
      for (final forecast in results) {
        _forecasts[forecast.name] = forecast;
      }
      _plannableDays = _computePlannableDays();
    } catch (e) {
      _error = "Couldn't load surf conditions: $e";
    }

    _isLoading = false;
    notifyListeners();
  }

  List<DateTime> _computePlannableDays() {
    final days = {for (final forecast in _forecasts.values) ...forecast.hours.map((h) => dateOnly(h.reading.time))}.toList()
      ..sort();
    return days.where((day) => _forecasts.values.any((f) => f.bestWindowOn(day) != null)).toList();
  }
}
