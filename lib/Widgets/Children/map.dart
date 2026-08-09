import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:surfspot/Globals/config.dart';
import 'package:surfspot/Providers/location_provider.dart';
import 'package:surfspot/Theme/app_theme.dart';

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

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

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: colorScheme.outlineVariant, width: 1)),
        child: AspectRatio(
          aspectRatio: 16 / 9,
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
                urlTemplate: isDarkMode
                    ? "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
                    : "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: isDarkMode ? const ['a', 'b', 'c', 'd'] : const [],
                userAgentPackageName: 'com.example.surfspot',
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
                    width: 132,
                    height: 78,
                    alignment: Alignment.bottomCenter,
                    child: GestureDetector(
                      onTap: () {
                        final index = locations.indexOf(spot);
                        Provider.of<LocationProvider>(context, listen: false).setLocation(index);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.teal : (isDarkMode ? Colors.black87 : Colors.white),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              spot["name"],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : (isDarkMode ? Colors.white : Colors.black87),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Icon(
                            Icons.location_on,
                            color: isSelected ? AppColors.teal : AppColors.coral,
                            size: isSelected ? 32 : 24,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
