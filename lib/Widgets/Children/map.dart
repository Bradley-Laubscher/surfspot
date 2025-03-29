import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:surfspot/Globals/config.dart';
import 'package:surfspot/Providers/location_provider.dart';

class DestinationMap extends StatefulWidget {
  const DestinationMap({super.key});

  @override
  State<DestinationMap> createState() => _DestinationMapState();
}

class _DestinationMapState extends State<DestinationMap> {
  final MapController _mapController = MapController();

  void _animatedMove(MapController mapController, LatLng destLocation, double zoom) {
    const int steps = 30;
    const int duration = 500;
    const double stepDuration = duration / steps;

    LatLng currentCenter = mapController.camera.center;
    double currentZoom = mapController.camera.zoom;

    double latStep = (destLocation.latitude - currentCenter.latitude) / steps;
    double lonStep = (destLocation.longitude - currentCenter.longitude) / steps;
    double zoomStep = (zoom - currentZoom) / steps;

    int currentStep = 0;

    Timer.periodic(Duration(milliseconds: stepDuration.toInt()), (timer) {
      if (currentStep >= steps) {
        timer.cancel();
      } else {
        currentStep++;
        mapController.move(
          LatLng(
            currentCenter.latitude + (latStep * currentStep),
            currentCenter.longitude + (lonStep * currentStep),
          ),
          currentZoom + (zoomStep * currentStep),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedLocation = Provider.of<LocationProvider>(context).selectedLocation;

    // Smoothly animate to the selected location when it changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animatedMove(
        _mapController,
        LatLng(
          double.parse(selectedLocation["latitude"]),
          double.parse(selectedLocation["longitude"]),
        ),
        9.0,
      );
    });

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 250,
        minWidth: 400,
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        width: MediaQuery.of(context).size.width * 0.6,
        height: MediaQuery.of(context).size.height * 0.3,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(
              double.parse(selectedLocation["latitude"]),
              double.parse(selectedLocation["longitude"]),
            ),
            initialZoom: 9.0,
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              tileProvider: CancellableNetworkTileProvider(),
            ),
            MarkerLayer(
              markers: locations.map((spot) {
                bool isSelected = spot["name"] == selectedLocation["name"];

                return Marker(
                  point: LatLng(
                    double.parse(spot["latitude"]),
                    double.parse(spot["longitude"]),
                  ),
                  width: 100,
                  height: 50,
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            spot["name"],
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Icon(
                          Icons.location_on,
                          color: isSelected ? Colors.blue : Colors.red,
                          size: isSelected ? 40 : 30,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}