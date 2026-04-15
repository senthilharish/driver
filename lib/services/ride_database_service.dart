import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/models/ride_model.dart';

class RideDatabaseService {
  static final RideDatabaseService _instance = RideDatabaseService._internal();

  factory RideDatabaseService() {
    return _instance;
  }

  RideDatabaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _ridesCollection = 'rides';

  // Save ride to Firestore
  Future<void> saveRide(RideModel ride) async {
    try {
      print('[RideDatabaseService] ===== SAVE RIDE =====');
      print('[RideDatabaseService] Ride ID: ${ride.rideId}');
      print('[RideDatabaseService] Driver ID: ${ride.driverId}');
      print('[RideDatabaseService] Converting to JSON...');
      
      final rideJson = ride.toJson();
      print('[RideDatabaseService] JSON keys: ${rideJson.keys.toList()}');
      
      print('[RideDatabaseService] Writing to Firestore...');
      await _firestore
          .collection(_ridesCollection)
          .doc(ride.rideId)
          .set(rideJson);
      
      print('[RideDatabaseService] Ride saved successfully to Firestore');
    } catch (e, stackTrace) {
      print('[RideDatabaseService] ERROR: $e');
      print('[RideDatabaseService] StackTrace: $stackTrace');
      throw Exception('Failed to save ride: $e');
    }
  }

  // Update ride in Firestore
  Future<void> updateRide(RideModel ride) async {
    try {
      await _firestore
          .collection(_ridesCollection)
          .doc(ride.rideId)
          .update(ride.toJson());
    } catch (e) {
      throw Exception('Failed to update ride: $e');
    }
  }

  // Get ride by ID
  Future<RideModel> getRideById(String rideId) async {
    try {
      final doc = await _firestore.collection(_ridesCollection).doc(rideId).get();

      if (!doc.exists) {
        throw Exception('Ride not found');
      }

      return RideModel.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch ride: $e');
    }
  }

  // Get all rides for a driver
  Future<List<RideModel>> getDriverRides(String driverId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_ridesCollection)
          .where('driverId', isEqualTo: driverId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => RideModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch driver rides: $e');
    }
  }

  // Get driver rides stream
  Stream<List<RideModel>> getDriverRidesStream(String driverId) {
    return _firestore
        .collection(_ridesCollection)
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RideModel.fromJson(doc.data()))
          .toList();
    });
  }

  // Get completed rides for a driver
  Future<List<RideModel>> getCompletedRides(String driverId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_ridesCollection)
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'completed')
          .orderBy('completedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => RideModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch completed rides: $e');
    }
  }

  // Get today's rides
  Future<List<RideModel>> getTodayRides(String driverId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection(_ridesCollection)
          .where('driverId', isEqualTo: driverId)
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
          .where('createdAt', isLessThan: endOfDay)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => RideModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch today rides: $e');
    }
  }

  // Get ride statistics for a driver
  Future<Map<String, dynamic>> getRideStatistics(String driverId) async {
    try {
      final rides = await getDriverRides(driverId);

      int totalRides = rides.length;
      int completedRides = rides.where((r) => r.status == RideStatus.completed).length;
      int cancelledRides = rides.where((r) => r.status == RideStatus.cancelled).length;

      double totalEarnings = rides
          .where((r) => r.status == RideStatus.completed && r.totalPrice != null)
          .fold(0.0, (sum, r) => sum + (r.totalPrice ?? 0.0));

      double totalDistance = rides
          .where((r) => r.rideDistance != null)
          .fold(0.0, (sum, r) => sum + (r.rideDistance ?? 0.0));

      return {
        'totalRides': totalRides,
        'completedRides': completedRides,
        'cancelledRides': cancelledRides,
        'totalEarnings': totalEarnings.toStringAsFixed(2),
        'totalDistance': totalDistance.toStringAsFixed(2),
        'averageEarningsPerRide':
            completedRides > 0 ? (totalEarnings / completedRides).toStringAsFixed(2) : '0.00',
      };
    } catch (e) {
      throw Exception('Failed to fetch statistics: $e');
    }
  }
}
