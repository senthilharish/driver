# 🎨 Visual Guide - Booking Display & Seat Management

## User Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                    DRIVER'S RIDE IN PROGRESS                        │
│                                                                     │
│  AppBar: "Ride in Progress"                    [X] Cancel           │
│  ─────────────────────────────────────────────────────────────────  │
│                                                                     │
│  📍 Current Location Card                                           │
│  ├─ Start Location: Central Station                                │
│  ├─ Lat: 28.6345, Long: 77.2197                                   │
│  └─ [Border: Yellow]                                               │
│                                                                     │
│  📍 Destination Card                                               │
│  ├─ Destination: Downtown Plaza                                    │
│  └─ [Border: Green - Set]                                          │
│                                                                     │
│  ─────────────────────────────────────────────────────────────────  │
│  RIDE DETAILS                                                      │
│  ─────────────────────────────────────────────────────────────────  │
│                                                                     │
│  🪑 Total Seats            5          ← Total capacity             │
│                                                                     │
│  👥 Seats Allocated        0          ← Currently booked           │
│                                                                     │
│  🛫 Available Seats        5 ← ⭐ Updates when booking accepted    │
│                                                                     │
│  📏 Distance               12.45 km                                 │
│                                                                     │
│  👨‍👩‍👧‍👦 Passengers         5                                        │
│                                                                     │
│  💰 Base Price: ₹500                                               │
│  ─────────────────────────────────────────────────────────────────  │
│  💵 Total Price: ₹2,500                                            │
│                                                                     │
│  [View Route on Map]                                               │
│  [Complete Ride]                                                   │
│  [🧪 TEST: Show Booking Popup]                                    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                            ↓
                    (Booking Arrives)
                            ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    BOOKING NOTIFICATION POPUP                        │
│                                                                     │
│  ════════════════════════════════════════════════════════════════   │
│                                                                     │
│              📲 NEW BOOKING REQUEST                                 │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │ ┌─────────────────────────────────────────────────────────┐ │  │
│  │ │ 🪑 Seats Booked                           3           │ │  │
│  │ ├──────────────────────────────────────────────────────── │  │
│  │ │ 📍 Pickup                     123 Main Street          │ │  │
│  │ ├──────────────────────────────────────────────────────── │  │
│  │ │ 📍 Dropoff                    456 Oak Avenue           │ │  │
│  │ ├──────────────────────────────────────────────────────── │  │
│  │ │ 🚕 Price per Seat             ₹150                    │ │  │
│  │ ├──────────────────────────────────────────────────────── │  │
│  │ │ 💵 Total Price                ₹450  [Yellow Highlight]│ │  │
│  │ └─────────────────────────────────────────────────────────┘ │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ ✅ ACCEPT BOOKING (Green Button)                             │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ ❌ REJECT BOOKING (Red Button)                               │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                            ↓
                  (Driver Taps Accept)
                            ↓
┌─────────────────────────────────────────────────────────────────────┐
│                        PROCESS FLOW                                  │
│                                                                     │
│  ✅ BookingController.acceptBooking() called                       │
│     └─ Updates Firestore: booking.status = "accepted"             │
│                                                                     │
│  ✅ RideController.reduceAvailableSeats(3) called                  │
│     ├─ availableSeats: 5 → 2                                      │
│     └─ numberOfPassengersAllocated: 0 → 3                         │
│                                                                     │
│  ✅ Firestore rides collection updated                            │
│     ├─ availableSeats: 5 → 2                                      │
│     └─ bookedSeats: 0 → 3                                         │
│                                                                     │
│  ✅ UI rebuilds automatically (Obx)                               │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────────┐
│                      SUCCESS MESSAGE POPUP                           │
│                                                                     │
│  ════════════════════════════════════════════════════════════════   │
│                                                                     │
│                    ✅ BOOKING ACCEPTED!                            │
│                                                                     │
│       Seats allocated: 3                                            │
│       Available seats: 2                                            │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ CONTINUE                                                     │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    RIDE DETAILS UPDATED                             │
│                                                                     │
│  RIDE DETAILS                                                      │
│  ─────────────────────────────────────────────────────────────────  │
│                                                                     │
│  🪑 Total Seats            5                                       │
│                                                                     │
│  👥 Seats Allocated        3 ← Changed from 0                     │
│                                                                     │
│  🛫 Available Seats        2 ← Changed from 5 ⭐ In Real-Time      │
│                                                                     │
│  (Other ride details...)                                           │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Component Hierarchy

