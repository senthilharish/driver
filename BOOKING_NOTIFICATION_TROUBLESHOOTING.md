# Booking Notification System - Troubleshooting Guide

## Common Issues & Solutions

### 1. Notifications Not Showing

#### Issue
Push notifications don't appear when a new booking arrives.

#### Possible Causes & Solutions

**A. Permissions Not Granted**
```bash
Solution:
1. Go to device Settings
2. Find "Driver" app
3. Go to Permissions
4. Enable "Notifications"
5. Make sure notification access is granted in system settings

Android:
Settings > Apps > Driver > Notifications > Allow notifications

iOS:
Settings > Driver > Notifications > Allow Notifications
```

**B. Notification Channel Not Created**
```dart
Solution:
The NotificationService.initialize() should be called.
Check in console for:
[NotificationService] ✅ Notification service initialized

If you see an error instead:
[NotificationService] ❌ Initialization error: ...
Then the channel creation failed.
```

**C. App Running in Background**
```
Solution:
For notifications to show in background:

Android:
- App must have been started at least once
- Background notification permission must be granted
- Device should not be in deep sleep mode

iOS:
- App must have been started at least once
- Push notifications should be enabled in device settings
```

**D. No Pending Bookings**
```
Solution:
Verify that:
1. A booking exists in Firestore with status: "pending"
2. The booking's driverId matches your driver's UID
3. Check Firestore console: https://console.firebase.google.com

Query to verify:
db.collection("bookings").where("status", "==", "pending").limit(1).get()
```

---

### 2. Popup Not Displaying

#### Issue
Notification shows but popup dialog doesn't appear.

#### Possible Causes & Solutions

**A. Home Screen Not Loaded**
```dart
Solution:
The popup only shows on HomeScreen.
Ensure you are on the home screen when booking arrives.

Check:
1. Navigate to Home Screen first
2. Wait for initialization
3. Then test booking
4. If popup doesn't show, check console for errors
```

**B. BookingController Not Registered**
```dart
Solution:
Verify in main.dart:

void main() {
  // ...
  Get.put(BookingController());  // ← Must be here
  // ...
}

If missing:
1. Add the line above
2. Run: flutter pub get
3. Restart app
```

**C. Listener Not Started**
```dart
Solution:
In _HomeScreenState._setupBookingListener():

The listener must start when home screen loads.
Check console for:
[BookingController] 👂 Starting to listen for bookings...

If you don't see this:
1. Check if _setupBookingListener() is called in initState()
2. Verify driverId is not empty
3. Check for exceptions in console
```

**D. currentBooking Not Updating**
```dart
Solution:
The ever() listener in home screen watches currentBooking.

If popup doesn't show:
1. Check: [BookingController] 📢 Received booking: ...
2. If no log, booking isn't being detected
3. Verify Firestore has pending booking with correct driverId
4. Check internet connection
```

---

### 3. Accept/Reject Not Working

#### Issue
Buttons don't work or response takes too long.

#### Possible Causes & Solutions

**A. Internet Connection**
```
Solution:
1. Check if device has internet
2. Verify WiFi or mobile data is connected
3. Check Firestore is accessible

Test:
- Try to load home screen (should show driver info)
- If home screen is blank, no internet connection
```

**B. Firestore Permissions**
```
Solution:
Update Firestore rules to allow updates:

firestore.rules:
match /bookings/{bookingId} {
  allow read: if request.auth.uid == resource.data.driverId;
  allow update: if request.auth.uid == resource.data.driverId;
}

match /rides/{rideId} {
  allow update: if request.auth.uid == resource.data.driverId;
}
```

**C. Loading State Stuck**
```dart
Solution:
If isLoading stays true:

Check console for:
[BookingController] ❌ Error: ...

This means the operation failed.
Solutions:
1. Check Firestore permissions
2. Verify bookingId exists
3. Verify driverId matches
4. Check network connection
```

**D. No Response from Server**
```
Solution:
1. Wait 5-10 seconds for response
2. Check Firestore console for recent writes
3. Verify in Firestore the status changed
4. If nothing changes, check error logs

Logs to check:
[BookingService] ➡️ Accepting booking...
[BookingService] ✅ Booking accepted: ...

If you see error instead, note the error message.
```

---

### 4. Multiple Notifications Appearing

