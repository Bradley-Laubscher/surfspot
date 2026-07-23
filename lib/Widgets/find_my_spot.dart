import 'package:flutter/material.dart';
import 'package:surfspot/Theme/app_theme.dart';
import 'package:surfspot/Widgets/Children/locations.dart';
import 'package:surfspot/Widgets/Children/map.dart';
import 'package:surfspot/Widgets/Children/surf_forecast.dart';
import 'package:surfspot/Widgets/spot_of_the_day.dart';

class FindMySpot extends StatelessWidget {
  const FindMySpot({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = AppBreakpoints.isTablet(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SpotOfTheDay(),
          const SizedBox(height: 20),
          if (isWide)
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      DestinationMap(),
                      SizedBox(height: 16),
                      LocationList(),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(flex: 4, child: SurfForecast()),
              ],
            )
          else
            const Column(
              children: [
                DestinationMap(),
                SizedBox(height: 16),
                LocationList(),
                SizedBox(height: 16),
                SurfForecast(),
              ],
            ),
        ],
      ),
    );
  }
}
