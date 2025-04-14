import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'screens/about.screen.dart';
import 'screens/current_weather.screen.dart';
import 'screens/forecast.screen.dart';
import 'screens/hamburger.screen.dart';
import 'util/location_notifier.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationNotifier()..loadLocation()),
      ],
      child: MaterialApp(
        title: 'Weather App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<String> _locations = [];

  static const List<Widget> _widgetOptions = <Widget>[
    CurrentWeatherScreen(),
    ForecastScreen(),
    AboutScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final locationNotifier = Provider.of<LocationNotifier>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final storedLocations = prefs.getStringList('locations');

    if (storedLocations == null || storedLocations.isEmpty) {
      // SharedPreferences is empty, this is the first boot
      await _getCurrentLocationAndSave();
    } else {
      setState(() {
        _locations = storedLocations;
      });
      locationNotifier.updateLocation(storedLocations.first);
    }
  }

  Future<void> _getCurrentLocationAndSave() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];

      // Ensure the format is always "City, Country Code"
      String city = place.locality ?? '';
      String country = place.isoCountryCode ?? place.country ?? '';

      if (city.isEmpty) {
        // Fallback to another field if locality is empty
        city =  place.subLocality?.split(" ")[1] ?? '';
      }

      String currentLocation = "$city, $country";

      final locationNotifier = Provider.of<LocationNotifier>(context, listen: false);
      await locationNotifier.updateLocation(currentLocation);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('locations', [currentLocation]);

      setState(() {
        _locations = [currentLocation];
      });
    } catch (e) {
      print('Error obtaining location: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationNotifier = Provider.of<LocationNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather App'),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 22),
        backgroundColor: Colors.blue,
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                color: Colors.white,  // Set the hamburger icon color to white
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
        ],
      ),
      endDrawer: HamburgerScreen(
          currentLocation: locationNotifier.currentLocation,
          locations: _locations,
          onLocationSelected: (location) async {
            final locationNotifier = Provider.of<LocationNotifier>(context, listen: false);
            await locationNotifier.updateLocation(location);
          }
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Current',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_list),
            label: 'Forecast',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'About',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 255, 255, 255),
        unselectedItemColor: const Color.fromARGB(128, 255, 255, 255),
        onTap: _onItemTapped,
        backgroundColor: Colors.blue,
      ),
    );
  }
}