#### Issue
Getting duplicate notifications or too many notifications.

#### Possible Causes & Solutions

**A. Listener Started Multiple Times**
```dart
Solution:
Listener should start only once in home screen.

Check:
void _setupBookingListener() {
  // Should only be called once in initState()
  _bookingController.startListeningWithNotifications(driverId);
  
  // Should not be called in build() or other methods
}

If called multiple times:
Disable Dart rebuild to prevent multiple starts
Add flag to track if listener started:

bool _listenerStarted = false;

void _setupBookingListener() {
  if (_listenerStarted) return;
  _listenerStarted = true;
  _bookingController.startListeningWithNotifications(driverId);
}
```

**B. Same Booking Notified Repeatedly**
```dart
Solution:
If you get same notification multiple times:

1. Previous booking was never cleared
2. currentBooking.value wasn't set to null

Solution:
Always set currentBooking to null after handling:

_bookingController.currentBooking.value = null;
```

**C. Test Data in Firestore**
```
Solution:
Clean up Firestore test data:

1. Go to Firebase console
2. Delete duplicate bookings
3. Keep only valid pending bookings
4. Restart app
```

---

### 5. Notification Sound Not Working

#### Issue
Notification appears but no sound.

#### Possible Causes & Solutions

**A. Device Volume Muted**
```
Solution:
1. Check device volume is not on silent
2. Adjust volume while notification is playing
3. Ensure notification volume is separate from media volume

Android:
Settings > Sound > Notification volume > Increase

iOS:
Settings > Sound > Ringer and Alerts > On
```

**B. Sound File Not Found**
```dart
Solution:
In notification_service.dart:

// For Android, place notification_sound.mp3 in:
// android/app/src/main/res/raw/notification_sound.mp3

// For iOS, place in Xcode project:
// ios/Runner/notification_sound.aiff

Then reference in code:
sound: RawResourceAndroidNotificationSound('notification_sound')
sound: 'notification_sound.aiff'
```

**C. Notification Channel Settings**
```dart
Solution:
Verify Android notification details:

const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
  'booking_channel',
  'Booking Notifications',
  sound: RawResourceAndroidNotificationSound('notification_sound'),
  playSound: true,  // ← Must be true
);
```

**D. System Notification Sound Disabled**
```
Solution:
Android:
Settings > Apps > Driver > Notifications > Enable sound

iOS:
Settings > Driver > Allow Sounds
```

---

### 6. App Crashing on Booking

#### Issue
App crashes when new booking arrives.

#### Possible Causes & Solutions

**A. BookingModel Parsing Error**
```dart
Solution:
If booking data from Firestore doesn't match model:

Check BookingModel.fromJson() for missing fields:
- bookingId
- rideId
- userId
- driverId
- pickupLocation
- dropoffLocation
- seatsBooked
- pricePerSeat
- totalPrice
- status
- isApproved
- bookedAt

Ensure Firestore booking has all these fields.

If field is missing, add default value in fromJson():
factory BookingModel.fromJson(Map<String, dynamic> json) {
  return BookingModel(
    bookingId: json['bookingId'] ?? 'unknown',
    // ...
  );
}
```

**B. Null Pointer Exception**
```dart
Solution:
Check all null safety:

// Before using:
if (booking != null) {
  _showBookingPopup(booking);
}

// When accessing fields:
booking?.pickupLocation ?? 'Unknown'
```

**C. Widget Build Error**
```dart
Solution:
If PopupWidget crashes:

1. Check all required fields are provided
2. Verify booking data is valid
3. Check text fields don't exceed constraints

In booking_popup.dart:
// Make sure all data is provided
required BookingModel booking,
```

**D. Stream Error**
```dart
Solution:
Check stream error handling:

_service.listenToDriverPendingBookings(driverId).listen(
  (bookings) { /* process */ },
  onError: (error) {
    print('[Error] $error');
  },
);
```

---

### 7. Notification Payload Issues

#### Issue
Notification shows but bookingId is not passed correctly.

#### Possible Causes & Solutions

**A. Payload Empty**
```dart
Solution:
In notification_service.dart:

await _notificationsPlugin.show(
  bookingId.hashCode,
  title,
  body,
  notificationDetails,
  payload: bookingId,  // ← Must be set
);
```

