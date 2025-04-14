import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationNotifier extends ChangeNotifier {
  String _currentLocation = ''; // Default location

  String get currentLocation => _currentLocation;

  Future<void> loadLocation() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLocation = prefs.getString('current_location') ?? _currentLocation;
    notifyListeners();
  }

  Future<void> updateLocation(String newLocation) async {
    _currentLocation = newLocation;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_location', _currentLocation);
    notifyListeners();
  }
}
