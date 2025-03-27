import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:surfspot/Config/config.dart';

class DestinationMap extends StatelessWidget {
  const DestinationMap({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 250,
        minWidth: 400
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        width: MediaQuery.of(context).size.width*0.6,
        height: MediaQuery.of(context).size.height*0.3,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black,
            width: 1,
            style: BorderStyle.solid
          )
        ),
        child: FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(-34.008856, 18.581152),
            initialZoom: 9.0,
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              tileProvider: CancellableNetworkTileProvider(),
            ),
            MarkerLayer(
              markers: locations.map((spot) {
                return Marker(
                  point: LatLng(
                    double.parse(spot["latitude"]),
                    double.parse(spot["longitude"]),
                  ),
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_on, color: Colors.red, size: 30),
                );
              }).toList(),
            ),
          ],
        ),
      )
    );
  }
}
