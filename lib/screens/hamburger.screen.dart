import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../util/weather_service.api.dart';
import '../util/location_service.dart';

final LocationService _locationService = LocationService();

class HamburgerScreen extends StatefulWidget {
  final String currentLocation;
  final List<String> locations;
  final Function(String) onLocationSelected;

  const HamburgerScreen({
    Key? key,
    required this.currentLocation,
    required this.locations,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  _HamburgerScreenState createState() => _HamburgerScreenState();
}

class _HamburgerScreenState extends State<HamburgerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final WeatherService _weatherService = WeatherService();
  List<String> _filteredLocations = [];
  List<dynamic> _searchResults = [];
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _filteredLocations = prefs.getStringList('locations') ?? [];
    });
  }

  void _filterLocations(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    _weatherService.searchCity(query).then((results) {
      setState(() {
        _searchResults = results.map((result) => result['name'] + ', ' + (result['country'] ?? '')).toList();
      });
    }).catchError((error) {
      print('Error searching city: $error');
    });
  }

  Future<void> _saveLocation(String location) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? storedLocations = prefs.getStringList('locations') ?? [];

    if (!storedLocations!.contains(location)) {
      storedLocations.add(location);
      await prefs.setStringList('locations', storedLocations);
      setState(() {
        _filteredLocations = storedLocations;
      });
    }

    widget.onLocationSelected(location);
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocating = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];

      String city = place.locality ?? '';
      String country = place.country ?? '';

      if (city.isEmpty) {
        city = place.subLocality?.split(' ')[1] ?? '';
      }

      String currentAddress = "$city, $country";
      _searchController.text = currentAddress;
      _filterLocations(currentAddress);
    } catch (e) {
      print('Error obtaining location: $e');
    } finally {
      setState(() {
        _isLocating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Searched Locations',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                elevation: 3,
                child: ListTile(
                  title: Text(
                    'Current Location: ${widget.currentLocation}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    widget.onLocationSelected(widget.currentLocation);
                    Navigator.pop(context); // Close the drawer
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Search locations',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            prefixIcon: const Icon(Icons.search),
                          ),
                          onChanged: _filterLocations,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: _isLocating
                            ? const CircularProgressIndicator()
                            : const Icon(Icons.my_location),
                        onPressed: _isLocating ? null : _getCurrentLocation,
                      ),
                    ],
                  ),
                  if (_searchResults.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_searchResults[index]),
                            onTap: () async {
                              await _saveLocation(_searchResults[index]);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Saved Locations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8.0),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredLocations.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Card(
                    elevation: 3,
                    child: ListTile(
                      title: Text(_filteredLocations[index]),
                      onTap: () async {
                        await _saveLocation(_filteredLocations[index]);
                        Navigator.pop(context); // Close the drawer
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
