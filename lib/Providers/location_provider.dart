import 'package:flutter/material.dart';
import 'package:surfspot/Globals/config.dart';

class LocationProvider with ChangeNotifier {
  Map<String, dynamic> _selectedLocation = locations[0];
  bool _isGoodSurfDay = false; // Store the boolean value for surf conditions

  Map<String, dynamic> get selectedLocation => _selectedLocation;
  bool get isGoodSurfDay => _isGoodSurfDay;

  void setLocation(int index) {
    _selectedLocation = locations[index];
    notifyListeners();
  }

  // Method to update the surf day condition
  void setSurfCondition(bool isGood) async {
    _isGoodSurfDay = isGood;
  }
}