import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:driver/controllers/auth_controller.dart';
import 'package:driver/controllers/ride_controller.dart';
import 'package:driver/utils/app_theme.dart';
import 'package:driver/widgets/custom_widgets.dart';

class StartRideScreen extends StatefulWidget {
  const StartRideScreen({Key? key}) : super(key: key);

  @override
  State<StartRideScreen> createState() => _StartRideScreenState();
}

class _StartRideScreenState extends State<StartRideScreen> {
  final AuthController _authController = Get.find();
  final RideController _rideController = Get.put(RideController());
  final RxInt _selectedPassengers = 1.obs;
  final _basePriceController = TextEditingController(text: '100');

  @override
  void initState() {
    super.initState();
    _basePriceController.text = _rideController.basePrice.value.toString();
  }

  @override
  void dispose() {
    _basePriceController.dispose();
    super.dispose();
  }

  void _handleStartRide() async {
    print('[StartRideScreen] ===== START RIDE BUTTON PRESSED =====');
    
    if (_authController.currentDriver.value == null) {
      print('[StartRideScreen] ERROR: currentDriver is null');
      _showErrorDialog('Error', 'Driver information not found');
      return;
    }

    print('[StartRideScreen] Driver found: ${_authController.currentDriver.value!.uid}');
    print('[StartRideScreen] Selected passengers: ${_selectedPassengers.value}');
    
    double basePrice = double.tryParse(_basePriceController.text) ?? 100.0;
    print('[StartRideScreen] Base price: $basePrice');
    
    double destLat = _rideController.destinationLatitude.value;
    double destLong = _rideController.destinationLongitude.value;
    print('[StartRideScreen] Destination Lat: $destLat, Long: $destLong');

    // Validate destination coordinates
    if (destLat == 0.0 || destLong == 0.0) {
      print('[StartRideScreen] ERROR: Destination coordinates are zero');
      _showErrorDialog('Missing Information', 'Please enter destination latitude and longitude');
      return;
    }

    print('[StartRideScreen] All validations passed, calling startRide...');
    bool success = await _rideController.startRide(
      driverId: _authController.currentDriver.value!.uid,
      passengers: _selectedPassengers.value,
      basePrice: basePrice,
      destinationLat: destLat,
      destinationLong: destLong,
    );

    print('[StartRideScreen] startRide returned: $success');
    
    if (success) {
      print('[StartRideScreen] Navigating to /ride-in-progress');
      Get.offNamed('/ride-in-progress');
    } else {
      print('[StartRideScreen] ERROR: ${_rideController.errorMessage.value}');
      _showErrorDialog('Failed to Start Ride', _rideController.errorMessage.value);
    }
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Start New Ride'),
          automaticallyImplyLeading: false,
        ),
        body: Obx(
          () => SingleChildScrollView(
            padding: const EdgeInsets.all(AppPadding.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Location Card
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
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppPadding.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Location',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.mediumGray,
                                      ),
                                ),
                                const SizedBox(height: AppPadding.xs),
                                Text(
                                  _rideController.startAddress.value,
                                  style: Theme.of(context).textTheme.titleMedium,
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

                // Passengers Selection
                Text(
                  'Number of Seats',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppPadding.md),
                _buildPassengerSelector(),
                const SizedBox(height: AppPadding.xl),

                // Base Price
                Text(
                  'Base Price (₹)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppPadding.md),
                TextFormField(
                  controller: _basePriceController,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    double price = double.tryParse(value) ?? 100.0;
                    _rideController.updateBasePrice(price);
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter base price',
                    prefixIcon: const Icon(
                      Icons.currency_rupee,
                      color: AppColors.primaryYellow,
                    ),
                  ),
                ),
                const SizedBox(height: AppPadding.xl),

                // Destination Latitude
                Text(
                  'Destination Latitude',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppPadding.md),
                TextFormField(
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  onChanged: (value) {
                    _rideController.setDestinationLatitude(double.tryParse(value) ?? 0.0);
                  },
                  decoration: InputDecoration(
                    hintText: 'e.g., 28.5355',
                    prefixIcon: const Icon(
                      Icons.map,
                      color: AppColors.primaryYellow,
                    ),
                  ),
                ),
                const SizedBox(height: AppPadding.lg),

                // Destination Longitude
                Text(
                  'Destination Longitude',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppPadding.md),
                TextFormField(
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  onChanged: (value) {
                    _rideController.setDestinationLongitude(double.tryParse(value) ?? 0.0);
                  },
                  decoration: InputDecoration(
                    hintText: 'e.g., 77.3910',
                    prefixIcon: const Icon(
                      Icons.map,
                      color: AppColors.primaryYellow,
                    ),
                  ),
                ),
                const SizedBox(height: AppPadding.xl),

                // Price Preview
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
                            'Estimated Total:',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₹${_rideController.basePrice.value.toStringAsFixed(2)}',
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

                // Info Message
                Container(
                  padding: const EdgeInsets.all(AppPadding.md),
                  decoration: BoxDecoration(
                    color: AppColors.infoBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info,
                        color: AppColors.infoBlue,
                      ),
                      const SizedBox(width: AppPadding.md),
                      Expanded(
                        child: Text(
                          'Final price will be calculated after destination is set',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppPadding.xl),

                // Start Ride Button
                CustomButton(
                  label: _rideController.isLoading.value ? 'Starting...' : 'Start Ride',
                  onPressed: _handleStartRide,
                  isLoading: _rideController.isLoading.value,
                  isEnabled: !_rideController.isLoading.value,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPassengerSelector() {
    return Row(
      children: [
        _buildPassengerButton(1),
        const SizedBox(width: AppPadding.md),
        _buildPassengerButton(2),
        const SizedBox(width: AppPadding.md),
        _buildPassengerButton(3),
        const SizedBox(width: AppPadding.md),
        _buildPassengerButton(4),
      ],
    );
  }

  Widget _buildPassengerButton(int count) {
    return Obx(
      () => GestureDetector(
        onTap: () {
          _selectedPassengers.value = count;
          _rideController.updateNumberOfPassengers(count);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.md,
            vertical: AppPadding.md,
          ),
          decoration: BoxDecoration(
            color: _selectedPassengers.value == count
                ? AppColors.primaryYellow
                : AppColors.lightGray,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: _selectedPassengers.value == count
                  ? AppColors.primaryYellow
                  : AppColors.mediumGray,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.people,
                color: _selectedPassengers.value == count
                    ? AppColors.primaryBlack
                    : AppColors.mediumGray,
                size: 24,
              ),
              const SizedBox(height: AppPadding.xs),
              Text(
                '$count',
                style: TextStyle(
                  color: _selectedPassengers.value == count
                      ? AppColors.primaryBlack
                      : AppColors.mediumGray,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
