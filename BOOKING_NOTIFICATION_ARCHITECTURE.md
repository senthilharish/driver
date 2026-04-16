# Booking Notification System - Architecture Diagram

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Driver App                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐         ┌──────────────┐                    │
│  │  Home Screen │◄────────│  UI Widgets  │                    │
│  └──────┬───────┘         └──────────────┘                    │
│         │                                                      │
│         │ starts listener                                     │
│         ▼                                                      │
│  ┌──────────────────────────────────────────────┐            │
│  │    BookingController (GetX)                  │            │
│  │  ┌──────────────────────────────────────┐  │            │
│  │  │ • currentBooking: Rx<BookingModel>   │  │            │
│  │  │ • pendingBookings: RxList            │  │            │
│  │  │ • isLoading: Rx<bool>                │  │            │
│  │  │ • errorMessage: Rx<String>           │  │            │
│  │  │                                      │  │            │
│  │  │ Methods:                             │  │            │
│  │  │ • startListeningWithNotifications()  │  │            │
│  │  │ • acceptBooking()                    │  │            │
│  │  │ • rejectBooking()                    │  │            │
│  │  │ • _sendBookingNotification()         │  │            │
│  │  └──────────────────────────────────────┘  │            │
│  └──────┬────────────────────────────┬─────────┘            │
│         │                            │                       │
│         │ uses                       │ uses                  │
│         ▼                            ▼                       │
│  ┌──────────────┐          ┌─────────────────────┐          │
│  │BookingService│          │NotificationService │          │
│  │              │          │                     │          │
│  │ • Firebase   │          │ • Local Notifs      │          │
│  │   Firestore  │          │ • Sound & Vibration │          │
│  │ • Listeners  │          │ • Permissions       │          │
│  │ • CRUD Ops   │          └─────────────────────┘          │
│  └──────┬───────┘                                           │
│         │                                                    │
│         │ ◄────────────────────────────┐                     │
│         │ listens to stream            │ updates             │
│         ▼                              │                     │
│  ┌──────────────────────────────────────────┐               │
│  │         Firestore (Firebase)             │               │
│  │  ┌──────────────────────────────────┐   │               │
│  │  │ bookings/ (collection)           │   │               │
│  │  │   └─ {bookingId} (document)      │   │               │
│  │  │       ├─ bookingId: String       │   │               │
│  │  │       ├─ rideId: String          │   │               │
│  │  │       ├─ userId: String          │   │               │
│  │  │       ├─ driverId: String        │   │               │
│  │  │       ├─ pickupLocation: String  │   │               │
│  │  │       ├─ dropoffLocation: String │   │               │
│  │  │       ├─ seatsBooked: int        │   │               │
│  │  │       ├─ totalPrice: double      │   │               │
│  │  │       ├─ status: String          │   │               │
│  │  │       │  (pending/accepted/...)  │   │               │
│  │  │       └─ bookedAt: DateTime      │   │               │
│  │  └──────────────────────────────────┘   │               │
│  └──────────────────────────────────────────┘               │
│         ▲                                                    │
│         │                                                    │
│         │ creates booking                                   │
└─────────┼────────────────────────────────────────────────────┘
          │
          │ Firestore
          │
┌─────────┴────────────────────────────────────────────────────┐
│                     Passenger App                            │
│                                                              │
│  User Creates Booking                                        │
│  ↓                                                           │
│  Booking Details Filled                                      │
│  ↓                                                           │
│  Sent to Firestore with status: "pending"                   │
└──────────────────────────────────────────────────────────────┘
```

## Booking Popup Flow

```
┌─────────────────────────────────────────────────────────────┐
│                   BookingPopup Widget                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │              Header Section                           │ │
│  │  🚕 New Booking Request                              │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │         Pickup Location Card (Green)                 │ │
│  │  🟢 📍 Pickup Location                               │ │
│  │     Address: [booking.pickupLocation]                │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │        Dropoff Location Card (Red)                   │ │
│  │  🔴 📍 Dropoff Location                              │ │
│  │     Address: [booking.dropoffLocation]               │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │         Booking Details Section                       │ │
│  │  👥 Number of Seats: [booking.seatsBooked]           │ │
│  │  ─────────────────────────────────────               │ │
│  │  💵 Base Price: ₹[booking.pricePerSeat]              │ │
│  │  ─────────────────────────────────────               │ │
│  │  💰 Total Price: ₹[booking.totalPrice] ⭐            │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌──────────────────────┐   ┌──────────────────────────┐   │
│  │  ✅ Accept Booking   │   │   ❌ Decline Booking     │   │
│  │   (Green Button)     │   │   (Outlined Button)      │   │
│  └──────────────────────┘   └──────────────────────────┘   │
│         │                              │                    │
│         ▼                              ▼                    │
│   acceptBooking()              rejectBooking()              │
│         │                              │                    │
│         └──────────────┬───────────────┘                    │
│                        ▼                                     │
│                Firestore Update                             │
│                  status: accepted/rejected                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## State Management Flow

