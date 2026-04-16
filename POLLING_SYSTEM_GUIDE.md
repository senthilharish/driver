# Polling System Implementation Guide

## Overview

The booking notification system now includes a **5-second polling mechanism** that periodically checks the database for new bookings. This is more reliable than real-time listeners in some scenarios and provides better control over update frequency.

---

## What Changed

### 1. BookingController Updates

Added new polling methods:
- `startPollingBookings(String driverId)` - Start polling every 5 seconds
- `pausePollingBookings()` - Pause polling temporarily
- `resumePollingBookings(String driverId)` - Resume after pause
- `stopPollingBookings()` - Stop polling completely
- `_pollBookings(String driverId)` - Internal method called every 5 seconds

Added new observable properties:
- `pollingActive` - Whether polling is currently active
- `lastPolledTime` - Timestamp of last poll

### 2. Home Screen Updates

- Replaced real-time listener with polling
- Added polling status indicator card
- Shows "Active" or "Inactive" status
- Shows last poll time
- Automatically stops polling on dispose

### 3. BookingPopup Updates

- Enhanced button styling with icons
- Better visual feedback
- Improved button animations
- Better disabled state appearance

---

## How It Works

### Polling Flow

```
1. HomeScreen initializes
   ↓
2. Calls startPollingBookings(driverId)
   ↓
3. Polls database immediately
   ↓
4. Starts 5-second timer
   ↓
5. Every 5 seconds: Fetch pending bookings
   ↓
6. Compare with current booking
   ↓
7. If new booking detected:
   - Update currentBooking
   - Send notification
   - Show popup
   ↓
8. Update lastPolledTime
   ↓
9. Repeat from step 5
```

### Code Flow

```dart
// Start polling
_bookingController.startPollingBookings(driverId);

// Every 5 seconds, this runs:
Future<void> _pollBookings(String driverId) {
  // Fetch bookings
  final bookingsList = await _service
      .listenToDriverPendingBookings(driverId)
      .first;
  
  // Check if new
  if (bookingsList.isNotEmpty && isNewBooking) {
    // Send notification
    _sendBookingNotification(booking);
  }
  
  // Update time
  lastPolledTime.value = DateTime.now();
}
```

---

## Key Features

### 1. Automatic Polling
```dart
// Starts automatically when home screen loads
_bookingController.startPollingBookings(driverId);

// Checks database every 5 seconds
Duration(seconds: 5)
```

### 2. New Booking Detection
```dart
// Only shows notification for NEW bookings
if (currentBooking.value == null || 
    currentBooking.value!.bookingId != latestBooking.bookingId) {
  // Send notification
  _sendBookingNotification(latestBooking);
}
```

### 3. Visual Status Indicator
Shows:
- 🟢 **Active** - Polling is running
- 🔴 **Inactive** - Polling stopped
- Last polled timestamp
- Animated indicator during poll

### 4. Automatic Cleanup
```dart
@override
void dispose() {
  // Stop polling when leaving screen
  _bookingController.stopPollingBookings();
  super.dispose();
}
```

---

## Configuration

### Poll Interval

To change from 5 seconds to different interval:

```dart
// In BookingController.startPollingBookings()

// Change this line:
_pollingTimer = Timer.periodic(
  const Duration(seconds: 5),  // ← Change this
  (_) => _pollBookings(driverId),
);

// Examples:
Duration(seconds: 3)    // Poll every 3 seconds
Duration(seconds: 10)   // Poll every 10 seconds
Duration(seconds: 30)   // Poll every 30 seconds
Duration(minutes: 1)    // Poll every 1 minute
```

### Disable Polling

To use real-time listeners instead:

```dart
// In home_screen.dart, change from:
_bookingController.startPollingBookings(driverId);

// To:
_bookingController.startListeningWithNotifications(driverId);
```

---

## Polling Status UI

### Visual Indicator

The home screen displays:

```
┌─────────────────────────────────────┐
│ ⟳ Booking Polling Status             │
│                                      │
│ 🟢 Active - Checking every 5 seconds │
│ Last polled: HH:MM:SS                │
└─────────────────────────────────────┘
```

### Colors
- **Green**: Polling is active
- **Red**: Polling is inactive
- Shows animated spinner when active

### Information Shown
- Polling status (Active/Inactive)
- Update frequency (every 5 seconds)
- Last poll timestamp
- Real-time updates as polls happen

---

## Usage Examples

### Start Polling (Automatic)

```dart
// Already started in home screen
void _setupBookingListener() {
  final driverId = _authController.currentDriver.value?.uid ?? '';
  _bookingController.startPollingBookings(driverId);
}
```

### Pause Polling

```dart
// When user is temporarily away
_bookingController.pausePollingBookings();
```

### Resume Polling

```dart
// When user comes back
_bookingController.resumePollingBookings(driverId);
```

### Stop Polling

```dart
// When leaving the app
_bookingController.stopPollingBookings();
```

---

## Console Logs

When polling is active, you'll see logs like:

