import 'dart:convert';
import 'package:http/http.dart' as http;

/// Fetches marine swell data and meteorological wind data and merges them
/// into a single hourly series keyed by timestamp.
///
/// The Marine API's `wave_height`/`wave_period` are the *combined* sea state
/// (groundswell mixed with local wind chop), so we pull the `swell_wave_*`
/// components instead - that's the part of the sea that actually indicates
/// surfable wave quality. Wind isn't available from the Marine API at all,
/// so it's fetched separately from the Weather Forecast API and merged in by
/// timestamp, since it's the biggest driver of whether a swell will be clean
/// or blown out.
Future<Map<String, dynamic>> fetchSurfForecast(double latitude, double longitude) async {
  final marineUrl = Uri.parse(
      'https://marine-api.open-meteo.com/v1/marine?latitude=$latitude&longitude=$longitude'
      '&hourly=swell_wave_height,swell_wave_period,swell_wave_direction&timezone=auto');
  final windUrl = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude'
      '&hourly=wind_speed_10m,wind_direction_10m&timezone=auto');

  try {
    final responses = await Future.wait([http.get(marineUrl), http.get(windUrl)]);
    final marineResponse = responses[0];
    final windResponse = responses[1];

    if (marineResponse.statusCode != 200) {
      throw Exception("Failed to load marine forecast: ${marineResponse.statusCode}");
    }
    if (windResponse.statusCode != 200) {
      throw Exception("Failed to load wind forecast: ${windResponse.statusCode}");
    }

    final marineHourly = jsonDecode(marineResponse.body)['hourly'];
    final windHourly = jsonDecode(windResponse.body)['hourly'];

    final List<dynamic> times = marineHourly['time'];
    final List<dynamic> windTimes = windHourly['time'];
    final windIndexByTime = <String, int>{
      for (int i = 0; i < windTimes.length; i++) windTimes[i]: i,
    };

    final windSpeeds = <dynamic>[];
    final windDirections = <dynamic>[];
    for (final time in times) {
      final windIndex = windIndexByTime[time];
      windSpeeds.add(windIndex != null ? windHourly['wind_speed_10m'][windIndex] : null);
      windDirections.add(windIndex != null ? windHourly['wind_direction_10m'][windIndex] : null);
    }

    return {
      'hourly': {
        'time': times,
        'swell_wave_height': marineHourly['swell_wave_height'],
        'swell_wave_period': marineHourly['swell_wave_period'],
        'swell_wave_direction': marineHourly['swell_wave_direction'],
        'wind_speed_10m': windSpeeds,
        'wind_direction_10m': windDirections,
      }
    };
  } catch (e) {
    throw Exception("Error fetching surf forecast: $e");
  }
}
