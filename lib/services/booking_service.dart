import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/models/booking_model.dart';

class BookingService {
  static final BookingService _instance = BookingService._internal();

  factory BookingService() {
    return _instance;
  }

  BookingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _bookingsCollection = 'bookings';

  /// Listen to pending bookings for a specific driver
  Stream<BookingModel?> listenToPendingBookings({String? driverId}) {
    print('[BookingService] 👂 Setting up listener for pending bookings...');
    
    return _firestore
        .collection(_bookingsCollection)
        .where('status', isEqualTo: 'pending')
        .orderBy('bookedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        print('[BookingService] ✅ No pending bookings');
        return null;
      }

      final doc = snapshot.docs.first;
      final booking = BookingModel.fromJson(doc.data());
      print('[BookingService] 📢 Booking received: ${booking.bookingId}');
      return booking;
    });
  }

  /// Get a specific booking by ID
  Future<BookingModel?> getBooking(String bookingId) async {
    try {
      final doc = await _firestore
          .collection(_bookingsCollection)
          .doc(bookingId)
          .get();

      if (!doc.exists) {
        print('[BookingService] ❌ Booking not found: $bookingId');
        return null;
      }

      print('[BookingService] ✅ Booking fetched: $bookingId');
      return BookingModel.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('[BookingService] ❌ Error fetching booking: $e');
      throw Exception('Failed to fetch booking: $e');
    }
  }

  /// Accept a booking
  Future<void> acceptBooking(
    String bookingId,
    String rideId,
    int seatsBooked,
  ) async {
    try {
      print('[BookingService] ➡️ Accepting booking: $bookingId');

      // Update booking status
      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'status': 'accepted',
        'isApproved': true,
        'approvedAt': DateTime.now().toIso8601String(),
      });

      // Update ride seats
      await _firestore.collection('rides').doc(rideId).update({
        'availableSeats': FieldValue.increment(-seatsBooked),
        'bookedSeats': FieldValue.increment(seatsBooked),
      });

      print('[BookingService] ✅ Booking accepted: $bookingId');
    } catch (e) {
      print('[BookingService] ❌ Error accepting booking: $e');
      throw Exception('Failed to accept booking: $e');
    }
  }

  /// Reject a booking
  Future<void> rejectBooking(String bookingId) async {
    try {
      print('[BookingService] ➡️ Rejecting booking: $bookingId');

      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'status': 'rejected',
      });

      print('[BookingService] ✅ Booking rejected: $bookingId');
    } catch (e) {
      print('[BookingService] ❌ Error rejecting booking: $e');
      throw Exception('Failed to reject booking: $e');
    }
  }

  /// Cancel a booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      print('[BookingService] ➡️ Cancelling booking: $bookingId');

      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'status': 'cancelled',
      });

      print('[BookingService] ✅ Booking cancelled: $bookingId');
    } catch (e) {
      print('[BookingService] ❌ Error cancelling booking: $e');
      throw Exception('Failed to cancel booking: $e');
    }
  }

  /// Create a new booking (called from passenger side)
  Future<void> createBooking(BookingModel booking) async {
    try {
      print('[BookingService] ➡️ Creating new booking: ${booking.bookingId}');

      await _firestore
          .collection(_bookingsCollection)
          .doc(booking.bookingId)
          .set(booking.toJson());

      print('[BookingService] ✅ Booking created: ${booking.bookingId}');
    } catch (e) {
      print('[BookingService] ❌ Error creating booking: $e');
      throw Exception('Failed to create booking: $e');
    }
  }

  /// Get all bookings for a ride
  Future<List<BookingModel>> getRideBookings(String rideId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_bookingsCollection)
          .where('rideId', isEqualTo: rideId)
          .get();

      return querySnapshot.docs
          .map((doc) => BookingModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('[BookingService] ❌ Error fetching ride bookings: $e');
      throw Exception('Failed to fetch ride bookings: $e');
    }
  }

  /// Get booking history for a driver
  Stream<List<BookingModel>> getDriverBookingHistory(String driverId) {
    return _firestore
        .collection(_bookingsCollection)
        .where('driverId', isEqualTo: driverId)
        .orderBy('bookedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromJson(doc.data()))
          .toList();
    });
  }

  /// Get pending bookings count
  Future<int> getPendingBookingsCount(String driverId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_bookingsCollection)
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'pending')
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('[BookingService] ❌ Error fetching pending count: $e');
      return 0;
    }
  }

  /// Listen to pending bookings for a driver
  Stream<List<BookingModel>> listenToDriverPendingBookings(String driverId) {
    return _firestore
        .collection(_bookingsCollection)
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      final bookings = snapshot.docs
          .map((doc) => BookingModel.fromJson(doc.data()))
          .toList();
      
      // Sort by bookedAt in Dart instead of Firestore
      // This avoids needing a composite index
      bookings.sort((a, b) => b.bookedAt.compareTo(a.bookedAt));
      
      return bookings;
    });
  }
}
