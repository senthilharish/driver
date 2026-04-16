import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:driver/controllers/auth_controller.dart';
import 'package:driver/controllers/booking_controller.dart';
import 'package:driver/models/booking_model.dart';
import 'package:driver/utils/app_theme.dart';
import 'package:driver/widgets/custom_widgets.dart';
import 'package:driver/widgets/booking_notification_popup.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthController _authController = Get.find();
  final BookingController _bookingController = Get.find();
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _startClock();
    _setupBookingListener();
  }

  void _setupBookingListener() {
    // Start real-time listening for bookings when home screen is loaded
    final driverId = _authController.currentDriver.value?.uid ?? '';
    if (driverId.isNotEmpty) {
      print('[HomeScreen] 🔌 Setting up real-time booking listener');
      print('[HomeScreen] 🆔 Driver ID: $driverId');
      
      // Use real-time listener instead of polling
      _bookingController.startListeningWithNotifications(driverId);
      
      // Watch for new bookings and show popup
      ever(_bookingController.currentBooking, (booking) {
        if (booking != null && mounted) {
          print('[HomeScreen] 📲 New booking received, showing popup');
          _showBookingPopup(booking);
        }
      });
    } else {
      print('[HomeScreen] ⚠️ Driver ID is empty, cannot start listener');
    }
  }

  @override
  void dispose() {
    print('[HomeScreen] 🛑 Disposing home screen');
    // Listener will continue - no need to stop it here
    // (It's tied to the BookingController lifecycle)
    super.dispose();
  }

  void _showBookingPopup(BookingModel booking) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Obx(
        () => BookingNotificationPopup(
          booking: booking,
          isLoading: _bookingController.isLoading.value,
          onAccept: () async {
            await _bookingController.acceptBooking('');
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking accepted! Ride started.'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          onReject: () async {
            await _bookingController.rejectBooking();
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking declined.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void _startClock() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
        _startClock();
      }
    });
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.primaryBlack),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _authController.logout();
              Get.offNamed('/login');
            },
            child: const Text(
              'Logout',
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

  void _handleUpdateLocation() async {
    showDialog(
      context: context,
      builder: (context) => const CustomLoadingDialog(
        message: 'Updating location...',
      ),
    );

    await _authController.updateLocation();
    Navigator.pop(context);

    if (_authController.errorMessage.value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location updated successfully'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_authController.errorMessage.value),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  String _getGreeting() {
    final hour = _currentTime.hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Obx(
        () {
          if (_authController.currentDriver.value == null) {
            return Center(
              child: Text(
                'Loading...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          }

          final driver = _authController.currentDriver.value!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppPadding.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppPadding.lg),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.primaryBlack,
                            ),
                      ),
                      const SizedBox(height: AppPadding.sm),
                      Text(
                        driver.drivername,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: AppColors.primaryBlack,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppPadding.xl),

                // Start Ride Button
                CustomButton(
                  label: 'Start New Ride',
                  onPressed: () => Get.toNamed('/start-ride'),
                  height: 60,
                ),
                const SizedBox(height: AppPadding.xl),

                // Polling Status Card
                Obx(
                  () => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppPadding.md),
                    decoration: BoxDecoration(
                      color: _bookingController.pollingActive.value
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: _bookingController.pollingActive.value
                            ? Colors.green
                            : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppPadding.md),
                          decoration: BoxDecoration(
                            color: _bookingController.pollingActive.value
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: _bookingController.pollingActive.value
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.green),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.sync_disabled,
                                  color: Colors.red,
                                ),
                        ),
                        const SizedBox(width: AppPadding.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Booking Polling Status',
                                style:
                                    Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.mediumGray,
                                        ),
                              ),
                              const SizedBox(height: AppPadding.xs),
                              Text(
                                _bookingController.pollingActive.value
                                    ? '🟢 Active - Checking every 5 seconds'
                                    : '🔴 Inactive',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: _bookingController.pollingActive.value
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              if (_bookingController.lastPolledTime.value.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Last polled: ${_bookingController.lastPolledTime.value.substring(11, 19)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppPadding.xl),

                // Driver Information Cards
                Text(
                  'Driver Information',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppPadding.md),

                // Phone Number Card
                _buildInfoCard(
                  context,
                  icon: Icons.phone,
                  label: 'Phone Number',
                  value: driver.phone,
                ),
                const SizedBox(height: AppPadding.md),

                // Email Card
                _buildInfoCard(
                  context,
                  icon: Icons.email,
                  label: 'Email',
                  value: driver.email,
                ),
                const SizedBox(height: AppPadding.md),

                // Location Card
                _buildInfoCard(
                  context,
                  icon: Icons.location_on,
                  label: 'Location',
                  value: driver.latitude != null && driver.longitude != null
                      ? '${driver.latitude!.toStringAsFixed(4)}, ${driver.longitude!.toStringAsFixed(4)}'
                      : 'No location data',
                ),
                const SizedBox(height: AppPadding.xl),

                // Location Update Button
                CustomButton(
                  label: 'Update Location',
                  onPressed: _handleUpdateLocation,
                ),
                const SizedBox(height: AppPadding.md),

                // Join Date Card
                Container(
                  width: double.infinity,
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
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Icon(
                          Icons.calendar_today,
                          color: AppColors.primaryYellow,
                        ),
                      ),
                      const SizedBox(width: AppPadding.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Member Since',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.mediumGray,
                              ),
                            ),
                            const SizedBox(height: AppPadding.xs),
                            Text(
                              DateFormat('MMM dd, yyyy').format(driver.createdAt),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppPadding.xl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(
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
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryYellow,
            ),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
