# 📊 Real-Time Booking Listener - Visual Guide

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  FIREBASE FIRESTORE                         │
│                 (Bookings Collection)                       │
└──────────────────────────┬──────────────────────────────────┘
                           │
                    (Real-Time Updates)
                           │
                           ↓
┌─────────────────────────────────────────────────────────────┐
│              BOOKING SERVICE                                │
│  listenToDriverPendingBookings(driverId)                   │
│  ├─ Filters: driverId + status='pending'                  │
│  └─ Returns: Stream<List<BookingModel>>                   │
└──────────────────────────┬──────────────────────────────────┘
                           │
                    (Booking updates)
                           │
                           ↓
┌─────────────────────────────────────────────────────────────┐
│              BOOKING CONTROLLER                             │
│  startListeningWithNotifications(driverId)                 │
│  ├─ Subscribes to real-time stream                         │
│  ├─ Checks _shownBookingIds (prevent duplicates)           │
│  ├─ Updates currentBooking.value                           │
│  └─ Logs all activity                                      │
└──────────────────────────┬──────────────────────────────────┘
                           │
                 (Booking value changed)
                           │
                           ↓
┌─────────────────────────────────────────────────────────────┐
│          RIDE IN PROGRESS / HOME SCREEN                     │
│  ever(bookingController.currentBooking, (booking) {        │
│    _showBookingPopup(booking);                             │
│  })                                                         │
└──────────────────────────┬──────────────────────────────────┘
                           │
                    (Popup triggered)
                           │
                           ↓
┌─────────────────────────────────────────────────────────────┐
│        BOOKING NOTIFICATION POPUP                           │
│  ┌────────────────────────────────────────────────┐        │
│  │  📲 New Booking Request                        │        │
│  ├────────────────────────────────────────────────┤        │
│  │  🪑 Seats Booked: 3                           │        │
│  │  📍 Pickup: 123 Main Street                   │        │
│  │  📍 Dropoff: 456 Oak Avenue                   │        │
│  │  💰 Total Price: ₹450                         │        │
│  ├────────────────────────────────────────────────┤        │
│  │  [✅ Accept] [❌ Reject]                       │        │
│  └────────────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

## Real-Time Update Flow

```
Event: New Booking Created in Firebase
│
├─→ timestamp: 10:00:00
│
├─→ Firestore sends snapshot
│   └─ latency: < 100ms
│
├─→ BookingService receives update
│   └─ time: 10:00:00.050
│
├─→ BookingController processes
│   ├─ checks _shownBookingIds
│   ├─ marks as shown
│   └─ updates currentBooking
│   └─ time: 10:00:00.100
│
├─→ ever() watcher triggered
│   └─ time: 10:00:00.110
│
├─→ _showBookingPopup() called
│   └─ time: 10:00:00.150
│
└─→ 🎉 Popup visible to driver
    └─ total latency: < 150ms
```

## State Diagram

```
                    ┌──────────────┐
                    │   LISTENING  │
                    │   (Started)  │
                    └──────┬───────┘
                           │
         New Booking Detected
                           │
                           ↓
      ┌────────────────────────────────────┐
      │  Check _shownBookingIds             │
      │  (Already shown?)                   │
      └──────┬─────────────────────────────┘
             │
        ─────┴─────
        │         │
       YES        NO
        │         │
        ↓         ↓
    IGNORE    NEW! 🆕
    (Skip)    (Show Popup)
        │         │
        │         ↓
        │    ┌──────────────────┐
        │    │ currentBooking =  │
        │    │    booking        │
        │    └────────┬─────────┘
        │             │
        │             ↓
        │      ┌──────────────────┐
        │      │ ever() triggered  │
        │      │ _showBookingPopup │
        │      └────────┬─────────┘
        │               │
        │               ↓
        │        ┌──────────────────┐
        │        │ Bottom Sheet Show │
        │        │ ✅ Accept         │
        │        │ ❌ Reject         │
        │        └────────┬─────────┘
        │                 │
        └─────────────────┘
                 │
              ✅ OR ❌
                 │
                 ↓
         ┌──────────────────┐
         │ Firebase Update  │
         │ + Success Popup  │
         └──────────────────┘
```

## Duplicate Prevention

```
Scenario: Showing Same Booking Twice

TIME    ACTION                          _shownBookingIds
────────────────────────────────────────────────────────
10:00   Booking received from Firebase  {}
        ↓
        Check: booking_001 in set? NO!
        ↓
        Add to set
        ↓
        Show popup                      {booking_001}
        
        Driver accepts
        
10:05   Firestore still has this booking
        (Status not yet changed)
        
        Real-time update fires
        ↓
        Receive booking_001 again
        ↓
        Check: booking_001 in set? YES ✅
        ↓
        Skip! (Don't show again)        {booking_001}

Result: ✅ No duplicate popup!
```

## Listener Lifecycle

