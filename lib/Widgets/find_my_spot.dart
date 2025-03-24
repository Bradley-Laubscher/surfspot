import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FindMySpot extends StatefulWidget {
  const FindMySpot({super.key});

  @override
  State<FindMySpot> createState() => _FindMySpotState();
}

class _FindMySpotState extends State<FindMySpot> {
  late GoogleMapController mapController;
  final LatLng _initialPosition = LatLng(-33.8688, 151.2093); // Default to Sydney

  final Set<Marker> _surfSpots = {
    Marker(
      markerId: MarkerId('spot1'),
      position: LatLng(-33.892, 151.256), // Example coordinates
      infoWindow: InfoWindow(title: 'Bondi Beach', snippet: 'Great waves today!'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ),
    Marker(
      markerId: MarkerId('spot2'),
      position: LatLng(-33.728, 151.300),
      infoWindow: InfoWindow(title: 'Manly Beach', snippet: 'Moderate swell'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ),
  };

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(
              minHeight: 200,
              minWidth: 400
          ),
          child: Container(
            width: MediaQuery.of(context).size.width*0.6,
            height: MediaQuery.of(context).size.height*0.3,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black,
                width: 1,
                style: BorderStyle.solid
              )
            ),
            // child: GoogleMap(
            //   onMapCreated: _onMapCreated,
            //   initialCameraPosition: CameraPosition(
            //     target: _initialPosition,
            //     zoom: 10.0,
            //   ),
            //   markers: _surfSpots,
            //   myLocationEnabled: true,
            //   zoomControlsEnabled: false,
            // ),
          ),
        ),
      ],
    );
  }
}