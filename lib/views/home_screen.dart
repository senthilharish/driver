import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:driver/controllers/auth_controller.dart';
import 'package:driver/utils/app_theme.dart';
import 'package:driver/widgets/custom_widgets.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthController _authController = Get.find();
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _startClock();
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
