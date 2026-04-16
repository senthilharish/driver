# Booking Notification System

## Overview
This documentation explains the complete booking notification system that displays popups when new bookings arrive and sends push notifications to the driver.

## Features

### 1. **Real-time Booking Listening**
   - Automatically listens to new bookings for the driver
   - Updates in real-time using Firestore listeners

### 2. **Push Notifications**
   - Local push notifications with sound and vibration
   - Notification shows booking details (pickup, dropoff, price, seats)
   - Works on Android and iOS

### 3. **Booking Popup Modal**
   - Beautiful, intuitive popup dialog
   - Displays all booking details with formatted information
   - Accept/Reject buttons for quick actions

### 4. **Automatic Actions**
   - Accept booking: Updates booking status and adjusts available seats
   - Reject booking: Updates booking status to rejected

## Architecture

### Components

#### 1. **BookingController** (`lib/controllers/booking_controller.dart`)
   - Manages booking state and business logic
   - Listens to pending bookings from Firestore
   - Triggers notifications when new bookings arrive
   - Handles accept/reject operations

#### 2. **BookingService** (`lib/services/booking_service.dart`)
   - Communicates with Firestore
   - Provides real-time booking listeners
   - Performs booking CRUD operations
   - Updates ride seat information

#### 3. **NotificationService** (`lib/services/notification_service.dart`)
   - Initializes local notifications
   - Requests necessary permissions
   - Shows booking notifications with custom details
   - Handles notification actions

#### 4. **BookingPopup** (`lib/widgets/booking_popup.dart`)
   - Beautiful popup widget displaying booking details
   - Shows pickup/dropoff locations
   - Displays seat count and pricing
   - Accept/Reject action buttons

## Implementation Details

### Setup in Main App

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Register controllers
  Get.put(AuthController());
  Get.put(RideController());
  Get.put(BookingController());  // ← Booking Controller
  
  runApp(const MyApp());
}
```

### Start Listening for Bookings (Home Screen)

```dart
void _setupBookingListener() {
  final driverId = _authController.currentDriver.value?.uid ?? '';
  if (driverId.isNotEmpty) {
    // Start listening with notifications
    _bookingController.startListeningWithNotifications(driverId);
    
    // Watch for new bookings and show popup
    ever(_bookingController.currentBooking, (booking) {
      if (booking != null && mounted) {
        _showBookingPopup(booking);
      }
    });
  }
}
```

## Firestore Structure

### Bookings Collection
```firestore
bookings/
  {bookingId}/
    - bookingId: String
    - rideId: String
    - userId: String (passenger)
    - driverId: String
    - pickupLocation: String
    - dropoffLocation: String
    - seatsBooked: int
    - pricePerSeat: double
    - totalPrice: double
    - status: String ("pending", "accepted", "rejected", "cancelled")
    - isApproved: boolean
    - bookedAt: DateTime
    - approvedAt: DateTime (optional)
```

## Data Flow

```
1. Passenger Books a Ride
   ↓
2. Booking Created in Firestore with status: "pending"
   ↓
3. BookingController listens via BookingService
   ↓
4. New booking detected
   ↓
5. NotificationService sends push notification
   ↓
6. BookingPopup displayed to driver
   ↓
7. Driver accepts/rejects
   ↓
8. BookingService updates Firestore status
   ↓
