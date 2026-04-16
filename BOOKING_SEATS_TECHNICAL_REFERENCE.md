# Technical Reference - Booking & Seat Management

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                  RideInProgressScreen (UI)                  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Booking Popup (BookingNotificationPopup)             │  │
│  │ ├─ Shows: seatsBooked, pickupLocation, totalPrice   │  │
│  │ └─ Actions: onAccept(), onReject()                  │  │
│  └──────────────────────────────────────────────────────┘  │
│                         ↓                                    │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Ride Details Section                                 │  │
│  │ ├─ Total Seats: 5                                    │  │
│  │ ├─ Seats Allocated: 3                                │  │
│  │ └─ Available Seats: 2 [Reactive - Obx]             │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│             RideController (State Management)                │
│                                                              │
│  Observable Variables:                                       │
│  ├─ numberOfPassengers: 5 (total capacity)                 │
│  ├─ numberOfPassengersAllocated: 0→3 (booked seats)       │
│  └─ availableSeats: 5→2 (remaining seats) [NEW]           │
│                                                              │
│  Methods:                                                    │
│  ├─ startRide()                                            │
│  │  └─ Sets: availableSeats = numberOfPassengers         │
│  │          numberOfPassengersAllocated = 0              │
│  │                                                         │
│  └─ reduceAvailableSeats(seatsBooked: int) [NEW]         │
│     ├─ availableSeats -= seatsBooked                      │
│     └─ numberOfPassengersAllocated += seatsBooked         │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│            BookingController & BookingService                │
│                                                              │
│  BookingController:                                          │
│  ├─ startListening()  [Already implemented]                │
│  ├─ acceptBooking(rideId) [Already implemented]           │
│  ├─ rejectBooking() [Already implemented]                  │
│  └─ testBookingPopup() [NEW]                               │
│                                                              │
│  BookingService:                                            │
│  ├─ Updates Firestore 'bookings' collection               │
│  │  └─ status: 'pending' → 'accepted'                    │
│  │                                                         │
│  └─ Updates Firestore 'rides' collection                  │
│     ├─ availableSeats: -seatsBooked                       │
│     └─ bookedSeats: +seatsBooked                          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    Firebase Firestore                        │
│                                                              │
│  bookings/{bookingId}                                        │
│  ├─ bookingId: "booking_123"                               │
│  ├─ rideId: "ride_456"                                     │
│  ├─ seatsBooked: 3                                         │
│  ├─ pickupLocation: "123 Main St"                          │
│  ├─ dropoffLocation: "456 Oak Ave"                         │
│  ├─ totalPrice: 450.00                                     │
│  └─ status: "pending" → "accepted"                         │
│                                                              │
│  rides/{rideId}                                             │
│  ├─ numberOfPassengers: 5                                  │
│  ├─ numberOfPassengersAllocated: 0 → 3                    │
│  ├─ availableSeats: 5 → 2                                 │
│  └─ bookedSeats: 0 → 3                                    │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow Sequence

### When Booking Accepted:

```
1. User taps "Accept Booking" button in UI
                    ↓
2. BookingNotificationPopup.onAccept() called
                    ↓
3. BookingController.acceptBooking(rideId) called
                    ↓
4. BookingService.acceptBooking() updates Firestore
   - bookings/{id}: status = "accepted"
   - rides/{id}: availableSeats -= seatsBooked
   - rides/{id}: bookedSeats += seatsBooked
                    ↓
5. RideInProgressScreen calls:
   _rideController.reduceAvailableSeats(booking.seatsBooked)
                    ↓
6. RideController.reduceAvailableSeats() updates state
   - availableSeats.value -= seatsBooked
   - numberOfPassengersAllocated.value += seatsBooked
                    ↓
7. Obx widget rebuilds automatically with new values
                    ↓
8. Success message shown with updated seat info
```

## Code Examples

### Accepting a Booking:

```dart
onAccept: () async {
  final rideId = _rideController.currentRide.value?.rideId;
  if (rideId != null) {
    // Step 1: Accept booking in database
    await controller.acceptBooking(rideId);
    
    // Step 2: Update local state (reduce seats)
    _rideController.reduceAvailableSeats(booking.seatsBooked);
    
    // Step 3: Show feedback
    _showActionMenu(
      context, 
      'Booking Accepted!', 
      'Seats allocated: ${booking.seatsBooked}\n'
      'Available seats: ${_rideController.availableSeats.value}'
    );
  }
}
```

### Displaying Available Seats:

```dart
Obx(
  () => Column(
    children: [
      _buildDetailCard(
        context,
        icon: Icons.event_seat,
        label: 'Total Seats',
        value: '${_rideController.numberOfPassengers.value}',
      ),
      _buildDetailCard(
        context,
        icon: Icons.person,
        label: 'Seats Allocated',
        value: '${_rideController.numberOfPassengersAllocated.value}',
      ),
      _buildDetailCard(
        context,
        icon: Icons.airline_seat_flat_angled,
        label: 'Available Seats',
        value: '${_rideController.availableSeats.value}',
      ),
    ],
  ),
)
```

### Reducing Available Seats:

