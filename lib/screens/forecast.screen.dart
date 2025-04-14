import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather_icons/weather_icons.dart';
import '../util/weather_service.api.dart';
import '../util/location_notifier.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  _ForecastScreenState createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  final WeatherService _weatherService = WeatherService();
  List<dynamic>? forecastData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchForecast();
  }

  Future<void> _fetchForecast() async {
    setState(() {
      isLoading = true;
    });

    try {
      final locationNotifier = Provider.of<LocationNotifier>(context, listen: false);
      final location = locationNotifier.currentLocation;

      // Fetch coordinates from city name
      final coordinates = await _weatherService.searchCity(location);
      if (coordinates.isNotEmpty) {
        final lat = coordinates[0]['lat'];
        final lon = coordinates[0]['lon'];

        final data = await _weatherService.fetch5DayForecast(lat, lon);
        if (mounted) {
          setState(() {
            forecastData = data;
            isLoading = false;
          });
        }
      } else {
        throw Exception('Location not found');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      print('Error fetching forecast data: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locationNotifier = Provider.of<LocationNotifier>(context);
    final previousLocation = forecastData?.first['name'];
    if (previousLocation != locationNotifier.currentLocation) {
      // Only fetch forecast if the location has changed
      _fetchForecast();
    }
  }

  // Map weather conditions to icons
  IconData getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return WeatherIcons.day_sunny;
      case 'rain':
        return WeatherIcons.rain;
      case 'thunderstorm':
        return WeatherIcons.thunderstorm;
      case 'snow':
        return WeatherIcons.snow;
      case 'clouds':
        return WeatherIcons.cloudy;
      case 'wind':
        return WeatherIcons.strong_wind;
      case 'mist':
      case 'haze':
        return WeatherIcons.fog;
      default:
        return WeatherIcons.day_cloudy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('5-Day Forecast'),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 22,
        ),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : forecastData != null
            ? ListView.builder(
          itemCount: forecastData!.length,
          itemBuilder: (context, index) {
            var item = forecastData![index];
            var dateTime = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
            var formattedDate =
                "${dateTime.day}/${dateTime.month}/${dateTime.year} - ${dateTime.hour}:${dateTime.minute}";
            var condition = item['weather'][0]['main'];

            return ListTile(
              leading: BoxedIcon(getWeatherIcon(condition)),
              title: Text(
                  '$formattedDate - ${item['main']['temp']}°C - ${item['weather'][0]['description']}'),
            );
          },
        )
            : const Text('Error loading forecast data'),
      ),
    );
  }
}
