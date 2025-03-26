import 'package:flutter/material.dart';
import 'package:surfspot/Widgets/Children/locations.dart';
import 'package:surfspot/Widgets/Children/map.dart';
import 'package:surfspot/Widgets/Children/surf_forecast.dart';

class FindMySpot extends StatefulWidget {
  const FindMySpot({super.key});

  @override
  State<FindMySpot> createState() => _FindMySpotState();
}

class _FindMySpotState extends State<FindMySpot> {

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[
        DestinationMap(),
        SizedBox(height: 8),
        LocationList(),
        SizedBox(height: 8),
        SurfForecast()
      ],
    );
  }
}