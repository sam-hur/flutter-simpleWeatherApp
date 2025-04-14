import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey = '623d465a18e79d7734566eb1d68538df';
  final String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  final String forecastUrl = 'https://api.openweathermap.org/data/2.5/forecast';

  Future<Map<String, dynamic>> fetchCurrentWeatherByCoordinates(double latitude, double longitude) async {
  final url = '$baseUrl?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric';

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Invalid API key');
    } else if (response.statusCode == 404) {
      throw Exception('Location not found');
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  Future<Map<String, dynamic>> fetchCurrentWeather(String cityName) async {
    final url = '$baseUrl?q=$cityName&appid=$apiKey&units=metric';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  Future<List<dynamic>> fetch5DayForecast(double latitude, double longitude) async {
    final url = '$forecastUrl?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      return data['list'];
    } else {
      throw Exception('Failed to load forecast data');
    }
  }

  Future<List<dynamic>> searchCity(String query) async {
    final url = 'https://api.openweathermap.org/geo/1.0/direct?q=$query&limit=5&appid=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load city data');
    }
  }
}
