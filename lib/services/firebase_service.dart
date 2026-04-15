import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/models/driver_model.dart';
import 'package:driver/utils/validators.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize Firebase (call this in main)
  Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      throw Exception('Failed to initialize Firebase: $e');
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with phone number and password
  Future<DriverModel> signUpWithPhone({
    required String username,
    required String phoneNumber,
    required String password,
    required double? latitude,
    required double? longitude,
  }) async {
    try {
      // Convert phone to email
      String email = Validators.phoneToEmail(phoneNumber);

      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User user = userCredential.user!;

      // Create driver model
      DriverModel driver = DriverModel(
        uid: user.uid,
        drivername: username,
        phone: phoneNumber,
        email: email,
        password: password,
        latitude: latitude,
        longitude: longitude,
        createdAt: DateTime.now(),
      );

      // Store in Firestore
      await _firestore.collection('driver').doc(user.uid).set(driver.toJson());

      return driver;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Login with phone number and password
  Future<DriverModel> loginWithPhone({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      // Convert phone to email
      String email = Validators.phoneToEmail(phoneNumber);

      // Sign in with email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User user = userCredential.user!;

      // Fetch driver data from Firestore
      DocumentSnapshot doc = await _firestore.collection('driver').doc(user.uid).get();

      if (!doc.exists) {
        throw Exception('Driver profile not found');
      }

      return DriverModel.fromJson(doc.data() as Map<String, dynamic>);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Fetch driver data
  Future<DriverModel> getDriverData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('driver').doc(uid).get();

      if (!doc.exists) {
        throw Exception('Driver profile not found');
      }

      return DriverModel.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch driver data: $e');
    }
  }

  // Get driver data stream
  Stream<DriverModel> getDriverDataStream(String uid) {
    return _firestore.collection('driver').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        throw Exception('Driver profile not found');
      }
      return DriverModel.fromJson(snapshot.data() as Map<String, dynamic>);
    });
  }

  // Update driver location
  Future<void> updateDriverLocation(String uid, double latitude, double longitude) async {
    try {
      await _firestore.collection('driver').doc(uid).update({
        'latitude': latitude,
        'longitude': longitude,
      });
    } catch (e) {
      throw Exception('Failed to update location: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'email-already-in-use':
        return 'This phone number is already registered.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'user-not-found':
        return 'No account found with this phone number.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Invalid phone number or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}