```
RideInProgressScreen
│
├─ Scaffold
│  │
│  ├─ AppBar
│  │  └─ Actions: [Cancel Ride X]
│  │
│  └─ Body: SingleChildScrollView
│     └─ Column
│        │
│        ├─ Current Location Card
│        │  ├─ Icon: location_on (Yellow)
│        │  ├─ Label: "Start Location"
│        │  ├─ Address: "Central Station"
│        │  └─ Coordinates: Lat/Long
│        │
│        ├─ Destination Card
│        │  ├─ Icon: location_on
│        │  ├─ Label: "Destination"
│        │  └─ Address: "Downtown Plaza"
│        │
│        ├─ [IF destination NOT set]
│        │  ├─ Title: "Set Destination"
│        │  ├─ Info Card: "Enter coordinates"
│        │  ├─ TextFields: Latitude, Longitude
│        │  └─ Button: "Set Destination"
│        │
│        └─ [IF destination IS set]
│           │
│           ├─ Title: "RIDE DETAILS" ⭐
│           │
│           ├─ DetailCard: Total Seats [NEW]
│           │  ├─ Icon: event_seat
│           │  └─ Value: 5
│           │
│           ├─ DetailCard: Seats Allocated [NEW]
│           │  ├─ Icon: person
│           │  └─ Value: 3 ← Updates
│           │
│           ├─ DetailCard: Available Seats [NEW] ⭐
│           │  ├─ Icon: airline_seat_flat_angled
│           │  └─ Value: 2 ← Updates in Real-Time
│           │
│           ├─ DetailCard: Distance
│           │  ├─ Icon: straighten
│           │  └─ Value: 12.45 km
│           │
│           ├─ DetailCard: Passengers
│           │  ├─ Icon: people
│           │  └─ Value: 5
│           │
│           ├─ PriceCard: Pricing Details
│           │  ├─ Base Price: ₹500
│           │  └─ Total Price: ₹2,500
│           │
│           ├─ Button: "View Route on Map"
│           │
│           ├─ Button: "Complete Ride"
│           │
│           └─ Button: "🧪 TEST: Show Booking Popup" [NEW]
│
└─ showModalBottomSheet [For Popups]
   ├─ BookingNotificationPopup ⭐ [NEW WIDGET]
   │  ├─ Booking Details Card
   │  ├─ Buttons: Accept | Reject
   │  └─ Reactive Loading State
   │
   └─ Action Menu [Success/Feedback]
      ├─ Success Icon
      ├─ Title & Message
      └─ Button: Continue
```

## State Changes Visualization

```
INITIAL STATE (When Ride Starts)
┌──────────────────────────────┐
│ numberOfPassengers = 5       │
│ numberOfPassengersAllocated = 0
│ availableSeats = 5           │
└──────────────────────────────┘

AFTER 1st BOOKING ACCEPTED (3 seats)
┌──────────────────────────────┐
│ numberOfPassengers = 5       │
│ numberOfPassengersAllocated = 3 ← +3
│ availableSeats = 2           │ ← -3
└──────────────────────────────┘

AFTER 2nd BOOKING ACCEPTED (2 seats)
┌──────────────────────────────┐
│ numberOfPassengers = 5       │
│ numberOfPassengersAllocated = 5 ← +2
│ availableSeats = 0           │ ← -2 (FULL!)
└──────────────────────────────┘

No more bookings can be accepted when availableSeats = 0
```

## Color Scheme

```
🟡 Primary Yellow (AppColors.primaryYellow)
   ├─ Accent for important elements
   ├─ Accept buttons
   └─ Highlighted values (Total Price)

🟢 Success Green (AppColors.successGreen)
   ├─ Accept button
   ├─ Positive actions
   └─ Seats booked value (3)

🔴 Error Red (AppColors.errorRed)
   ├─ Reject button
   └─ Negative actions

⚫ Primary Black (AppColors.primaryBlack)
   ├─ Main text
   └─ Labels

⚪ Light Gray (AppColors.lightGray)
   ├─ Card backgrounds
   └─ Container backgrounds
```

## Interactive Elements

