import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:driver/models/ride_model.dart';

class RideManagementService {
  static final RideManagementService _instance = RideManagementService._internal();

  factory RideManagementService() {
    return _instance;
  }

  RideManagementService._internal();

  RideModel? _currentRide;

  RideModel? get currentRide => _currentRide;

  // Create a new ride
  Future<RideModel> createNewRide({
    required String driverId,
    required Position startPosition,
    required String startAddress,
    required int numberOfPassengers,
    required double basePrice,
  }) async {
    try {
      print('[RideManagementService] ===== CREATE NEW RIDE =====');
      print('[RideManagementService] Driver ID: $driverId');
      print('[RideManagementService] Start Position: ${startPosition.latitude}, ${startPosition.longitude}');
      print('[RideManagementService] Start Address: $startAddress');
      print('[RideManagementService] Passengers: $numberOfPassengers');
      print('[RideManagementService] Base Price: $basePrice');
      
      const uuid = Uuid();
      final rideId = uuid.v4();
      print('[RideManagementService] Generated Ride ID: $rideId');

      _currentRide = RideModel(
        rideId: rideId,
        driverId: driverId,
        startLatitude: startPosition.latitude,
        startLongitude: startPosition.longitude,
        startAddress: startAddress,
        numberOfPassengers: numberOfPassengers,
        basePrice: basePrice,
        status: RideStatus.started,
        createdAt: DateTime.now(),
        startedAt: DateTime.now(),
      );

      print('[RideManagementService] RideModel created: $_currentRide');
      print('[RideManagementService] _currentRide is null: ${_currentRide == null}');
      return _currentRide!;
    } catch (e, stackTrace) {
      print('[RideManagementService] ERROR: $e');
      print('[RideManagementService] StackTrace: $stackTrace');
      throw Exception('Failed to create ride: $e');
    }
  }

  // Set destination
  Future<void> setDestination({
    required double destinationLatitude,
    required double destinationLongitude,
    required String destinationAddress,
  }) async {
    try {
      if (_currentRide == null) {
        throw Exception('No active ride');
      }

      _currentRide = _currentRide!.copyWith(
        destinationLatitude: destinationLatitude,
        destinationLongitude: destinationLongitude,
        destinationAddress: destinationAddress,
        status: RideStatus.inProgress,
      );
    } catch (e) {
      throw Exception('Failed to set destination: $e');
    }
  }

  // Calculate distance between two coordinates
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final distance = Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
    return distance / 1000; // Convert to kilometers
  }

  // Calculate ride price
  double calculateRidePrice({
    required double basePrice,
    required double distance,
    required int numberOfPassengers,
    double perKmRate = 15.0, // Rs per km
    double passengerMultiplier = 1.0,
  }) {
    double distanceCharge = distance * perKmRate;
    double passengerCharge = (numberOfPassengers - 1) * 10.0; // Rs 10 per additional passenger
    double additionalPrice = distanceCharge + passengerCharge;
    double totalPrice = basePrice + additionalPrice;

    return totalPrice;
  }

  // Update ride with distance and duration
  Future<void> updateRideMetrics({
    required double distance,
    required int durationInSeconds,
  }) async {
    try {
      if (_currentRide == null) {
        throw Exception('No active ride');
      }

      _currentRide = _currentRide!.copyWith(
        rideDistance: distance,
        rideDuration: durationInSeconds,
      );
    } catch (e) {
      throw Exception('Failed to update ride metrics: $e');
    }
  }

  // Complete the ride
  Future<RideModel> completeRide() async {
    try {
      if (_currentRide == null) {
        throw Exception('No active ride');
      }

      if (_currentRide!.destinationLatitude == null ||
          _currentRide!.destinationLongitude == null) {
        throw Exception('Destination not set');
      }

      // Calculate final price
      double distance = calculateDistance(
        _currentRide!.startLatitude,
        _currentRide!.startLongitude,
        _currentRide!.destinationLatitude!,
        _currentRide!.destinationLongitude!,
      );

      double totalPrice = calculateRidePrice(
        basePrice: _currentRide!.basePrice,
        distance: distance,
        numberOfPassengers: _currentRide!.numberOfPassengers,
      );

      _currentRide = _currentRide!.copyWith(
        status: RideStatus.completed,
        completedAt: DateTime.now(),
        rideDistance: distance,
        totalPrice: totalPrice,
      );

      return _currentRide!;
    } catch (e) {
      throw Exception('Failed to complete ride: $e');
    }
  }

  // Cancel the ride
  Future<void> cancelRide() async {
    try {
      if (_currentRide == null) {
        throw Exception('No active ride');
      }

      _currentRide = _currentRide!.copyWith(
        status: RideStatus.cancelled,
      );
    } catch (e) {
      throw Exception('Failed to cancel ride: $e');
    }
  }

  // Get ride summary
  Map<String, dynamic> getRideSummary() {
    if (_currentRide == null) {
      throw Exception('No active ride');
    }

    final ride = _currentRide!;

    return {
      'rideId': ride.rideId,
      'startAddress': ride.startAddress,
      'destinationAddress': ride.destinationAddress ?? 'Not set',
      'distance': ride.rideDistance?.toStringAsFixed(2) ?? 'Calculating...',
      'duration': ride.rideDuration != null
          ? '${(ride.rideDuration! ~/ 60)} min ${ride.rideDuration! % 60} sec'
          : 'Calculating...',
      'basePrice': ride.basePrice.toStringAsFixed(2),
      'additionalPrice': ride.additionalPrice?.toStringAsFixed(2) ?? '0.00',
      'totalPrice': ride.totalPrice?.toStringAsFixed(2) ?? 'Calculating...',
      'numberOfPassengers': ride.numberOfPassengers,
      'status': ride.status.toString().split('.').last,
    };
  }

  // Reset current ride
  void resetCurrentRide() {
    _currentRide = null;
  }
}
