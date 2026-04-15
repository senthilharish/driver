import 'package:get/get.dart';
import 'package:geocoding/geocoding.dart';
import 'package:driver/models/ride_model.dart';
import 'package:driver/services/ride_management_service.dart';
import 'package:driver/services/ride_database_service.dart';
import 'package:driver/services/location_service.dart';

class RideController extends GetxController {
  final RideManagementService _rideManagementService = RideManagementService();
  final RideDatabaseService _rideDatabaseService = RideDatabaseService();
  final LocationService _locationService = LocationService();

  // Observable variables
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<RideModel?> currentRide = Rx<RideModel?>(null);
  final RxString startAddress = 'Getting location...'.obs;
  final RxString destinationAddress = 'Not set'.obs;
  final RxInt numberOfPassengers = 1.obs;
  final RxDouble basePrice = 100.0.obs;
  final RxDouble totalPrice = 0.0.obs;
  final RxBool rideInProgress = false.obs;
  final RxList<RideModel> rideHistory = <RideModel>[].obs;

  // Ride metrics
  final RxDouble currentDistance = 0.0.obs;
  final RxInt rideDuration = 0.obs;
  
  // Destination coordinates (for manual input)
  final RxDouble destinationLatitude = 0.0.obs;
  final RxDouble destinationLongitude = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadRideHistory();
  }

  // Set destination latitude
  void setDestinationLatitude(double lat) {
    destinationLatitude.value = lat;
  }

  // Set destination longitude
  void setDestinationLongitude(double long) {
    destinationLongitude.value = long;
  }

  // Start a new ride
  Future<bool> startRide({
    required String driverId,
    required int passengers,
    required double basePrice,
    double? destinationLat,
    double? destinationLong,
  }) async {
    try {
      print('[RideController] ===== START RIDE INITIATED =====');
      print('[RideController] Driver ID: $driverId');
      print('[RideController] Passengers: $passengers');
      print('[RideController] Base Price: $basePrice');
      print('[RideController] Destination Lat: $destinationLat, Long: $destinationLong');
      
      isLoading.value = true;
      errorMessage.value = '';

      // Get current location
      print('[RideController] Getting current location...');
      final position = await _locationService.getCurrentLocation();
      print('[RideController] Current position: ${position.latitude}, ${position.longitude}');

      // Get address from coordinates
      print('[RideController] Getting address from coordinates...');
      String address = 'Pickup Location';
      
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('[RideController] Geocoding timeout, using default address');
            return [];
          },
        );
        
        print('[RideController] Placemarks received: ${placemarks.length}');

        if (placemarks.isNotEmpty) {
          final place = placemarks[0];
          address = '${place.street ?? ''}, ${place.locality ?? ''}, ${place.postalCode ?? ''}';
          address = address.replaceAll(RegExp(r',\s*,'), ',').trim();
          print('[RideController] Address: $address');
        }
      } catch (e) {
        print('[RideController] Geocoding failed: $e, using default address');
        address = 'Pickup Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
      }

      startAddress.value = address;

      // Create new ride
      print('[RideController] Creating new ride in service...');
      final ride = await _rideManagementService.createNewRide(
        driverId: driverId,
        startPosition: position,
        startAddress: address,
        numberOfPassengers: passengers,
        basePrice: basePrice,
      );
      print('[RideController] Ride created: ${ride.rideId}');

      currentRide.value = ride;
      numberOfPassengers.value = passengers;
      this.basePrice.value = basePrice;
      rideInProgress.value = true;
      print('[RideController] Ride controller state updated');

      // Save to database
      print('[RideController] Saving ride to database...');
      await _rideDatabaseService.saveRide(ride);
      print('[RideController] Ride saved to Firestore');

      // If destination is provided, set it immediately
      if (destinationLat != null && destinationLat != 0.0 && 
          destinationLong != null && destinationLong != 0.0) {
        print('[RideController] Setting destination: $destinationLat, $destinationLong');
        await setDestination(
          latitude: destinationLat,
          longitude: destinationLong,
        );
        print('[RideController] Destination set successfully');
      }

      print('[RideController] ===== RIDE STARTED SUCCESSFULLY =====');
      isLoading.value = false;
      return true;
    } catch (e, stackTrace) {
      print('[RideController] ===== ERROR IN START RIDE =====');
      print('[RideController] Exception: $e');
      print('[RideController] StackTrace: $stackTrace');
      errorMessage.value = e.toString();
      isLoading.value = false;
      return false;
    }
  }

  // Set destination
  Future<bool> setDestination({
    required double latitude,
    required double longitude,
  }) async {
    try {
      print('[RideController] ===== SET DESTINATION INITIATED =====');
      print('[RideController] Destination Lat: $latitude, Long: $longitude');
      
      isLoading.value = true;
      errorMessage.value = '';

      // Get address from coordinates
      print('[RideController] Getting address from destination coordinates...');
      String address = 'Destination Location';
      
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude)
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                print('[RideController] Destination geocoding timeout, using default address');
                return [];
              },
            );
        print('[RideController] Destination placemarks received: ${placemarks.length}');

        if (placemarks.isNotEmpty) {
          final place = placemarks[0];
          address = '${place.street ?? ''}, ${place.locality ?? ''}, ${place.postalCode ?? ''}';
          address = address.replaceAll(RegExp(r',\s*,'), ',').trim();
          print('[RideController] Destination address: $address');
        }
      } catch (e) {
        print('[RideController] Destination geocoding failed: $e, using default address');
        address = 'Destination Location ($latitude, $longitude)';
      }

      destinationAddress.value = address;

      // Update ride with destination
      print('[RideController] Updating ride with destination in service...');
      await _rideManagementService.setDestination(
        destinationLatitude: latitude,
        destinationLongitude: longitude,
        destinationAddress: address,
      );
      print('[RideController] Ride destination updated in service');

      // Calculate distance
      if (currentRide.value != null) {
        print('[RideController] Current ride exists, calculating distance...');
        double distance = _rideManagementService.calculateDistance(
          currentRide.value!.startLatitude,
          currentRide.value!.startLongitude,
          latitude,
          longitude,
        );

        currentDistance.value = distance;

        // Calculate price
        double price = _rideManagementService.calculateRidePrice(
          basePrice: basePrice.value,
          distance: distance,
          numberOfPassengers: numberOfPassengers.value,
        );

        totalPrice.value = price;

        // Update current ride
        currentRide.value = currentRide.value!.copyWith(
          destinationLatitude: latitude,
          destinationLongitude: longitude,
          destinationAddress: address,
          rideDistance: distance,
          totalPrice: price,
        );

        // Update in database
        await _rideDatabaseService.updateRide(currentRide.value!);
      }

      isLoading.value = false;
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      isLoading.value = false;
      return false;
    }
  }

  // Update number of passengers
  void updateNumberOfPassengers(int passengers) {
    numberOfPassengers.value = passengers;

    if (currentRide.value != null) {
      // Recalculate price
      double price = _rideManagementService.calculateRidePrice(
        basePrice: basePrice.value,
        distance: currentDistance.value,
        numberOfPassengers: passengers,
      );

      totalPrice.value = price;

      currentRide.value = currentRide.value!.copyWith(
        numberOfPassengers: passengers,
        totalPrice: price,
      );
    }
  }

  // Update base price
  void updateBasePrice(double price) {
    basePrice.value = price;

    if (currentRide.value != null) {
      // Recalculate total price
      double totalPrice = _rideManagementService.calculateRidePrice(
        basePrice: price,
        distance: currentDistance.value,
        numberOfPassengers: numberOfPassengers.value,
      );

      this.totalPrice.value = totalPrice;

      currentRide.value = currentRide.value!.copyWith(
        basePrice: price,
        totalPrice: totalPrice,
      );
    }
  }

  // Complete the ride
  Future<bool> completeRide() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final completedRide = await _rideManagementService.completeRide();
      currentRide.value = completedRide;

      // Update in database
      await _rideDatabaseService.updateRide(completedRide);

      rideInProgress.value = false;
      isLoading.value = false;

      // Reload history
      await _loadRideHistory();

      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      isLoading.value = false;
      return false;
    }
  }

  // Cancel the ride
  Future<bool> cancelRide() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _rideManagementService.cancelRide();

      if (currentRide.value != null) {
        // Update in database
        await _rideDatabaseService.updateRide(currentRide.value!);
      }

      rideInProgress.value = false;
      currentRide.value = null;
      isLoading.value = false;

      // Reset for new ride
      _rideManagementService.resetCurrentRide();

      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      isLoading.value = false;
      return false;
    }
  }

  // Load ride history
  Future<void> _loadRideHistory() async {
    try {
      // Get driver ID from auth (you need to pass this or get from controller)
      // For now, we'll skip this - you can integrate with AuthController
      // final driverId = authController.currentDriver.value?.uid;
      // if (driverId != null) {
      //   final rides = await _rideDatabaseService.getDriverRides(driverId);
      //   rideHistory.value = rides;
      // }
    } catch (e) {
      print('Error loading ride history: $e');
    }
  }

  // Get ride summary
  Map<String, dynamic> getRideSummary() {
    return _rideManagementService.getRideSummary();
  }

  // Clear error
  void clearError() {
    errorMessage.value = '';
  }

  // Reset for new ride
  void resetForNewRide() {
    startAddress.value = 'Getting location...';
    destinationAddress.value = 'Not set';
    numberOfPassengers.value = 1;
    basePrice.value = 100.0;
    totalPrice.value = 0.0;
    currentDistance.value = 0.0;
    rideDuration.value = 0;
    currentRide.value = null;
    errorMessage.value = '';
    _rideManagementService.resetCurrentRide();
  }
}
