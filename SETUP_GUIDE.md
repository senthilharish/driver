# Driver App - Flutter Application

A modern Flutter driver application built with Firebase Authentication, Cloud Firestore, and geolocation services. Features a clean, minimal UI inspired by the Rapido app with yellow/black theme.

## 📱 Features

### Authentication & User Management
- ✅ Phone number-based registration (converted to email format: phone@driver.com)
- ✅ Secure password authentication
- ✅ User profile management
- ✅ Location tracking (optional during signup)
- ✅ Firestore data persistence

### Ride Management
- ✅ Start new rides with location capture
- ✅ Set ride destinations with geolocation
- ✅ Dynamic pricing calculation
  - Base price
  - Distance-based charges (₹15 per km)
  - Passenger-based charges (₹10 per additional passenger)
- ✅ Real-time ride tracking
- ✅ Ride completion and cancellation
- ✅ Ride history

### UI/UX Design
- 🎨 Clean, minimal interface with Rapido-style design
- 🎨 Yellow/Black bold color scheme
- 🎨 Rounded components and smooth transitions
- 🎨 Loading indicators and error handling
- 🎨 Form validation with helpful error messages
- 🎨 Password visibility toggle

## 🏗️ Architecture

The app follows the **MVC Pattern** with clear separation of concerns:

```
lib/
├── models/              # Data models
│   ├── driver_model.dart
│   └── ride_model.dart
├── views/               # UI screens
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── home_screen.dart
│   ├── start_ride_screen.dart
│   └── ride_in_progress_screen.dart
├── controllers/         # Business logic (GetX controllers)
│   ├── auth_controller.dart
│   └── ride_controller.dart
├── services/            # Firebase & location services
│   ├── firebase_service.dart
│   ├── ride_management_service.dart
│   ├── ride_database_service.dart
│   └── location_service.dart
├── utils/               # Theme, validators, constants
│   ├── app_theme.dart
│   └── validators.dart
├── widgets/             # Reusable UI components
│   └── custom_widgets.dart
└── main.dart            # App entry point
```

## 🔧 Technologies Used

- **Flutter**: Cross-platform mobile framework
- **Firebase**: 
  - Firebase Auth: Phone-based authentication
  - Cloud Firestore: Database
- **GetX**: State management and routing
- **Geolocator**: Location services
- **Geocoding**: Address conversion
- **UUID**: Unique ID generation
- **Intl**: Date formatting

## 📦 Installation & Setup

### Prerequisites
- Flutter SDK (version 3.6.1+)
- Firebase account
- Android Studio or VS Code with Flutter extension

### 1. Clone the Repository

```bash
git clone <repository-url>
cd driver
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Setup

#### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: "Driver" (or your preferred name)
4. Enable Google Analytics (optional)
5. Create the project

#### Step 2: Add Android App

1. In Firebase Console, click "Add app" → "Android"
2. Enter package name: `com.example.driver`
3. Download `google-services.json`
4. Place it in `android/app/google-services.json`

#### Step 3: Add iOS App

1. In Firebase Console, click "Add app" → "iOS"
2. Enter bundle ID: `com.example.driver`
3. Download `GoogleService-Info.plist`
4. Add to iOS project using Xcode

#### Step 4: Enable Authentication

1. Go to Firebase Console → Authentication
2. Click "Set up sign-in method"
3. Enable **Email/Password** authentication

#### Step 5: Create Firestore Database

1. Go to Firebase Console → Firestore Database
2. Click "Create database"
3. Start in **test mode** (for development)
4. Choose your preferred region
5. Click "Create"

#### Step 6: Firestore Security Rules (for testing)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 4. Android Permissions

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

### 5. iOS Permissions

Add to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to your location for ride tracking</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs access to your location for ride tracking</string>
```

## 🚀 Running the App

### Development Build
```bash
flutter run
```

### Android Release Build
```bash
flutter build apk --release
```

### iOS Release Build
```bash
flutter build ios --release
```

## 📱 App Usage

### 1. Authentication Flow

**Login:**
1. Open app → Login screen appears
2. Enter 10-digit phone number (e.g., 9876543210)
3. Enter password
4. Tap "Login"
5. Automatically redirected to Home screen

**Signup:**
1. Tap "Sign Up" on Login screen
2. Enter full name
3. Enter 10-digit phone number
4. Enter password (minimum 6 characters)
5. Location permissions are requested
6. Current location captured (optional)
7. User profile stored in Firestore
8. Redirected to Home screen

### 2. Starting a Ride

1. From Home screen, tap "Start New Ride"
2. Enter number of passengers (1-4 seats)
3. Enter base price in rupees
4. Review pricing estimate
5. Tap "Start Ride"
6. Current location captured automatically
7. Redirected to "Ride in Progress" screen

### 3. Setting Destination