**B. Can't Click Notification**
```dart
Solution:
Verify tap handler is set:

In NotificationService.initialize():

onDidReceiveNotificationResponse: (NotificationResponse response) {
  print('[NotificationService] Notification tapped: ${response.payload}');
  // You can navigate here based on payload
},
```

---

### 8. Performance Issues

#### Issue
App feels slow when booking arrives.

#### Possible Causes & Solutions

**A. Too Many Listeners**
```dart
Solution:
Ensure listener is not created in build():

// ❌ Wrong - creates listener every build
@override
Widget build(BuildContext context) {
  bookingController.startListening(); // Bad!
  // ...
}

// ✅ Correct - create once in initState
@override
void initState() {
  _setupBookingListener(); // Good
  super.initState();
}
```

**B. Large Booking Data**
```
Solution:
Keep booking data minimal:
- Use IDs instead of full objects
- Limit location string length
- Remove unnecessary fields
```

**C. UI Rebuild Loop**
```dart
Solution:
Use Obx() to prevent unnecessary rebuilds:

Obx(() {
  if (bookingController.currentBooking.value != null) {
    return BookingPopup(...);
  }
  return SizedBox.shrink();
})
```

---

### 9. Firestore Connection Issues

#### Issue
"Can't connect to Firestore" errors.

#### Possible Causes & Solutions

**A. Internet Not Working**
```
Solution:
1. Check WiFi/mobile connection
2. Try accessing a website
3. Restart internet connection
4. Restart app
```

**B. Firebase Not Initialized**
```dart
Solution:
Verify in main.dart:

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // ...
}
```

**C. Wrong Firebase Project**
```
Solution:
1. Verify google-services.json is current
2. Check Firebase console project ID matches
3. Re-download google-services.json if needed
```

**D. Firestore Rules Blocking Access**
```firestore
Solution:
Check rules allow reading bookings:

match /bookings/{bookingId} {
  allow read: if true; // or more restrictive condition
}
```

---

### 10. Permission Denied Errors

#### Issue
"Permission Denied" when accessing Firestore.

#### Possible Causes & Solutions

**A. Firestore Security Rules**
```firestore
Solution:
Update rules to allow driver access:

match /bookings/{bookingId} {
  allow read: if request.auth.uid == resource.data.driverId;
  allow update: if request.auth.uid == resource.data.driverId;
}

match /rides/{rideId} {
  allow update: if request.auth.uid == resource.data.driverId;
}
```

**B. User Not Authenticated**
```dart
Solution:
Verify user is logged in:

if (_authController.isAuthenticated.value) {
  // Safe to proceed
}
```

**C. UID Mismatch**
```
Solution:
Ensure:
1. Driver UID in database matches auth UID
2. Booking driverId matches driver UID
3. Check Firestore for correct UIDs
```

---

## Debugging Checklist

When something goes wrong:

- [ ] Check console for error logs
- [ ] Look for [BookingController], [BookingService], [NotificationService] logs
- [ ] Verify internet connection is active
- [ ] Check Firestore has pending bookings
- [ ] Verify booking has correct driverId
- [ ] Check app has required permissions
- [ ] Verify user is authenticated
- [ ] Check device volume is not muted
- [ ] Verify Firestore security rules
- [ ] Check if same booking already processed
- [ ] Try restarting the app
- [ ] Check device logs: `flutter logs`
- [ ] Verify Firebase connection: try loading home screen

---

## Getting Help

If issue persists:

1. **Check the logs** - Copy exact error message
2. **Verify Firestore** - Check booking data structure
3. **Review code** - Compare with examples in documentation
4. **Test with sample data** - Use Firestore console to create test booking
5. **Check Firebase** - Go to https://console.firebase.google.com
6. **Restart everything** - Kill app, clear cache, restart phone

---

## Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| "Permission denied" | Firestore rules | Update rules |
| "Failed to fetch booking" | Booking not found | Check booking exists |
| "Network error" | No internet | Check connection |
| "Notification permission denied" | App permission | Grant in settings |
| "UID mismatch" | Wrong driver ID | Verify auth |
| "No pending bookings" | No data in Firestore | Create booking |
| "Cannot update booking" | Firestore rules | Check permissions |
| "Null pointer" | Missing data | Add validation |

---

**Last Updated:** April 16, 2026
**System Version:** 1.0
