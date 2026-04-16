import 'package:get/get.dart';
import 'dart:async';
import 'package:driver/models/booking_model.dart';
import 'package:driver/services/booking_service.dart';
// import 'package:driver/services/notification_service.dart';

class BookingController extends GetxController {
  final BookingService _service = BookingService();
  // final NotificationService _notificationService = NotificationService();

  // Current pending booking
  final currentBooking = Rx<BookingModel?>(null);
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final pendingBookings = <BookingModel>[].obs;
  
  // Track which bookings have been shown to avoid duplicates
  final Set<String> _shownBookingIds = {};
  
  // Polling timer
  Timer? _pollingTimer;
  final pollingActive = false.obs;
  final lastPolledTime = ''.obs;

  @override
  void onInit() {
    super.onInit();
    print('[BookingController] 🎯 Controller initialized');
    // _notificationService.initialize();
    // _notificationService.requestPermissions();
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    print('[BookingController] 🛑 Polling stopped');
    super.onClose();
  }

  /// Start listening to pending bookings with notifications and real-time updates
  void startListeningWithNotifications(String driverId) {
    print('[BookingController] 👂 Starting real-time listener for bookings...');
    
    _service.listenToDriverPendingBookings(driverId).listen(
      (bookings) {
        print('[BookingController] 📲 Received ${bookings.length} booking(s) from Firestore');
        
        if (bookings.isNotEmpty) {
          pendingBookings.assignAll(bookings);
          
          // Check for new bookings that haven't been shown yet
          for (final booking in bookings) {
            if (booking.status == 'pending' && !_shownBookingIds.contains(booking.bookingId)) {
              print('[BookingController] 🆕 NEW BOOKING DETECTED: ${booking.bookingId}');
              print('[BookingController] 📢 Seats: ${booking.seatsBooked}');
              print('[BookingController] 💰 Price: ₹${booking.totalPrice}');
              
              // Mark as shown
              _shownBookingIds.add(booking.bookingId);
              
              // Update current booking
              currentBooking.value = booking;
              
              // Send notification
              _sendBookingNotification(booking);
            }
          }
        } else {
          print('[BookingController] ℹ️ No pending bookings');
          currentBooking.value = null;
          pendingBookings.clear();
        }
      },
      onError: (error) {
        print('[BookingController] ❌ Real-time listener error: $error');
        errorMessage.value = error.toString();
      },
    );
    
    print('[BookingController] ✅ Real-time listener started for driver: $driverId');
  }

  /// Send notification for new booking
  void _sendBookingNotification(BookingModel booking) {
    print('[BookingController] 🔔 Sending notification for booking: ${booking.bookingId}');
    // Notification service will be integrated later
    // _notificationService.showBookingNotification(
    //   bookingId: booking.bookingId,
    //   passengerName: 'Passenger', // You can get actual name from booking details
    //   pickupLocation: booking.pickupLocation,
    //   dropoffLocation: booking.dropoffLocation,
    //   totalPrice: booking.totalPrice,
    //   seatsBooked: booking.seatsBooked,
    // );
  }

  /// Start listening to pending bookings
  void startListening() {
    print('[BookingController] 👂 Starting to listen for bookings...');
    
    _service.listenToPendingBookings().listen(
      (booking) {
        print('[BookingController] 📢 Received booking: ${booking?.bookingId}');
        currentBooking.value = booking;
        
        if (booking != null) {
          print('[BookingController] ✅ Booking updated: ${booking.bookingId}');
          print('[BookingController] ✅ Seats: ${booking.seatsBooked}');
          print('[BookingController] ✅ Price: ₹${booking.totalPrice}');
          
          // Send notification
          _sendBookingNotification(booking);
        }
      },
      onError: (error) {
        print('[BookingController] ❌ Listen error: $error');
        errorMessage.value = error.toString();
      },
    );
  }