1. On "Ride in Progress" screen
2. Enter destination coordinates:
   - Latitude (e.g., 28.6139)
   - Longitude (e.g., 77.2090)
3. Tap "Set Destination"
4. App calculates:
   - Distance to destination
   - Dynamic pricing based on distance and passengers
5. View price breakdown
6. Tap "Complete Ride" to finish

## 📊 Firestore Collections

### Collection: `driver`
Document ID: `{uid}`

Fields:
```json
{
  "uid": "user-firebase-uid",
  "drivername": "Driver Name",
  "phone": "9876543210",
  "email": "9876543210@driver.com",
  "password": "hashed-password",
  "latitude": 28.6139,
  "longitude": 77.2090,
  "createdAt": "2024-01-15T10:30:00.000Z"
}
```

### Collection: `rides`
Document ID: `{rideId}`

Fields:
```json
{
  "rideId": "unique-ride-id",
  "driverId": "driver-uid",
  "startLatitude": 28.6139,
  "startLongitude": 77.2090,
  "startAddress": "Address string",
  "destinationLatitude": 28.5355,
  "destinationLongitude": 77.3910,
  "destinationAddress": "Destination address string",
  "numberOfPassengers": 2,
  "basePrice": 100.0,
  "additionalPrice": 45.5,
  "totalPrice": 145.5,
  "status": "completed", // started, inProgress, completed, cancelled
  "createdAt": "2024-01-15T10:30:00.000Z",
  "startedAt": "2024-01-15T10:30:00.000Z",
  "completedAt": "2024-01-15T10:45:00.000Z",
  "rideDistance": 3.5,
  "rideDuration": 900
}
```

## 🎨 Color Scheme

- **Primary Yellow**: `#FFD700` (Gold/Yellow)
- **Primary Black**: `#1A1A1A` (Deep Black)
- **Accent Yellow**: `#FFC107` (Amber)
- **Error Red**: `#E53935`
- **Success Green**: `#4CAF50`
- **Info Blue**: `#1976D2`

## 📝 Key Classes & Methods

### AuthController
```dart
Future<bool> signUp({
  required String username,
  required String phoneNumber,
  required String password,
})

Future<bool> login({
  required String phoneNumber,
  required String password,
})

Future<void> logout()

Future<void> updateLocation()
```

### RideController
```dart
Future<bool> startRide({
  required String driverId,
  required int passengers,
  required double basePrice,
})

Future<bool> setDestination({
  required double latitude,
  required double longitude,
})

Future<bool> completeRide()

Future<bool> cancelRide()
```

### RideManagementService
```dart
double calculateDistance(
  double lat1, double lon1, double lat2, double lon2
)

double calculateRidePrice({
  required double basePrice,
  required double distance,
  required int numberOfPassengers,
})

Map<String, dynamic> getRideSummary()
```

## 🔐 Security Notes

### For Production
1. Change Firestore rules to strict access control
2. Implement proper password hashing on backend
3. Never store passwords in Firestore (use Firebase Auth)
4. Use environment variables for sensitive data
5. Implement rate limiting for authentication
6. Add SSL/TLS certificates
7. Implement input validation and sanitization
8. Use Firebase Security Rules properly

### Recommended Firestore Rules (Production)
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /driver/{uid} {
      allow read, write: if request.auth.uid == uid;
    }
    match /rides/{rideId} {
      allow read, write: if request.auth.uid == resource.data.driverId;
    }
  }
}
```

## 🐛 Troubleshooting

### Location Permission Issues
- Ensure permissions are granted in Android/iOS settings
- Check `AndroidManifest.xml` and `Info.plist`
- Restart app after granting permissions

### Firebase Authentication Errors
- Verify `google-services.json` is in correct location
- Check Firebase project ID matches
- Ensure Email/Password auth is enabled
- Verify Firestore database is created

### Build Errors
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Firestore Connection Issues
- Check internet connection
- Verify Firestore database rules
- Check Firebase credentials
- Ensure project is not on Spark plan (free tier has limitations)

## 📈 Future Enhancements

- 🗺️ Google Maps integration for visual route tracking
- 📍 Real-time location updates with streaming
- 💬 In-app messaging system
- ⭐ Rating and review system
- 💳 Payment integration
- 📊 Driver analytics dashboard
- 🔔 Push notifications
- 🎯 Ride history with detailed analytics
- 🌙 Dark mode support
- 🌐 Multi-language support

## 📄 License

This project is proprietary and confidential.

## 👨‍💻 Support

For issues or questions, please contact: [your-email@example.com]

## 🙏 Acknowledgments

- Design inspired by Rapido app
- Built with Flutter and Firebase
- State management with GetX

---

**Last Updated**: April 2026
**Flutter Version**: 3.6.1+
**Dart Version**: 3.6.1+