```
[BookingController] ⏱️ Starting polling for bookings every 5 seconds...
[BookingController] ✅ Polling started
[BookingController] 🔄 Polling database for bookings...
[BookingController] 📢 New booking detected: booking_123
[BookingController] ✅ Poll completed at 2026-04-16 14:30:45.123456
[BookingController] 🔄 Polling database for bookings...
[BookingController] ℹ️ No more pending bookings
[BookingController] ✅ Poll completed at 2026-04-16 14:30:50.123456
```

### Log Meanings

| Log | Meaning |
|-----|---------|
| ⏱️ Starting polling | Polling initialized |
| ✅ Polling started | Timer created and running |
| 🔄 Polling database | Checking for new bookings |
| 📢 New booking detected | New booking found |
| ✅ Poll completed | Poll cycle finished |
| ℹ️ No pending bookings | No bookings in database |
| ❌ Polling error | Error during poll |
| 🛑 Polling stopped | Polling terminated |
| ⏸️ Polling paused | Polling temporarily paused |
| ▶️ Polling resumed | Polling restarted |

---

## Polling vs Real-Time Listeners

### Polling (Current Implementation)

**Advantages:**
- ✅ Predictable update frequency
- ✅ Controlled database hits
- ✅ Can pause/resume easily
- ✅ Works reliably in all scenarios
- ✅ Easy to debug timing issues

**Disadvantages:**
- ⚠️ Slight delay (up to 5 seconds)
- ⚠️ More battery usage (periodic wakeups)
- ⚠️ More database calls

### Real-Time Listeners

**Advantages:**
- ✅ Instant updates
- ✅ Only query when data changes
- ✅ Lower battery usage
- ✅ Better user experience

**Disadvantages:**
- ⚠️ Requires active Firestore listener
- ⚠️ More complex to control
- ⚠️ May miss updates in poor network

### When to Use What

**Use Polling When:**
- You need predictable timing
- Network is unstable
- You want full control over update frequency
- Debugging timing issues
- Battery is a concern (wider intervals)

**Use Real-Time When:**
- You want instant updates
- Network is reliable
- You don't need control over frequency
- User experience is priority

---

## Performance Considerations

### Database Load

Each poll makes 1 Firestore query:
- Polling every 5 seconds = 720 queries/hour/driver
- Polling every 10 seconds = 360 queries/hour/driver
- Polling every 60 seconds = 60 queries/hour/driver

### Battery Impact

Polling impacts battery through:
- Timer wakeups (minor)
- Network calls (varies)
- Screen updates (if active)

### Network Bandwidth

Each poll is a small query:
- ~1-2 KB per poll
- 5 second interval = ~1-2 MB/hour/driver

---

## Troubleshooting

### Polling Not Starting

**Check:**
```dart
// Verify startPollingBookings is called
print(_bookingController.pollingActive.value); // Should be true

// Check console for:
[BookingController] ⏱️ Starting polling...
[BookingController] ✅ Polling started
```

### Polling Stops Unexpectedly

**Check:**
```dart
// Verify screen is still active
print('Current page: ${Get.currentRoute}');

// Verify dispose wasn't called
// (leaving home screen stops polling - this is normal)
```

### Updates Not Frequent Enough

**Change interval:**
```dart
// In BookingController.startPollingBookings()
Duration(seconds: 3)  // Faster polling
```

### Too Many Database Calls

**Increase interval:**
```dart
Duration(seconds: 10)  // Less frequent polling
```

### Battery Draining

**Options:**
1. Increase poll interval: `Duration(seconds: 10)`
2. Switch to real-time listeners
3. Use pause/resume to stop polling when app is backgrounded

---

## Best Practices

### ✅ DO

- Start polling in `initState()`
- Stop polling in `dispose()`
- Check `pollingActive` before starting again
- Use pause/resume for app lifecycle events
- Monitor console logs during development

### ❌ DON'T

- Start multiple polling timers simultaneously
- Forget to stop polling (memory leak)
- Use very short intervals (<1 second) without reason
- Call startPollingBookings repeatedly
- Rely on exact 5-second timing for critical operations

---

## Code Example: Complete Setup

```dart
class HomeScreen extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    _setupBookingListener();
  }

  void _setupBookingListener() {
    final driverId = _authController.currentDriver.value?.uid ?? '';
    if (driverId.isNotEmpty) {
      // Start polling every 5 seconds
      _bookingController.startPollingBookings(driverId);
      
      // Watch for new bookings and show popup
      ever(_bookingController.currentBooking, (booking) {
        if (booking != null && mounted) {
          _showBookingPopup(booking);
        }
      });
    }
  }

  @override
  void dispose() {
    // Stop polling when leaving home screen
    _bookingController.stopPollingBookings();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... UI code ...
      body: Column(
        children: [
          // Polling Status Card
          Obx(() => _buildPollingStatus()),
          
          // Rest of UI
        ],
      ),
    );
  }
}
```

---

## Summary

Your booking system now:
✅ Polls database every 5 seconds
✅ Detects new bookings automatically
✅ Shows visual polling status
✅ Can pause/resume polling
✅ Automatically cleans up on app close
✅ Provides detailed logging

Enjoy reliable booking detection! 🚀

---

**System Version:** 2.0 (Polling)
**Date:** April 16, 2026
**Status:** Production Ready
