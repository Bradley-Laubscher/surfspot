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
    final selectedLocation = Provider.of<LocationProvider>(context).selectedLocation;
    final latitude = double.parse(selectedLocation["latitude"]);
    final longitude = double.parse(selectedLocation["longitude"]);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 250, minWidth: 400),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.3,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white
        ),
        child: FutureBuilder<dynamic>(
          future: fetchSurfForecast(latitude, longitude),
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
            final windDirections = data['hourly']['wind_wave_direction'];
            final wavePeriods = data['hourly']['wave_period'];
            final hours = data['hourly']['time'];

            String averageCondition = _calculateAverageCondition(waveHeights, wavePeriods);
            // Set the provider's isGoodSurfDay to true if it's a good day for surfing
            Provider.of<LocationProvider>(context, listen: false).setSurfCondition(averageCondition == "Good");

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
            groupedData.add(currentDay);

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
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Day label (Today or Day of the Week)
                          Text(
                            _dayOfTheWeek(index),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
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

                                    String hourRating = _isGoodSurfHour(height, period);

                                    return Container(
                                      width: 80,
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(timeOfDay),
                                          Text("${height.toStringAsFixed(1)} m", style: const TextStyle(fontSize: 12)),
                                          Transform.rotate(
                                            angle: direction * (pi / 180),
                                            child: const Icon(Icons.arrow_upward, size: 16),
                                          ),
                                          Text("${period.toStringAsFixed(1)}s", style: const TextStyle(fontSize: 10)),
                                          Container(
                                            margin: const EdgeInsets.only(top: 5),
                                            height: 10,
                                            width: 10,
                                            decoration: BoxDecoration(
                                              color: _getColorForHourRating(hourRating),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
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

  // Helper method to calculate if it's a good day for surfing
  String _calculateAverageCondition(List<dynamic> heights, List<dynamic> periods) {
    int goodCount = 0;
    int totalCount = heights.length;

    for (int i = 0; i < totalCount; i++) {
      if (_isGoodSurfHour(heights[i], periods[i]) == "Good") {
        goodCount++;
      }
    }

    // If more than 50% of the forecasted hours are good, consider it a good surf day
    if (goodCount > totalCount / 2) {
      return "Good";
    } else {
      return "Poor";
    }
  }

  String _isGoodSurfHour(double height, double period) {
    if (height > 1.5 && height < 3.0 && period > 8) {
      return "Good";
    } else if (height >= 0.5 && height <= 3.5 && period > 6) {
      return "Fair";
    } else {
      return "Poor";
    }
  }

  Color _getColorForHourRating(String rating) {
    if (rating == "Good") return Colors.green;
    if (rating == "Fair") return Colors.orange;
    return Colors.red;
  }

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

    int currentDayIndex = DateTime.now().weekday - 1;
    return (index == 0) ? "Today" : daysOfTheWeek[(currentDayIndex + index) % 7];
  }

  String _formatTimeOfDay(DateTime timestamp) {
    int hour = timestamp.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '$hour $period';
  }
}
