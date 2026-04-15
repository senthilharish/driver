import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  // Check location permissions
  Future<bool> checkLocationPermissions() async {
    final status = await Geolocator.checkPermission();
    return status == LocationPermission.whileInUse || status == LocationPermission.always;
  }

  // Request location permissions
  Future<bool> requestLocationPermissions() async {
    final status = await Geolocator.requestPermission();
    return status == LocationPermission.whileInUse || status == LocationPermission.always;
  }

  // Get current location
  Future<Position> getCurrentLocation() async {
    try {
      print('[LocationService] ===== GET CURRENT LOCATION =====');
      
      print('[LocationService] Checking location permissions...');
      bool hasPermission = await checkLocationPermissions();
      print('[LocationService] Has permission: $hasPermission');

      if (!hasPermission) {
        print('[LocationService] Requesting location permissions...');
        hasPermission = await requestLocationPermissions();
        print('[LocationService] Permission request result: $hasPermission');
      }

      if (!hasPermission) {
        print('[LocationService] ERROR: Location permission denied');
        throw Exception('Location permission denied');
      }

      print('[LocationService] Getting position from Geolocator...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );

      print('[LocationService] Position obtained: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e, stackTrace) {
      print('[LocationService] ERROR: $e');
      print('[LocationService] StackTrace: $stackTrace');
      throw Exception('Failed to get location: $e');
    }
  }

  // Get location updates as stream
  Stream<Position> getLocationUpdates() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10, // Update when moved 10 meters
      ),
    );
  }

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
}