```
                    ┌─────────────────────┐
                    │  Firestore Update   │
                    │  (New Booking)      │
                    └──────────┬──────────┘
                               │
                               │ Stream emits
                               ▼
                    ┌─────────────────────┐
                    │  BookingService     │
                    │  listenToDriver...()│
                    └──────────┬──────────┘
                               │
                               │ Emits booking
                               ▼
                    ┌─────────────────────┐
                    │ BookingController   │
                    │ currentBooking.     │
                    │   value = booking   │
                    └──────────┬──────────┘
                               │
                               │ Triggers
                               ▼
                    ┌─────────────────────┐
                    │ NotificationService │
                    │ showBookingNotif... │
                    └──────────┬──────────┘
                               │
                               │ Notifies
                               ▼
                    ┌─────────────────────┐
                    │  Notification API   │
                    │  (OS Level)         │
                    └──────────┬──────────┘
                               │
                ┌──────────────┴──────────────┐
                │                            │
                │ notification             │ notification
                │ sound                     │ badge
                ▼                            ▼
            (Optional)              (Optional)
        Shows as alert
        
        Also Triggers in GetX:
        ever(_bookingController
             .currentBooking)
             │
             ▼
        showDialog(
          BookingPopup()
        )
```

## Data Flow Timeline

```
Timeline: Booking Acceptance Flow
═════════════════════════════════════════════════════════════

Time 0:  Passenger Creates Booking
         ├─ App sends to Firestore
         └─ Booking created with status: "pending"

Time 1:  Firestore Listener Triggers
         ├─ BookingService detects new pending booking
         └─ Emits booking data through stream

Time 2:  BookingController Receives Data
         ├─ currentBooking.value = booking
         └─ pendingBookings.add(booking)

Time 3:  Notification Triggered
         ├─ NotificationService.showBookingNotification()
         ├─ OS shows notification with:
         │  • Title: 🚕 New Booking Request
         │  • Body: Locations, seats, price
         │  • Sound: Plays
         │  • Vibration: On
         └─ Notification badge appears

Time 4:  Popup Displayed
         ├─ ever() listener triggers
         ├─ showDialog(BookingPopup)
         └─ User sees beautiful popup

Time 5:  User Interaction
         ├─ User reads booking details
         │  • Pickup & dropoff locations
         │  • Number of seats
         │  • Price breakdown
         └─ User taps Accept or Decline

Time 6:  Action Processing
         ├─ Loading state shows
         ├─ acceptBooking() or rejectBooking() called
         └─ BookingService.acceptBooking() executes

Time 7:  Database Update
         ├─ Firestore transaction:
         │  ├─ Update booking status
         │  ├─ Update approved timestamp
         │  └─ Update ride available seats
         └─ Changes propagate

Time 8:  UI Update & Cleanup
         ├─ isLoading = false
         ├─ currentBooking.value = null
         ├─ Popup closes
         └─ Notification dismissed

Time 9:  Ready for Next Booking
         └─ App listens for next pending booking
```

## Component Dependencies

```
                    ┌─────────────────┐
                    │   Flutter App   │
                    └────────┬────────┘
                             │
                ┌────────────┼────────────┐
                │            │            │
                ▼            ▼            ▼
            ┌────┐      ┌────────┐   ┌────────┐
            │Main│      │  UI    │   │Database│
            └────┘      └────────┘   └────────┘
             │               │            │
    Get.put()│               │            │
             │               │            │
             ├─ AuthController                │
             │                                │
             ├─ RideController                │
             │                                │
             ├─ BookingController             │
             │    │                           │
             │    ├─► BookingService ────────►│
             │    │                           │
             │    └─► NotificationService     │
             │                                │
             │    ┌─────────────────────┐     │
             │    │  HomeScreen Init    │     │
             │    │                     │     │
             │    ├─► startListeningWith...  │
             │    │                          │
             │    ├─► ever(currentBooking)   │
             │    │                          │
             │    └─► showDialog(Popup)      │
             │                               │
             └───────────────────────────────┘
```

## Error Handling Flow

```
┌────────────────────────────────────────────────────────────┐
│              Error Handling Architecture                    │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Operation                                                 │
│      ▼                                                      │
│  try {                                                      │
│    • Execute task                                          │
│      ├─ Booking fetch                                      │
│      ├─ Database update                                    │
│      ├─ Notification send                                  │
│      └─ UI update                                          │
│  }                                                          │
│      ▼                                                      │
│  catch (e) {                                               │
│    • Log error                                             │
│    • Print with [Prefix] tag                              │
│    • Update errorMessage observable                        │
│    • Show user-friendly message                           │
│    • Reset loading state                                   │
│      ├─ isLoading = false                                 │
│      ├─ Show error snackbar                               │
│      └─ Popup closes with error                           │
│  }                                                          │
│      ▼                                                      │
│  Logs Example:                                             │
│  [BookingController] ❌ Error: Network error               │
│  [BookingService] ❌ Error accepting booking: Permission  │
│  [NotificationService] ❌ Error showing notification       │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

This architecture ensures:
- ✅ Real-time updates
- ✅ Responsive UI
- ✅ Error resilience
- ✅ User-friendly notifications
- ✅ Clean separation of concerns
