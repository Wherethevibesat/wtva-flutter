import 'package:geolocator/geolocator.dart';

/// A single device location reading used to prove venue presence on check-in.
class DeviceLocation {
  final double lat;
  final double lng;
  final double accuracy;

  const DeviceLocation({
    required this.lat,
    required this.lng,
    required this.accuracy,
  });
}

/// Thin wrapper over geolocator with graceful failure (returns null instead of
/// throwing) so the check-in flow can decide how to handle missing location.
class LocationService {
  LocationService._();

  static Future<DeviceLocation?> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return DeviceLocation(
        lat: pos.latitude,
        lng: pos.longitude,
        accuracy: pos.accuracy,
      );
    } catch (_) {
      return null;
    }
  }
}
