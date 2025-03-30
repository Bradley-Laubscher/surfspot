import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> fetchSurfForecast(double latitude, double longitude) async {
  final url = Uri.parse(
      'https://marine-api.open-meteo.com/v1/marine?latitude=$latitude&longitude=$longitude&hourly=wave_height,wind_wave_direction,wave_period&timezone=auto');

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load marine forecast: ${response.statusCode}");
    }
  } catch (e) {
    throw Exception("Error fetching marine forecast: $e");
  }
}
