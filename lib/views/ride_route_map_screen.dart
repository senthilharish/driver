import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import 'package:driver/controllers/ride_controller.dart';
import 'package:driver/utils/app_theme.dart';

class RideRouteMapScreen extends StatefulWidget {
  const RideRouteMapScreen({Key? key}) : super(key: key);

  @override
  State<RideRouteMapScreen> createState() => _RideRouteMapScreenState();
}

class _RideRouteMapScreenState extends State<RideRouteMapScreen> {
  late MapController _mapController;
  final RideController _controller = Get.find<RideController>();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _fitBounds(LatLng startLocation, LatLng endLocation) {
    final centerLat = (startLocation.latitude + endLocation.latitude) / 2;
    final centerLng = (startLocation.longitude + endLocation.longitude) / 2;
    final center = LatLng(centerLat, centerLng);
    _mapController.move(center, 12);
  }

  @override
  Widget build(BuildContext context) {
    // Get start and end locations from current ride
    late LatLng startLocation;
    late LatLng endLocation;
    
    try {
      final ride = _controller.currentRide.value;
      if (ride != null) {
        startLocation = LatLng(ride.startLatitude, ride.startLongitude);
        endLocation = LatLng(
          ride.destinationLatitude ?? 28.5355,
          ride.destinationLongitude ?? 77.3910,
        );
        
        print('[RideRouteMap] Start: ${startLocation.latitude}, ${startLocation.longitude}');
        print('[RideRouteMap] End: ${endLocation.latitude}, ${endLocation.longitude}');
      } else {
        // Fallback to default location (Delhi)
        startLocation = const LatLng(28.7041, 77.1025);
        endLocation = const LatLng(28.5355, 77.3910);
      }
    } catch (e) {
      print('[RideRouteMap] Error: $e');
      startLocation = const LatLng(28.7041, 77.1025);
      endLocation = const LatLng(28.5355, 77.3910);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Route'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out_map),
            onPressed: () => _fitBounds(startLocation, endLocation),
            tooltip: 'Fit Route',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: startLocation,
              initialZoom: 13,
            ),
            children: [
              // Map tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),

              // Polyline from start to end
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [startLocation, endLocation],
                    color: AppColors.primaryYellow,
                    strokeWidth: 4.0,
                  ),
                ],
              ),

              // Markers
              MarkerLayer(
                markers: [
                  // Start location marker
                  Marker(
                    width: 80,
                    height: 80,
                    point: startLocation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.successGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Start',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // End location marker
                  Marker(
                    width: 80,
                    height: 80,
                    point: endLocation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.errorRed,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.errorRed,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'End',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
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

          // Route info card at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Route info
                  Text(
                    'Route Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Start location info
                  _buildLocationInfo(
                    context,
                    icon: Icons.location_on,
                    iconColor: AppColors.successGreen,
                    label: 'Start Location',
                    value: _controller.startAddress.value,
                    coordinates: '${startLocation.latitude.toStringAsFixed(4)}, ${startLocation.longitude.toStringAsFixed(4)}',
                  ),
                  const SizedBox(height: 12),

                  // End location info
                  _buildLocationInfo(
                    context,
                    icon: Icons.location_on,
                    iconColor: AppColors.errorRed,
                    label: 'End Location',
                    value: _controller.destinationAddress.value,
                    coordinates: '${endLocation.latitude.toStringAsFixed(4)}, ${endLocation.longitude.toStringAsFixed(4)}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildLocationInfo(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String coordinates,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            coordinates,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
