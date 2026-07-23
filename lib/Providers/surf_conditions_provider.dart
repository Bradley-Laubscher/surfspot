import 'package:flutter/material.dart';
import 'package:surfspot/API/fetch_surf_forecast.dart';
import 'package:surfspot/Globals/config.dart';
import 'package:surfspot/Utils/surf_scoring.dart';

/// A spot's forecast, scored against its own best swell/wind/difficulty.
class SpotForecast {
  final Map<String, dynamic> spot;
  final List<ScoredHour> hours;

  SpotForecast({required this.spot, required this.hours});

  String get name => spot["name"] as String;

  List<List<ScoredHour>> get byDay => groupByDay(hours);

  /// The best 3-hour surf window happening today, if any daylight hours
  /// remain in today's forecast.
  SurfWindow? get todaysBestWindow {
    final now = DateTime.now();
    final today = hours.where((h) => h.reading.time.day == now.day && h.reading.time.month == now.month).toList();
    if (today.isEmpty) return null;
    return bestWindowInDay(today);
  }
}

/// Fetches forecasts for every configured spot once, scores them, and
/// exposes the results plus a "Spot of the Day" ranking so the whole app
/// shares a single set of network calls instead of every widget re-fetching.
class SurfConditionsProvider with ChangeNotifier {
  final Map<String, SpotForecast> _forecasts = {};
  bool _isLoading = true;
  String? _error;

  SurfConditionsProvider() {
    loadAll();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, SpotForecast> get forecasts => _forecasts;

  SpotForecast? forecastFor(String spotName) => _forecasts[spotName];

  /// The spot with the best surf window happening today, ranked by total
  /// points across its best 3 daylight hours.
  SpotForecast? get spotOfTheDay {
    SpotForecast? best;
    int bestScore = -1;
    for (final forecast in _forecasts.values) {
      final window = forecast.todaysBestWindow;
      if (window != null && window.totalPoints > bestScore) {
        bestScore = window.totalPoints;
        best = forecast;
      }
    }
    return best;
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
    } catch (e) {
      _error = "Couldn't load surf conditions: $e";
    }

    _isLoading = false;
    notifyListeners();
  }
}
