import 'package:flutter/material.dart';
import 'package:surfspot/Config/config.dart';

class LocationProvider with ChangeNotifier {
  Map<String, dynamic> _selectedLocation = locations[0];

  Map<String, dynamic> get selectedLocation => _selectedLocation;

  void setLocation(int index) {
    _selectedLocation = locations[index];
    notifyListeners();
  }
}