9. Passenger notified of driver's response
```

## Usage

### To Accept a Booking
```dart
await bookingController.acceptBooking(rideId);
```

### To Reject a Booking
```dart
await bookingController.rejectBooking();
```

### To Get Pending Bookings Count
```dart
final count = await bookingService.getPendingBookingsCount(driverId);
```

### To Get Booking History
```dart
bookingService.getDriverBookingHistory(driverId).listen((bookings) {
  // Handle booking list
});
```

## Notification Details

### Android Configuration
- **Channel**: "booking_channel"
- **Title**: "🚕 New Booking Request"
- **Sound & Vibration**: Enabled
- **Priority**: High
- **Actions**: Accept, Decline

### iOS Configuration
- **Sound**: notification_sound.aiff
- **Alert**: Enabled
- **Badge**: Enabled

## Classes & Methods

### BookingController

#### Methods:
- `startListeningWithNotifications(String driverId)` - Start listening to driver's bookings
- `startListening()` - Listen to all pending bookings
- `acceptBooking(String rideId)` - Accept current booking
- `rejectBooking()` - Reject current booking
- `_sendBookingNotification(BookingModel booking)` - Send notification

#### Observable Properties:
- `currentBooking` - Current booking being displayed
- `pendingBookings` - List of pending bookings
- `isLoading` - Loading state
- `errorMessage` - Error messages

### BookingService

#### Methods:
- `listenToPendingBookings({String? driverId})` - Get stream of pending bookings
- `listenToDriverPendingBookings(String driverId)` - Get driver's pending bookings stream
- `acceptBooking(String bookingId, String rideId, int seatsBooked)` - Accept a booking
- `rejectBooking(String bookingId)` - Reject a booking
- `createBooking(BookingModel booking)` - Create new booking
- `getRideBookings(String rideId)` - Get all bookings for a ride
- `getDriverBookingHistory(String driverId)` - Get booking history stream
- `getPendingBookingsCount(String driverId)` - Get count of pending bookings

### NotificationService

#### Methods:
- `initialize()` - Initialize notification service
- `requestPermissions()` - Request OS permissions
- `showBookingNotification({...})` - Show booking notification

## Error Handling

The system includes comprehensive error handling:

```dart
try {
  // Operations
} catch (e) {
  print('[BookingController] ❌ Error: $e');
  errorMessage.value = e.toString();
}
```

## Debug Logs

The system provides detailed logging:
- `[BookingController]` - Controller operations
- `[BookingService]` - Database operations
- `[NotificationService]` - Notification events

Example logs:
```
[BookingController] 👂 Starting to listen for bookings...
[BookingController] 📢 Received booking: booking_123
[BookingController] ✅ Booking updated: booking_123
[BookingService] ➡️ Accepting booking...
[BookingService] ✅ Booking accepted: booking_123
[NotificationService] ✅ Booking notification sent for: booking_123
```

## Testing

### Test Scenario 1: Accept Booking
1. Start app and go to home screen
2. Create a booking from passenger app
3. Verify notification appears
4. Verify popup appears
5. Click "Accept Booking"
6. Verify Firestore updates with accepted status

### Test Scenario 2: Reject Booking
1. Start app and go to home screen
2. Create a booking from passenger app
3. Verify notification appears
4. Verify popup appears
5. Click "Decline Booking"
6. Verify Firestore updates with rejected status

### Test Scenario 3: Multiple Bookings
1. Create multiple bookings quickly
2. Verify latest booking popup appears
3. Accept/reject and verify next booking appears

## Troubleshooting

### Notifications Not Showing
1. Check permissions are granted
2. Verify app has notification permission in OS settings
3. Check notification channel is properly configured

### Popup Not Appearing
1. Verify BookingController is registered in main.dart
2. Check listener is started in home screen
3. Verify Firestore has bookings with status: "pending"

### Booking Not Updating
1. Check internet connectivity
2. Verify Firestore rules allow updates
3. Check booking ID in database matches request

## Future Enhancements

1. **Sound Customization** - Allow different sounds for different booking types
2. **Booking History** - Display full booking history in app
3. **Estimated Earnings** - Calculate earnings from accepted bookings
4. **Booking Filters** - Filter by status, date range, etc.
5. **Offline Mode** - Cache bookings when offline

## Dependencies Added

```yaml
# In pubspec.yaml
flutter_local_notifications: ^17.0.0
```

This provides local push notification capabilities across Android and iOS.