```
┌─ Buttons ─────────────────────────┐
│                                    │
│ Accept Booking Button              │
│  ├─ Color: Green                   │
│  ├─ Icon: check_circle             │
│  ├─ State: Normal/Loading/Disabled │
│  └─ Action: Accept & Reduce Seats  │
│                                    │
│ Reject Booking Button              │
│  ├─ Color: Red                     │
│  ├─ Icon: cancel                   │
│  ├─ State: Normal/Loading/Disabled │
│  └─ Action: Reject Booking         │
│                                    │
│ Test Popup Button                  │
│  ├─ Color: Orange                  │
│  ├─ Text: 🧪 TEST: Show Popup     │
│  └─ Action: Trigger Mock Booking   │
│                                    │
│ Complete Ride Button               │
│  ├─ Color: Yellow                  │
│  └─ Action: Finish Ride            │
│                                    │
└────────────────────────────────────┘
```

## Real-Time Update Flow

```
┌─────────────────────────────────────────────────────┐
│           Available Seats: 5                         │
│         (Displayed in DetailCard)                    │
│              (Inside Obx Widget)                     │
└─────────────────────────────────────────────────────┘
                      ↑
                      │ (Watches for changes)
                      │
┌─────────────────────────────────────────────────────┐
│   _rideController.availableSeats (RxInt)            │
│                                                      │
│   Value: 5 → 4 → 3 → 2 → 1 → 0                    │
│                                                      │
│   Triggers Obx rebuild when value changes           │
└─────────────────────────────────────────────────────┘
                      ↑
                      │ (Updates)
                      │
┌─────────────────────────────────────────────────────┐
│ reduceAvailableSeats(seatsBooked)                   │
│                                                      │
│ availableSeats.value -= seatsBooked                 │
│                                                      │
│ Called after booking accepted                       │
└─────────────────────────────────────────────────────┘
```

## Mobile Screen Layout

```
iPhone 12 (390x844) Example:

┌────────────────────────┐
│  Ride in Progress  [X] │ 40px
├────────────────────────┤
│ 📍 Start Location      │ 100px
│ Central Station        │
│ Lat/Long display      │
│                        │
├────────────────────────┤
│ 📍 Destination         │ 100px
│ Downtown Plaza        │
│                        │
├────────────────────────┤
│ RIDE DETAILS           │ 350px
│ ┌──────────────────┐   │
│ │ 🪑 Total: 5     │   │
│ │ 👥 Allocated: 3 │   │
│ │ 🛫 Available: 2 │   │
│ │ 📏 Distance... │   │
│ │ 💰 Pricing...  │   │
│ └──────────────────┘   │
│                        │
│ [Complete Ride] 60px   │
│ [TEST Button]   60px   │
│                        │
└────────────────────────┘
```

## Booking Popup Mobile View

```
iPhone 12 (390x844):

┌────────────────────────┐ ▲
│                        │ │
│  (Transparent Area)    │ │ Page below visible
│                        │ │
├────────────────────────┤ ◄─┐
│   📲 New Booking      │ │ │ Rounded Top Corners
│   ═══════════════════ │ │ │
│                       │ │ │
│   🪑 Seats Booked: 3 │ │ │
│   ───────────────    │ │ │ 350px
│   📍 Pickup: ...     │ │ │
│   ───────────────    │ │ │
│   📍 Dropoff: ...    │ │ │
│   ───────────────    │ │ │
│   💵 Total: ₹450    │ │ │
│                       │ │ │
│   [Accept] [Reject]   │ │ │
│                       │ ◄─┘
└────────────────────────┘ ▼
```

## Console Output Example

```
[RideInProgressScreen] 🚀 Screen initialized
[RideInProgressScreen] 👂 Starting booking listener...
...
[RideInProgressScreen] 🔔 Booking changed: booking_001
[RideInProgressScreen] 📲 Showing popup for: booking_001
[RideInProgressScreen] 🔴 Showing popup...
...
(User taps Accept)
...
[RideInProgressScreen] ✅ Booking accepted, reducing available seats
[RideController] 📉 Reducing available seats by 3
[RideController] Before: Available = 5, Allocated = 0
[RideController] After: Available = 2, Allocated = 3
[BookingService] ✅ Booking accepted: booking_001
[RideInProgressScreen] ===== SHOWING ACTION MENU =====
[RideInProgressScreen] Title: Booking Accepted!
[RideInProgressScreen] Message: Seats allocated: 3...
```