```dart
void reduceAvailableSeats(int seatsBooked) {
  print('[RideController] 📉 Reducing available seats by $seatsBooked');
  print('[RideController] Before: Available = ${availableSeats.value}, '
        'Allocated = ${numberOfPassengersAllocated.value}');
  
  // Update state
  availableSeats.value -= seatsBooked;
  numberOfPassengersAllocated.value += seatsBooked;
  
  // Logs update
  print('[RideController] After: Available = ${availableSeats.value}, '
        'Allocated = ${numberOfPassengersAllocated.value}');
}
```

## State Management Pattern (GetX)

### Observable Variables in RideController:

```dart
class RideController extends GetxController {
  // Observable integers (can be watched for changes)
  final RxInt numberOfPassengers = 1.obs;
  final RxInt numberOfPassengersAllocated = 0.obs;
  final RxInt availableSeats = 0.obs;
  
  // Usage in UI:
  // Obx(() => Text('${_rideController.availableSeats.value}'))
  // Automatically rebuilds when value changes
}
```

### Reactive UI with Obx:

```dart
Obx(
  () => RideDetails(
    totalSeats: _rideController.numberOfPassengers.value,
    allocatedSeats: _rideController.numberOfPassengersAllocated.value,
    availableSeats: _rideController.availableSeats.value,
  ),
)
// This entire widget rebuilds whenever any of these values change
```

## Firestore Document Structure

### Before Accepting Booking:

```json
// bookings collection
{
  "bookingId": "booking_001",
  "rideId": "ride_001",
  "seatsBooked": 3,
  "status": "pending",
  "isApproved": false,
  "totalPrice": 450.00
}

// rides collection
{
  "rideId": "ride_001",
  "numberOfPassengers": 5,
  "numberOfPassengersAllocated": 0,
  "availableSeats": 5,
  "bookedSeats": 0
}
```

### After Accepting Booking:

```json
// bookings collection
{
  "bookingId": "booking_001",
  "rideId": "ride_001",
  "seatsBooked": 3,
  "status": "accepted",        // CHANGED
  "isApproved": true,          // CHANGED
  "approvedAt": "2024-04-16T10:30:00Z",  // NEW
  "totalPrice": 450.00
}

// rides collection
{
  "rideId": "ride_001",
  "numberOfPassengers": 5,
  "numberOfPassengersAllocated": 3,  // CHANGED (0 → 3)
  "availableSeats": 2,               // CHANGED (5 → 2)
  "bookedSeats": 3                   // CHANGED (0 → 3)
}
```

## Widget Tree

```
RideInProgressScreen (StatefulWidget)
├─ Scaffold
│  └─ body: SingleChildScrollView
│     └─ Column
│        ├─ Current Location Card
│        ├─ Destination Card
│        └─ Obx (Reactive Block)
│           └─ Column
│              ├─ [Destination not set?]
│              │  └─ Set Destination Form
│              └─ [Destination set]
│                 ├─ Ride Details Section
│                 │  ├─ DetailCard (Total Seats) [NEW]
│                 │  ├─ DetailCard (Allocated) [NEW]
│                 │  ├─ DetailCard (Available) [NEW]
│                 │  ├─ DetailCard (Distance)
│                 │  ├─ DetailCard (Passengers)
│                 │  ├─ Price Card
│                 │  └─ View Route Button
│                 ├─ Complete Ride Button
│                 └─ Test Popup Button
│
├─ showModalBottomSheet()
│  └─ BookingNotificationPopup
│     ├─ Booking Details Card
│     ├─ Accept Button
│     └─ Reject Button
│
└─ showModalBottomSheet()
   └─ Action Menu (Success)
      ├─ Success Icon
      ├─ Title & Message
      └─ Continue Button
```

## Error Handling

### Validation:

```dart
// In acceptBooking:
if (currentBooking.value == null) {
  print('[BookingController] ❌ No booking to accept');
  return;
}

if (rideId == null) {
  print('[RideInProgressScreen] ❌ No ride ID available');
  return;
}
```

### Exception Handling:

```dart
try {
  await controller.acceptBooking(rideId);
  _rideController.reduceAvailableSeats(booking.seatsBooked);
} catch (e) {
  print('[RideInProgressScreen] ❌ Error: $e');
  _showErrorDialog('Error', 'Failed to accept booking');
}
```

## Performance Considerations

1. **Reactive Updates**: Using Getx Obx for efficient rebuilds
   - Only affected widgets rebuild
   - Not entire page

2. **Debouncing**: Not needed here (discrete actions)

3. **Database Optimization**: 
   - Single Firestore write operation
   - Uses FieldValue.increment() for atomic updates

4. **Memory**: 
   - Observable objects properly disposed
   - No memory leaks from listeners

## Testing Checklist

- [ ] Tap TEST button → Popup shows
- [ ] Accept booking → Seats reduce
- [ ] Available seats decrease by booked amount
- [ ] Allocated seats increase by booked amount
- [ ] Firebase updates seats correctly
- [ ] Success message shows correct numbers
- [ ] Reject booking → No seat changes
- [ ] Multiple bookings work sequentially
- [ ] UI updates automatically without refresh

## Logging Points

All major operations log with prefixes:

```
[RideInProgressScreen]  - UI screen actions
[RideController]        - State management
[BookingController]     - Booking logic
[BookingService]        - Firebase operations
```

Look for these in console when debugging.
