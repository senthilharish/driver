import 'package:get/get.dart';
import 'package:driver/models/driver_model.dart';
import 'package:driver/services/firebase_service.dart';
import 'package:driver/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class AuthController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  final LocationService _locationService = LocationService();

  // Observable variables
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<DriverModel?> currentDriver = Rx<DriverModel?>(null);
  final RxBool isAuthenticated = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeAuth();
  }

  void _initializeAuth() {
    _firebaseService.authStateChanges.listen((user) {
      if (user != null) {
        isAuthenticated.value = true;
        _loadDriverData(user.uid);
      } else {
        isAuthenticated.value = false;
        currentDriver.value = null;
      }
    });
  }

  Future<void> _loadDriverData(String uid) async {
    try {
      final driver = await _firebaseService.getDriverData(uid);
      currentDriver.value = driver;
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }

  Future<bool> signUp({
    required String username,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Get current location
      Position? position;
      try {
        position = await _locationService.getCurrentLocation();
      } catch (e) {
        // Location is optional, continue without it
        print('Location error: $e');
      }

      // Sign up with Firebase
      final driver = await _firebaseService.signUpWithPhone(
        username: username,
        phoneNumber: phoneNumber,
        password: password,
        latitude: position?.latitude,
        longitude: position?.longitude,
      );

      currentDriver.value = driver;
      isAuthenticated.value = true;
      isLoading.value = false;
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> login({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Login with Firebase
      final driver = await _firebaseService.loginWithPhone(
        phoneNumber: phoneNumber,
        password: password,
      );

      currentDriver.value = driver;
      isAuthenticated.value = true;
      isLoading.value = false;
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      isLoading.value = false;
      return false;
    }
  }

  Future<void> updateLocation() async {
    try {
      if (currentDriver.value == null) return;

      final position = await _locationService.getCurrentLocation();
      await _firebaseService.updateDriverLocation(
        currentDriver.value!.uid,
        position.latitude,
        position.longitude,
      );

      // Update local driver model
      currentDriver.value = currentDriver.value!.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;
      await _firebaseService.signOut();
      currentDriver.value = null;
      isAuthenticated.value = false;
      isLoading.value = false;
    } catch (e) {
      errorMessage.value = e.toString();
      isLoading.value = false;
    }
  }

  void clearError() {
    errorMessage.value = '';
  }
}
