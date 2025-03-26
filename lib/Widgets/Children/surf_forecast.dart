import 'package:flutter/material.dart';
import 'package:surfspot/API/fetch_surf_forecast.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:surfspot/Providers/location_provider.dart';

class SurfForecast extends StatefulWidget {
  const SurfForecast({super.key});

  @override
  State<SurfForecast> createState() => _SurfForecastState();
}

class _SurfForecastState extends State<SurfForecast> {
  @override
  Widget build(BuildContext context) {
    // Access the selected location from the provider
    final selectedLocation = Provider.of<LocationProvider>(context).selectedLocation;
    final latitude = double.parse(selectedLocation["latitude"]);
    final longitude = double.parse(selectedLocation["longitude"]);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 250, minWidth: 400),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.3,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1, style: BorderStyle.solid),
        ),
        child: FutureBuilder<dynamic>(
          future: fetchSurfForecast(latitude, longitude), // Fetch forecast data with the selected location's coordinates
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData) {
              return const Center(child: Text("No data available"));
            }

            final data = snapshot.data!;
            final waveHeights = data['hourly']['wave_height'];
            final windDirections = data['hourly']['wind_wave_direction']; // Wave direction
            final wavePeriods = data['hourly']['wave_period']; // Wave period
            final hours = data['hourly']['time']; // Hour timestamps

            // Group the data by day
            List<List<Map<String, dynamic>>> groupedData = [];
            List<Map<String, dynamic>> currentDay = [];
            DateTime currentDayStart = DateTime.parse(hours[0]);

            for (int i = 0; i < waveHeights.length; i++) {
              DateTime timestamp = DateTime.parse(hours[i]);
              if (timestamp.day == currentDayStart.day) {
                currentDay.add({
                  "height": waveHeights[i],
                  "direction": windDirections[i],
                  "period": wavePeriods[i],
                  "time": timestamp
                });
              } else {
                groupedData.add(currentDay);
                currentDay = [{
                  "height": waveHeights[i],
                  "direction": windDirections[i],
                  "period": wavePeriods[i],
                  "time": timestamp
                }];
                currentDayStart = timestamp;
              }
            }
            groupedData.add(currentDay); // Add the last group

            return ListView.builder(
              itemCount: groupedData.length,
              itemBuilder: (context, index) {
                List<Map<String, dynamic>> dayData = groupedData[index];
                ScrollController scrollController = ScrollController();

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _dayOfTheWeek(index),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 110,
                        child: Column(
                          children: [
                            Expanded(
                              child: Scrollbar(
                                controller: scrollController,
                                thumbVisibility: true,
                                child: ListView.builder(
                                  controller: scrollController,
                                  scrollDirection: Axis.horizontal,
                                  itemCount: dayData.length,
                                  itemBuilder: (context, hourIndex) {
                                    DateTime timestamp = dayData[hourIndex]["time"];
                                    String timeOfDay = _formatTimeOfDay(timestamp);
                                    double height = dayData[hourIndex]["height"];
                                    int direction = dayData[hourIndex]["direction"];
                                    double period = dayData[hourIndex]["period"];

                                    return Container(
                                      width: 80,
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(timeOfDay), // Time of day
                                          Text("${height.toStringAsFixed(1)} m", style: const TextStyle(fontSize: 12)), // Wave height
                                          Transform.rotate(
                                            angle: direction * (pi / 180), // Convert degrees to radians
                                            child: const Icon(Icons.arrow_upward, size: 16),
                                          ), // Rotated arrow for wave direction
                                          Text("${period.toStringAsFixed(1)}s", style: const TextStyle(fontSize: 10)), // Wave period
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Get the current day of the week and map it to a readable name
  String _dayOfTheWeek(int index) {
    List<String> daysOfTheWeek = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday"
    ];

    int currentDayIndex = DateTime.now().weekday - 1; // 0 is Sunday, 6 is Saturday
    return (index == 0) ? "Today" : daysOfTheWeek[(currentDayIndex + index) % 7];
  }

  // Function to format the timestamp to time of day (e.g., 1 AM, 2 PM, etc.)
  String _formatTimeOfDay(DateTime timestamp) {
    int hour = timestamp.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12; // Convert to 12-hour format
    if (hour == 0) hour = 12; // Handle midnight and noon
    return '$hour $period';
  }
}