  /// Start polling for pending bookings every 5 seconds
  void startPollingBookings(String driverId) {
    print('[BookingController] ⏱️ Starting polling for bookings every 5 seconds...');
    
    // Cancel existing timer if any
    _pollingTimer?.cancel();
    
    // Poll immediately on start
    _pollBookings(driverId);
    
    // Then poll every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _pollBookings(driverId);
    });
    
    pollingActive.value = true;
    print('[BookingController] ✅ Polling started');
  }

  /// Fetch bookings from database (called every 5 seconds)
  Future<void> _pollBookings(String driverId) async {
    try {
      print('[BookingController] 🔄 Polling database for bookings...');
      
      // Get pending bookings for this driver
      final bookingsList = await _service.listenToDriverPendingBookings(driverId).first;
      
      if (bookingsList.isNotEmpty) {
        final latestBooking = bookingsList.first;
        
        // Check if this is a new booking (not already shown)
        if (currentBooking.value == null || 
            currentBooking.value!.bookingId != latestBooking.bookingId) {
          
          print('[BookingController] 📢 New booking detected: ${latestBooking.bookingId}');
          currentBooking.value = latestBooking;
          pendingBookings.assignAll(bookingsList);
          
          // Send notification
          _sendBookingNotification(latestBooking);
        }
      } else {
        if (currentBooking.value != null) {
          print('[BookingController] ℹ️ No more pending bookings');
          currentBooking.value = null;
          pendingBookings.clear();
        }
      }
      
      // Update last polled time
      lastPolledTime.value = DateTime.now().toString();
      print('[BookingController] ✅ Poll completed at ${lastPolledTime.value}');
      
    } catch (e) {
      print('[BookingController] ❌ Polling error: $e');
      errorMessage.value = 'Polling error: $e';
    }
  }

  /// Stop polling for bookings
  void stopPollingBookings() {
    _pollingTimer?.cancel();
    pollingActive.value = false;
    print('[BookingController] 🛑 Polling stopped');
  }

  /// Pause polling temporarily
  void pausePollingBookings() {
    _pollingTimer?.cancel();
    pollingActive.value = false;
    print('[BookingController] ⏸️ Polling paused');
  }

  /// Resume polling
  void resumePollingBookings(String driverId) {
    if (!pollingActive.value) {
      startPollingBookings(driverId);
      print('[BookingController] ▶️ Polling resumed');
    }
  }

  /// Accept current booking
  Future<void> acceptBooking(String rideId) async {
    if (currentBooking.value == null) {
      print('[BookingController] ❌ No booking to accept');
      return;
    }

    try {
      isLoading.value = true;
      final booking = currentBooking.value!;
      
      print('[BookingController] ➡️ Accepting booking...');
      await _service.acceptBooking(
        booking.bookingId,
        rideId,
        booking.seatsBooked,
      );
      
      currentBooking.value = null;
      isLoading.value = false;
      print('[BookingController] ✅ Booking accepted');
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = e.toString();
      print('[BookingController] ❌ Error: $e');
    }
  }

  /// Reject current booking
  Future<void> rejectBooking() async {
    if (currentBooking.value == null) {
      print('[BookingController] ❌ No booking to reject');
      return;
    }

    try {
      isLoading.value = true;
      final bookingId = currentBooking.value!.bookingId;
      
      print('[BookingController] ➡️ Rejecting booking...');
      await _service.rejectBooking(bookingId);
      
      currentBooking.value = null;
      isLoading.value = false;
      print('[BookingController] ✅ Booking rejected');
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = e.toString();
      print('[BookingController] ❌ Error: $e');
    }
  }

  /// Test method to trigger a booking popup (for debugging)
  void testBookingPopup() {
    print('[BookingController] 🧪 Test popup triggered');
    
    // Create a mock booking for testing
    final mockBooking = BookingModel(
      bookingId: 'test_${DateTime.now().millisecondsSinceEpoch}',
      rideId: 'test_ride_001',
      userId: 'test_user_001',
      driverId: 'test_driver_001',
      pickupLocation: '123 Main Street, Downtown',
      dropoffLocation: '456 Oak Avenue, Suburbs',
      seatsBooked: 3,
      pricePerSeat: 150.0,
      totalPrice: 450.0,
      status: 'pending',
      isApproved: false,
      bookedAt: DateTime.now(),
    );
    
    currentBooking.value = mockBooking;
    print('[BookingController] 🧪 Mock booking set: ${mockBooking.bookingId}');
  }
}

