import 'package:flutter/material.dart';
import 'package:surfspot/API/fetch_surf_forecast.dart';

class SurfForecast extends StatefulWidget {
  const SurfForecast({super.key});

  @override
  State<SurfForecast> createState() => _SurfForecastState();
}
// surf forecasts (specific information - wave size, length, wind, temperature, conditions)
class _SurfForecastState extends State<SurfForecast> {
  @override
  Widget build(BuildContext context) {
    return  ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 250,
        minWidth: 400
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        width: MediaQuery.of(context).size.width*0.8,
        height: MediaQuery.of(context).size.height*0.3,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black,
            width: 1,
            style: BorderStyle.solid
          )
        ),
        child: FutureBuilder<dynamic>(
          future: fetchSurfForecast(-33.9249, 18.4241),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData) {
              return Center(child: Text("No data available"));
            }

            final data = snapshot.data!;
            final waveHeights = data['hourly']['wave_height'];

            return ListView.builder(
              itemCount: waveHeights.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text("Hour $index"),
                  subtitle: Text("Wave Height: ${waveHeights[index]} meters"),
                );
              },
            );
          },
        ),
      )
    );
  }
}
