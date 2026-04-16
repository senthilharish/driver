import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:driver/controllers/auth_controller.dart';
import 'package:driver/controllers/ride_controller.dart';
import 'package:driver/controllers/booking_controller.dart';
import 'package:driver/models/booking_model.dart';
import 'package:driver/utils/app_theme.dart';
import 'package:driver/widgets/custom_widgets.dart';
import 'package:driver/widgets/booking_notification_popup.dart';

class RideInProgressScreen extends StatefulWidget {
  const RideInProgressScreen({Key? key}) : super(key: key);

  @override
  State<RideInProgressScreen> createState() => _RideInProgressScreenState();
}

class _RideInProgressScreenState extends State<RideInProgressScreen> {
  final AuthController _authController = Get.find();
  final RideController _rideController = Get.find();
  final BookingController _bookingController = Get.put(BookingController());
  final _destinationLatController = TextEditingController();
  final _destinationLongController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('[RideInProgressScreen] 🚀 Screen initialized');
    
    // Start listening for bookings immediately
    _startBookingListener();
  }

  void _startBookingListener() {
    print('[RideInProgressScreen] 👂 Starting real-time booking listener...');
    
    // Get driver ID from auth controller
    final driverId = _authController.currentDriver.value?.uid ?? '';
    print('[RideInProgressScreen] 🆔 Driver ID: $driverId');
    
    if (driverId.isEmpty) {
      print('[RideInProgressScreen] ⚠️ Driver ID is empty, cannot start listener');
      return;
    }
    
    // Create controller
    final bookingController = Get.put(BookingController());
    
    // Start real-time listening to bookings
    bookingController.startListeningWithNotifications(driverId);
    
    // Watch for booking changes
    ever(bookingController.currentBooking, (booking) {
      print('[RideInProgressScreen] 🔔 Booking changed: ${booking?.bookingId}');
      
      if (booking != null && mounted) {
        print('[RideInProgressScreen] 📲 Showing popup for: ${booking.bookingId}');
        _showBookingPopup(booking, bookingController);
      }
    });
  }

  void _showBookingPopup(BookingModel booking, BookingController controller) {
    print('[RideInProgressScreen] 🔴 Showing popup...');
    
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Obx(
        () => BookingNotificationPopup(
          booking: booking,
          isLoading: controller.isLoading.value,
          onAccept: () async {
            final rideId = _rideController.currentRide.value?.rideId;
            if (rideId != null) {
              print('[RideInProgressScreen] ➡️ Accepting booking...');
              await controller.acceptBooking(rideId);
              
              // Reduce available seats after accepting
              print('[RideInProgressScreen] ✅ Booking accepted, reducing available seats');
              _rideController.reduceAvailableSeats(booking.seatsBooked);
              
              // Pop the booking popup
              if (mounted) {
                Navigator.of(bottomSheetContext).pop();
                print('[RideInProgressScreen] 🔔 Booking popup closed');
                
                // Show success message
                _showActionMenu(context, 'Booking Accepted!', 'Seats allocated: ${booking.seatsBooked}\nAvailable seats: ${_rideController.availableSeats.value}');
              }
            }
          },
          onReject: () async {
            print('[RideInProgressScreen] ➡️ Rejecting booking...');
            await controller.rejectBooking();
            
            // Pop the booking popup
            if (mounted) {
              Navigator.of(bottomSheetContext).pop();
              print('[RideInProgressScreen] 🔔 Booking popup closed');
              
              // Show rejection message
              _showActionMenu(context, 'Booking Rejected!', 'Passenger will be notified');
            }
          },
        ),
      ),
    );
  }

  void _showActionMenu(BuildContext context, String title, String message) {
    print('[RideInProgressScreen] ===== SHOWING ACTION MENU =====');
    print('[RideInProgressScreen] Title: $title');
    print('[RideInProgressScreen] Message: $message');
    
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.lg),
            topRight: Radius.circular(AppRadius.lg),
          ),
        ),
        padding: const EdgeInsets.all(AppPadding.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle indicator
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.mediumGray,
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.only(bottom: AppPadding.lg),
            ),
            
            // Success icon
            Container(
              padding: const EdgeInsets.all(AppPadding.lg),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.successGreen,
                size: 50,
              ),
            ),
            const SizedBox(height: AppPadding.lg),
            
            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlack,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppPadding.md),
            
            // Message
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppPadding.xl),
            
            // Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  print('[RideInProgressScreen] Action menu closed, ready for next booking');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: AppColors.primaryBlack,
                  padding: const EdgeInsets.symmetric(vertical: AppPadding.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _destinationLatController.dispose();
    _destinationLongController.dispose();
    super.dispose();
  }

  void _handleSetDestination() async {
    if (_destinationLatController.text.isEmpty || _destinationLongController.text.isEmpty) {
      _showErrorDialog('Error', 'Please enter both destination latitude and longitude');
      return;
    }

    double? lat = double.tryParse(_destinationLatController.text);
    double? long = double.tryParse(_destinationLongController.text);

    if (lat == null || long == null) {
      _showErrorDialog('Error', 'Invalid coordinates. Please enter valid numbers');
      return;
    }

    bool success = await _rideController.setDestination(
      latitude: lat,
      longitude: long,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Destination set successfully'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } else {
      _showErrorDialog('Error', _rideController.errorMessage.value);
    }
  }

  void _handleCompleteRide() async {
    bool success = await _rideController.completeRide();

    if (success) {
      _showSuccessDialog(
        'Ride Completed',
        'Your ride has been completed successfully!',
        () {
          Navigator.pop(context);
          Get.offNamed('/home');
        },
      );
    } else {
      _showErrorDialog('Error', _rideController.errorMessage.value);
    }
  }

  void _handleCancelRide() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Cancel Ride?'),
        content: const Text('Are you sure you want to cancel this ride?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Keep Ride',
              style: TextStyle(color: AppColors.primaryBlack),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              bool success = await _rideController.cancelRide();

              if (success) {
                Get.offNamed('/home');
              } else {
                _showErrorDialog('Error', _rideController.errorMessage.value);
              }
            },
            child: const Text(
              'Cancel Ride',
              style: TextStyle(
                color: AppColors.errorRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => CustomErrorDialog(
        title: title,
        message: message,
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  void _showSuccessDialog(String title, String message, VoidCallback onDismiss) {
    showDialog(
      context: context,
      builder: (context) => CustomSuccessDialog(
        title: title,
        message: message,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ride in Progress'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: _handleCancelRide,
              icon: const Icon(Icons.close),
              tooltip: 'Cancel Ride',
            ),
          ],
        ),
        body: Obx(
          () => SingleChildScrollView(
            padding: const EdgeInsets.all(AppPadding.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Location Card with Coordinates
                Container(
                  padding: const EdgeInsets.all(AppPadding.md),
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.primaryYellow, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppPadding.md),
                            decoration: BoxDecoration(
                              color: AppColors.primaryYellow.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: AppColors.primaryYellow,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppPadding.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start Location',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.mediumGray,
                                      ),
                                ),
                                const SizedBox(height: AppPadding.xs),
                                Text(
                                  _rideController.startAddress.value,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppPadding.sm),
                                // Display current coordinates from driver model
                                if (_authController.currentDriver.value?.latitude != null &&
                                    _authController.currentDriver.value?.longitude != null)
                                  Container(
                                    padding: const EdgeInsets.all(AppPadding.sm),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryYellow.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                    ),
                                    child: Text(
                                      'Lat: ${_authController.currentDriver.value!.latitude?.toStringAsFixed(4)}, '
                                      'Long: ${_authController.currentDriver.value!.longitude?.toStringAsFixed(4)}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppColors.primaryBlack,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppPadding.md),

                // Destination Card
                Container(
                  padding: const EdgeInsets.all(AppPadding.md),
                  decoration: BoxDecoration(
                    color: _rideController.destinationAddress.value == 'Not set'
                        ? AppColors.lightGray.withOpacity(0.5)
                        : AppColors.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: _rideController.destinationAddress.value == 'Not set'
                          ? AppColors.mediumGray
                          : AppColors.successGreen,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppPadding.md),
                            decoration: BoxDecoration(
                              color: _rideController.destinationAddress.value == 'Not set'
                                  ? AppColors.mediumGray.withOpacity(0.2)
                                  : AppColors.successGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: _rideController.destinationAddress.value == 'Not set'
                                  ? AppColors.mediumGray
                                  : AppColors.successGreen,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppPadding.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Destination',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.mediumGray,
                                      ),
                                ),
                                const SizedBox(height: AppPadding.xs),
                                Text(
                                  _rideController.destinationAddress.value,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppPadding.xl),

                // Destination Coordinates Input
                if (_rideController.destinationAddress.value == 'Not set') ...[
                  Text(
                    'Set Destination',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppPadding.md),
                  
                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(AppPadding.md),
                    decoration: BoxDecoration(
                      color: AppColors.infoBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.infoBlue, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.infoBlue,
                        ),
                        const SizedBox(width: AppPadding.md),
                        Expanded(
                          child: Text(
                            'Enter destination coordinates (latitude, longitude)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppPadding.md),
                  
                  // Destination Latitude
                  TextFormField(
                    controller: _destinationLatController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(
                      labelText: 'Destination Latitude',
                      hintText: 'e.g., 28.5355',
                      prefixIcon: const Icon(
                        Icons.map,
                        color: AppColors.primaryYellow,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppPadding.md),
                  
                  // Destination Longitude
                  TextFormField(
                    controller: _destinationLongController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(
                      labelText: 'Destination Longitude',
                      hintText: 'e.g., 77.3910',
                      prefixIcon: const Icon(
                        Icons.map,
                        color: AppColors.primaryYellow,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppPadding.lg),
                  
                  CustomButton(
                    label: _rideController.isLoading.value
                        ? 'Setting...'
                        : 'Set Destination',
                    onPressed: _handleSetDestination,
                    isLoading: _rideController.isLoading.value,
                    isEnabled: !_rideController.isLoading.value,
                  ),
                  const SizedBox(height: AppPadding.xl),
                ] else ...[
                  // Ride Details
                  Text(
                    'Ride Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppPadding.md),
                  _buildDetailCard(
                    context,
                    icon: Icons.event_seat,
                    label: 'Total Seats',
                    value: '${_rideController.numberOfPassengers.value}',
                  ),
                  const SizedBox(height: AppPadding.md),
                  _buildDetailCard(
                    context,
                    icon: Icons.person,
                    label: 'Seats Allocated',
                    value: '${_rideController.numberOfPassengersAllocated.value}',
                  ),
                  const SizedBox(height: AppPadding.md),
                  _buildDetailCard(
                    context,
                    icon: Icons.airline_seat_flat_angled,
                    label: 'Available Seats',
                    value: '${_rideController.availableSeats.value}',
                  ),
                  const SizedBox(height: AppPadding.md),
                  _buildDetailCard(
                    context,
                    icon: Icons.straighten,
                    label: 'Distance',
                    value:
                        '${_rideController.currentDistance.value.toStringAsFixed(2)} km',
                  ),
                  const SizedBox(height: AppPadding.md),
                  _buildDetailCard(
                    context,
                    icon: Icons.people,
                    label: 'Passengers',
                    value: '${_rideController.numberOfPassengers.value}',
                  ),
                  const SizedBox(height: AppPadding.md),
                  Container(
                    padding: const EdgeInsets.all(AppPadding.md),
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.primaryYellow, width: 1),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Base Price:',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '₹${_rideController.basePrice.value.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppPadding.sm),
                        const Divider(),
                        const SizedBox(height: AppPadding.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Price:',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '₹${_rideController.totalPrice.value.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.primaryYellow,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppPadding.xl),
                  
                  // View Route Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.toNamed('/ride-route-map');
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('View Route on Map'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryYellow,
                        foregroundColor: AppColors.primaryBlack,
                        padding: const EdgeInsets.symmetric(vertical: AppPadding.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppPadding.xl),
                  
                  CustomButton(
                    label: _rideController.isLoading.value
                        ? 'Completing...'
                        : 'Complete Ride',
                    onPressed: _handleCompleteRide,
                    isLoading: _rideController.isLoading.value,
                    isEnabled: !_rideController.isLoading.value,
                  ),
                  const SizedBox(height: AppPadding.md),
                  
                  // DEBUG: Test Popup Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        print('[DEBUG] Test button pressed - triggering popup');
                        _bookingController.testBookingPopup();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: AppPadding.md),
                      ),
                      child: const Text('🧪 TEST: Show Booking Popup'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.md),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppPadding.md),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: AppColors.primaryYellow),
          ),
          const SizedBox(width: AppPadding.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mediumGray,
                      ),
                ),
                const SizedBox(height: AppPadding.xs),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
