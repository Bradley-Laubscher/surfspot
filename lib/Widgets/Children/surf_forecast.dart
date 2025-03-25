import 'package:flutter/material.dart';
import 'package:surfspot/API/fetch_surf_forecast.dart';

class SurfForecast extends StatefulWidget {
  const SurfForecast({super.key});

  @override
  State<SurfForecast> createState() => _SurfForecastState();
}

class _SurfForecastState extends State<SurfForecast> {
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
          minHeight: 250,
          minWidth: 400
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.3,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: FutureBuilder<dynamic>(
          future: fetchSurfForecast(-33.9249, 18.4241), // Fetch forecast data
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
            final hours = data['hourly']['time']; // Hour timestamps

            // Group the data by day
            List<List<dynamic>> groupedData = [];
            List<dynamic> currentDay = [];
            DateTime currentDayStart = DateTime.parse(hours[0]);

            for (int i = 0; i < waveHeights.length; i++) {
              DateTime timestamp = DateTime.parse(hours[i]);
              if (timestamp.day == currentDayStart.day) {
                currentDay.add(waveHeights[i]);
              } else {
                groupedData.add(currentDay);
                currentDay = [waveHeights[i]];
                currentDayStart = timestamp;
              }
            }
            groupedData.add(currentDay); // Add the last group

            return ListView.builder(
              itemCount: groupedData.length,
              itemBuilder: (context, index) {
                List<dynamic> dayData = groupedData[index];

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
                        height: 80, // Set height to fit hourly data
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: dayData.length,
                          itemBuilder: (context, hourIndex) {
                            // Convert hourIndex to a time of day format
                            DateTime timestamp = DateTime.parse(hours[hourIndex]);
                            String timeOfDay = _formatTimeOfDay(timestamp);

                            return Container(
                              width: 60,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(timeOfDay), // Display time of day
                                  Text(
                                    "${dayData[hourIndex]} m",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          },
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

    // Get today's day index (1 for Monday, 7 for Sunday)
    int currentDayIndex = DateTime.now().weekday - 1; // 0 is Sunday, 6 is Saturday

    // Calculate the day for the given index, accounting for wrapping around (cycling through days)
    String day = daysOfTheWeek[(currentDayIndex + index) % 7];
    return day;
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
