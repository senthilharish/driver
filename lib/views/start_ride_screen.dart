import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:driver/controllers/auth_controller.dart';
import 'package:driver/controllers/ride_controller.dart';
import 'package:driver/utils/app_theme.dart';
import 'package:driver/widgets/custom_widgets.dart';
import 'package:driver/views/map_destination_selector.dart';

class StartRideScreen extends StatefulWidget {
  const StartRideScreen({Key? key}) : super(key: key);

  @override
  State<StartRideScreen> createState() => _StartRideScreenState();
}

class _StartRideScreenState extends State<StartRideScreen> {
  final AuthController _authController = Get.find();
  final RideController _rideController = Get.find();
  final RxInt _selectedPassengers = 1.obs;
  final _basePriceController = TextEditingController(text: '100');
  final RxString _destinationAddress = 'Tap to select on map'.obs;
  final RxBool _hasDestination = false.obs;

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
    double destLng = _rideController.destinationLongitude.value;
    print('[StartRideScreen] Destination Lat: $destLat, Long: $destLng');

    // Validate destination has been selected
    if (!_hasDestination.value) {
      print('[StartRideScreen] ERROR: No destination selected');
      _showErrorDialog('Missing Information', 'Please select destination location on map');
      return;
    }

    print('[StartRideScreen] All validations passed, calling startRide...');
    bool success = await _rideController.startRide(
      driverId: _authController.currentDriver.value!.uid,
      passengers: _selectedPassengers.value,
      basePrice: basePrice,
      destinationLat: destLat,
      destinationLong: destLng,
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

                // Destination Selection
                Text(
                  'Destination Location',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppPadding.md),
                
                // Destination display card
                Obx(() => Container(
                  padding: const EdgeInsets.all(AppPadding.md),
                  decoration: BoxDecoration(
                    color: _hasDestination.value 
                        ? AppColors.primaryYellow.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: _hasDestination.value 
                          ? AppColors.primaryYellow 
                          : Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_hasDestination.value) ...[
                        Text(
                          'Selected Destination:',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: AppPadding.sm),
                        Text(
                          _destinationAddress.value,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppPadding.sm),
                        Text(
                          'Lat: ${_rideController.destinationLatitude.value.toStringAsFixed(4)}, '
                          'Long: ${_rideController.destinationLongitude.value.toStringAsFixed(4)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ] else
                        Text(
                          'Tap button below to select destination on map',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                )),
                const SizedBox(height: AppPadding.md),
                
                // Map selection button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text('Select on Map'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryYellow,
                      foregroundColor: AppColors.primaryBlack,
                      padding: const EdgeInsets.symmetric(vertical: AppPadding.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onPressed: _selectDestinationOnMap,
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

  Future<void> _selectDestinationOnMap() async {
    print('[StartRideScreen] Opening map destination selector...');
    try {
      final result = await Get.to(() => const MapDestinationSelector());
      
      if (result != null && result is Map) {
        print('[StartRideScreen] Map result received: $result');
        
        final latitude = result['latitude'] as double?;
        final longitude = result['longitude'] as double?;
        final address = result['address'] as String?;
        
        if (latitude != null && longitude != null) {
          print('[StartRideScreen] Updating destination - Lat: $latitude, Long: $longitude, Address: $address');
          
          _rideController.setDestinationLatitude(latitude);
          _rideController.setDestinationLongitude(longitude);
          _destinationAddress.value = address ?? 'Selected Location';
          _hasDestination.value = true;
          
          print('[StartRideScreen] Destination updated successfully');
          _showSuccessSnackbar('Destination Selected', address ?? 'Location set on map');
        }
      }
    } catch (e) {
      print('[StartRideScreen] Error selecting destination: $e');
      _showErrorDialog('Map Error', 'Failed to select destination: $e');
    }
  }

  void _showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.successGreen,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
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
