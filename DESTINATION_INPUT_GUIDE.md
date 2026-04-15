# Ride Destination Input - Implementation Guide

## Current Implementation

The app is set up to manually collect destination coordinates from the user.

### Flow:

1. **User starts a ride** → `StartRideScreen`
   - Current location is captured automatically
   - Current location is stored in Firestore under the `driver` collection

2. **User goes to ride in progress** → `RideInProgressScreen`
   - Current location from driver model is displayed (Lat/Long from signup)
   - User manually enters **destination latitude** and **longitude**
   - User taps "Set Destination" button

3. **Data sent to database** → `RideController` & `RideDatabaseService`
   - `destinationLatitude`: User entered value
   - `destinationLongitude`: User entered value
   - `destinationAddress`: Auto-generated from coordinates using geocoding
   - Price is calculated based on distance

---

## How Manual Destination Input Works

### Step 1: Ride In Progress Screen
**File**: `lib/views/ride_in_progress_screen.dart`

```dart
// Current location display (from driver model)
if (_authController.currentDriver.value?.latitude != null &&
    _authController.currentDriver.value?.longitude != null)
  Container(
    child: Text(
      'Lat: ${_authController.currentDriver.value!.latitude?.toStringAsFixed(4)}, '
      'Long: ${_authController.currentDriver.value!.longitude?.toStringAsFixed(4)}',
    ),
  ),

// User input fields for destination
TextFormField(
  controller: _destinationLatController,
  decoration: InputDecoration(
    labelText: 'Destination Latitude',
    hintText: 'e.g., 28.5355',
  ),
),

TextFormField(
  controller: _destinationLongController,
  decoration: InputDecoration(
    labelText: 'Destination Longitude',
    hintText: 'e.g., 77.3910',
  ),
),
```

### Step 2: Validation
```dart
void _handleSetDestination() async {
  // Check if fields are not empty
  if (_destinationLatController.text.isEmpty || 
      _destinationLongController.text.isEmpty) {
    _showErrorDialog('Error', 'Please enter both destination latitude and longitude');
    return;
  }

  // Parse the input
  double? lat = double.tryParse(_destinationLatController.text);
  double? long = double.tryParse(_destinationLongController.text);

  // Validate numeric values
  if (lat == null || long == null) {
    _showErrorDialog('Error', 'Invalid coordinates. Please enter valid numbers');
    return;
  }

  // Call controller to set destination
  bool success = await _rideController.setDestination(
    latitude: lat,
    longitude: long,
  );
}
```

### Step 3: Process in Ride Controller
**File**: `lib/controllers/ride_controller.dart`

```dart
Future<bool> setDestination({
  required double latitude,
  required double longitude,
}) async {
  // Get address from coordinates using geocoding
  List<Placemark> placemarks = await placemarkFromCoordinates(
    latitude, 
    longitude
  );

  String address = 'Unknown Location';
  if (placemarks.isNotEmpty) {
    final place = placemarks[0];
    address = '${place.street}, ${place.locality}, ${place.postalCode}';
  }

  destinationAddress.value = address;

  // Update ride with destination coordinates
  await _rideManagementService.setDestination(
    destinationLatitude: latitude,
    destinationLongitude: longitude,
    destinationAddress: address,
  );

  // Calculate distance and price
  double distance = _rideManagementService.calculateDistance(
    currentRide.value!.startLatitude,
    currentRide.value!.startLongitude,
    latitude,
    longitude,
  );

  double price = _rideManagementService.calculateRidePrice(
    basePrice: basePrice.value,
    distance: distance,
    numberOfPassengers: numberOfPassengers.value,
  );

  // Update UI
  currentDistance.value = distance;
  totalPrice.value = price;

  // Save to database
  await _rideDatabaseService.updateRide(currentRide.value!);
}
```

### Step 4: Data Saved to Firestore
**Collection**: `rides`
**Document**: `{rideId}`

```json
{
  "rideId": "12345-67890",
  "driverId": "driver-uid",
  "startLatitude": 28.6139,
  "startLongitude": 77.2090,
  "startAddress": "Street, City, Postal Code",
  "destinationLatitude": 28.5355,     // ← User entered
  "destinationLongitude": 77.3910,    // ← User entered
  "destinationAddress": "Destination address from geocoding",
  "numberOfPassengers": 2,
  "basePrice": 100.0,
  "totalPrice": 145.5,
  "status": "inProgress",
  "rideDistance": 3.5,
  "createdAt": "2024-01-15T10:30:00.000Z"
}
```

---

## Testing the Manual Input

### Example Coordinates for Testing:

**Start Location (Delhi):**
- Latitude: 28.6139
- Longitude: 77.2090

**Destination Location (Delhi):**
- Latitude: 28.5355
- Longitude: 77.3910

**Distance**: ~8 km

---

## Data Model Fields

### RideModel (ride_model.dart)

```dart
final double? destinationLatitude;    // Manually entered by user
final double? destinationLongitude;   // Manually entered by user
final String? destinationAddress;     // Auto-generated from coordinates
```

---

## Features Implemented

✅ **Current Location Display** (from driver model)
- Automatically fetched during signup
- Displayed when ride starts
- Shows latitude and longitude

✅ **Manual Destination Input**
- User enters destination coordinates
- Input validation (numeric values required)
- Error handling for invalid input

✅ **Automatic Address Generation**
- Geocoding converts lat/long to address
- Address displayed in UI
- Saved to Firestore

✅ **Dynamic Price Calculation**
- Based on distance between start and destination
- Considers number of passengers
- Updates in real-time

✅ **Database Storage**
- All ride data saved to Firestore
- Coordinates stored as separate fields
- Easy to query by location

---

## How to Use in Your App

1. User starts a ride on `StartRideScreen`
2. Navigate to `RideInProgressScreen`
3. Current location shown (from driver model)
4. User manually enters destination coordinates
5. Tap "Set Destination"
6. Address is auto-generated and distance calculated
7. Tap "Complete Ride" to finish
8. Data is saved to Firestore

---

## Important Notes

- **destinationLatitude** and **destinationLongitude** are **optional** fields (nullable)
- They become required once ride starts and user sets destination
- If user cancels ride without setting destination, they are null
- Geocoding requires internet connection
- Coordinates must be valid decimal numbers (e.g., 28.5355, 77.3910)
