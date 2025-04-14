import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import '../util/weather_service.api.dart';
import '../util/location_notifier.dart';

class CurrentWeatherScreen extends StatefulWidget {
  const CurrentWeatherScreen({super.key});

  @override
  _CurrentWeatherScreenState createState() => _CurrentWeatherScreenState();
}

class _CurrentWeatherScreenState extends State<CurrentWeatherScreen> {
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? weatherData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWeather();  // Initial fetch when the widget is created
  }

  Future<void> _fetchWeather() async {
    setState(() {
      isLoading = true;
    });
    try {
      final locationNotifier = Provider.of<LocationNotifier>(context, listen: false);
      final data = await _weatherService.fetchCurrentWeather(locationNotifier.currentLocation);
      setState(() {
        weatherData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching weather data: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locationNotifier = Provider.of<LocationNotifier>(context);
    final previousLocation = weatherData?['name']; // Assuming location name is stored in weatherData
    if (previousLocation != locationNotifier.currentLocation) {
      // Only fetch weather if the location has changed
      _fetchWeather();
    }
  }

  // Map weather conditions to Lottie animation paths
  String getWeatherAnimation(String condition, int currentTime, int sunrise, int sunset) {
    bool isNight = currentTime < sunrise || currentTime > sunset;

    switch (condition.toLowerCase()) {
      case 'clear':
        if (isNight) {
          return 'assets/moon.json';
        } else {
          return 'assets/sunny.json';
        }
      case 'rain':
        return 'assets/rainy.json';
      case 'thunderstorm':
        return 'assets/stormy.json';
      case 'clouds':
        return 'assets/cloudy.json';
      default:
        return 'assets/cloudy.json'; // Default to cloudy
    }
  }

  // Format the Unix timestamp to a readable date
  String formatDate(int timestamp, int timezoneOffset) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(
      (timestamp + timezoneOffset) * 1000,
      isUtc: false,
    );
    return DateFormat('EEEE, MMM dd, yyyy').format(dateTime);  // Format as 'Tuesday, May 30, 2023'
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : weatherData != null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              getWeatherAnimation(
                weatherData!['weather'][0]['main'],
                weatherData!['dt'],  // Current time from API
                weatherData!['sys']['sunrise'],  // Sunrise time from API
                weatherData!['sys']['sunset'],  // Sunset time from API
              ),
              width: 150,
              height: 150,
              fit: BoxFit.fill,
            ),
            Text(
              '${weatherData!['name']}, ${weatherData!['sys']['country']}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              formatDate(weatherData!['dt'], weatherData!['timezone']),
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              weatherData!['weather'][0]['description'],
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              '${weatherData!['main']['temp']}°C',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
          ],
        )
            : const Text('Error loading weather data'),
      ),
    );
  }
}