```
┌───────────────────────────────────────────────┐
│  App Launches / Screen Opens                  │
└──────────────────┬────────────────────────────┘
                   │
                   ↓
        ┌─────────────────────────┐
        │ Get Driver ID           │
        │ from AuthController     │
        └────────────┬────────────┘
                     │
                     ↓
        ┌─────────────────────────┐
        │ BookingController.      │
        │ startListening          │
        │ WithNotifications(id)   │
        └────────────┬────────────┘
                     │
                     ↓
        ┌─────────────────────────┐
        │ Subscribe to            │
        │ Firestore Stream        │
        │                         │
        │ Filters Applied:        │
        │ - driverId == id        │
        │ - status == pending     │
        │ - ordered by bookedAt   │
        └────────────┬────────────┘
                     │
                     ✅ LISTENING
                     │
           ┌─────────┴──────────┬──────────┐
           │                    │          │
           ↓                    ↓          ↓
        NEW              UPDATED        CLOSED
        BOOKING           BOOKING       CONNECTION
           │                  │          │
           └─→ Show Popup    └─→ Ignore  └─→ Stop
```

## Console Visualization

```
📱 DRIVER APP STARTUP
│
├─ [AuthController] Current Driver: driver_abc123
├─ [RideInProgressScreen] 🚀 Screen initialized
├─ [RideInProgressScreen] 👂 Starting real-time booking listener...
├─ [RideInProgressScreen] 🆔 Driver ID: driver_abc123
├─ [BookingController] 👂 Starting real-time listener for bookings...
└─ [BookingController] ✅ Real-time listener started for driver: driver_abc123

⏳ WAITING (Listening...)

🔔 NEW BOOKING CREATED IN FIREBASE
│
├─ [BookingController] 📲 Received 1 booking(s) from Firestore
├─ [BookingController] 🆕 NEW BOOKING DETECTED: booking_001
├─ [BookingController] 📢 Seats: 3
├─ [BookingController] 💰 Price: ₹450
├─ [RideInProgressScreen] 🔔 Booking changed: booking_001
├─ [RideInProgressScreen] 📲 Showing popup for: booking_001
└─ [RideInProgressScreen] 🔴 Showing popup...

👆 DRIVER ACCEPTS BOOKING
│
├─ [RideInProgressScreen] ➡️ Accepting booking...
├─ [BookingController] ➡️ Accepting booking...
├─ [BookingService] ➡️ Accepting booking: booking_001
├─ [BookingService] ✅ Booking accepted: booking_001
├─ [RideInProgressScreen] ✅ Booking accepted, reducing available seats
├─ [RideController] 📉 Reducing available seats by 3
├─ [RideController] Before: Available = 5, Allocated = 0
├─ [RideController] After: Available = 2, Allocated = 3
├─ [RideInProgressScreen] 🔔 Booking popup closed
├─ [RideInProgressScreen] ===== SHOWING ACTION MENU =====
├─ [RideInProgressScreen] Title: Booking Accepted!
└─ [RideInProgressScreen] Message: Seats allocated: 3...

⏳ LISTENING FOR NEXT BOOKING...
```

## Performance Metrics

```
METRIC              BEFORE (Polling)    AFTER (Real-Time)
─────────────────────────────────────────────────────────
Latency             ~5 seconds          < 1 second
Requests/min        12 (no bookings)    0 (no bookings)
Bandwidth           Moderate            Minimal
Firebase Costs      Higher              Lower
User Experience     Delayed             Instant
CPU Usage          Constant polling     Event-driven
Battery Drain      Higher              Lower
```

## Decision Tree

```
Is driver logged in?
├─ NO → Don't start listener
└─ YES ↓

    Is driver ID available?
    ├─ NO → Log error, skip
    └─ YES ↓

        Start Firestore listener
        ├─ Subscribe to bookings stream
        └─ Apply filters (driver + pending)
             │
             ├─ New booking? 🆕
             │  ├─ YES → Check _shownBookingIds
             │  │        ├─ Already shown? 
             │  │        │  ├─ NO → Show popup 📲
             │  │        │  └─ YES → Ignore
             │  │        └─ Update currentBooking
             │  │
             │  └─ NO → Wait for next...
             │
             └─ Error occurred?
                └─ Log & save error message
```

## Comparison: Polling vs Real-Time

```
POLLING (Old Way)
┌────────┬────────┬────────┬────────┐
│ Check  │ Check  │ Check  │ Check  │ ...
│ (miss) │ (miss) │ (hit!) │ (miss) │
└────┬───┴────┬───┴────┬───┴────┬───┘
     5s       5s       5s       5s
             ↑ USER DELAYED 5s

REAL-TIME (New Way)
═══════════════════════════════════════════════
                         ✨ BOOKING ARRIVES!
                         ↓
                       (< 1 second)
                         ↓
                    📲 POPUP SHOWS
             ↑ USER SEES INSTANTLY!
```

---

**Visual Guide Complete!** 📊

Use this guide to understand how real-time booking detection works.
