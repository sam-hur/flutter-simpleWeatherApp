import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  Future<Map<String, String>> getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark place = placemarks[0];

    String city = place.locality ?? place.subLocality ?? '';
    String country = place.country ?? '';

    if (city.isEmpty) {
      city = place.administrativeArea ?? '';
    }

    return {'city': city, 'country': country};
  }
}
