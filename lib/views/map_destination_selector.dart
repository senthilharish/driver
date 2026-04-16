import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import 'package:driver/utils/app_theme.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapDestinationSelector extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapDestinationSelector({
    Key? key,
    this.initialLat,
    this.initialLng,
  }) : super(key: key);

  @override
  State<MapDestinationSelector> createState() => _MapDestinationSelectorState();
}

class _MapDestinationSelectorState extends State<MapDestinationSelector> {
  late MapController _mapController;
  late LatLng _selectedLocation;
  String _selectedAddress = 'Select location on map';
  bool _isLoadingAddress = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResultsData = [];
  bool _isSearching = false;
  bool _showSearchResults = false;
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    
    // Initialize with provided coordinates or default location
    _selectedLocation = LatLng(
      widget.initialLat ?? 28.7041,
      widget.initialLng ?? 77.1025,
    );
    
    if (widget.initialLat != null && widget.initialLng != null) {
      _getAddressFromCoordinates(_selectedLocation);
    }
  }

  void _getAddressFromCoordinates(LatLng location) async {
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      print('[MapSelector] Getting address for: ${location.latitude}, ${location.longitude}');
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('[MapSelector] Geocoding timeout');
          return [];
        },
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        final address =
            '${place.street ?? ''}, ${place.locality ?? ''}, ${place.postalCode ?? ''}';
        setState(() {
          _selectedAddress = address.replaceAll(RegExp(r',\s*,'), ',').trim();
        });
        print('[MapSelector] Address: $_selectedAddress');
      } else {
        setState(() {
          _selectedAddress =
              '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
        });
      }
    } catch (e) {
      print('[MapSelector] Error getting address: $e');
      setState(() {
        _selectedAddress =
            '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
      });
    } finally {
      setState(() {
        _isLoadingAddress = false;
      });
    }
  }

  void _handleMapTap(LatLng tappedLocation) {
    print('[MapSelector] Map tapped at: ${tappedLocation.latitude}, ${tappedLocation.longitude}');
    setState(() {
      _selectedLocation = tappedLocation;
    });
    _getAddressFromCoordinates(tappedLocation);
  }

  void _handleConfirm() {
    if (_selectedLocation.latitude == 0 && _selectedLocation.longitude == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location on the map'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    Get.back(result: {
      'latitude': _selectedLocation.latitude,
      'longitude': _selectedLocation.longitude,
      'address': _selectedAddress,
    });
  }

  void _handleCurrentLocation() {
    // Default to Delhi, India
    final defaultLocation = LatLng(28.7041, 77.1025);
    _mapController.move(defaultLocation, 13);
    _handleMapTap(defaultLocation);
  }

  void _onSearchChanged(String query) {
    // Cancel previous timer
    _searchDebounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _showSearchResults = false;
        _searchResultsData = [];
      });
      return;
    }

    // Start a new timer with 800ms delay
    _searchDebounceTimer = Timer(const Duration(milliseconds: 800), () {
      _searchPlace(query);
    });
  }

  Future<void> _searchPlace(String query) async {
    if (!mounted) return;

    setState(() {
      _isSearching = true;
      _showSearchResults = true;
    });

    try {
      print('[MapSelector] Searching for place: $query');
      
      // Try using geocoding package first
      List<Location> locations = [];
      try {
        locations = await locationFromAddress(query).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('[MapSelector] Geocoding timeout, trying Nominatim API');
            return [];
          },
        );
      } catch (e) {
        print('[MapSelector] Geocoding error: $e, trying Nominatim API');
      }

      // If geocoding fails or returns empty, use Nominatim API (OpenStreetMap)
      if (locations.isEmpty) {
        print('[MapSelector] Using Nominatim API for search');
        locations = await _searchUsingNominatim(query);
      }

      if (!mounted) return;

      if (locations.isNotEmpty) {
        print('[MapSelector] Found ${locations.length} results');
        
        // Get placemarks for each location
        List<Map<String, dynamic>> results = [];
        for (var location in locations) {
          try {
            List<Placemark> placemarks = await placemarkFromCoordinates(
              location.latitude,
              location.longitude,
            ).timeout(
              const Duration(seconds: 3),
              onTimeout: () => [],
            );
            
            String addressText = '';
            if (placemarks.isNotEmpty) {
              final p = placemarks[0];
              addressText = '${p.street ?? ''}, ${p.locality ?? ''}, ${p.administrativeArea ?? ''}'
                  .replaceAll(RegExp(r',\s*,'), ',')
                  .trim();
            } else {
              addressText = '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
            }

            results.add({
              'name': query,
              'latitude': location.latitude,
              'longitude': location.longitude,
              'address': addressText,
            });
          } catch (e) {
            print('[MapSelector] Error getting placemark: $e');
            // Still add the location even if we can't get placemark
            results.add({
              'name': query,
              'latitude': location.latitude,
              'longitude': location.longitude,
              'address': '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
            });
          }
        }

        if (!mounted) return;
        setState(() {
          _searchResultsData = results;
          _isSearching = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _searchResultsData = [];
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No places found'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } catch (e) {
      print('[MapSelector] Error searching place: $e');
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searchResultsData = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<List<Location>> _searchUsingNominatim(String query) async {
    try {
      final String url = 'https://nominatim.openstreetmap.org/search'
          '?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1';
      
      print('[MapSelector] Nominatim API URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'FlutterDriver/1.0',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Nominatim API timeout'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('[MapSelector] Nominatim returned ${data.length} results');
        
        List<Location> locations = [];
        for (var item in data) {
          try {
            final lat = double.parse(item['lat'].toString());
            final lon = double.parse(item['lon'].toString());
            locations.add(Location(
              latitude: lat,
              longitude: lon,
              timestamp: DateTime.now(),
            ));
          } catch (e) {
            print('[MapSelector] Error parsing location: $e');
          }
        }
        return locations;
      } else {
        print('[MapSelector] Nominatim API error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[MapSelector] Error calling Nominatim API: $e');
      return [];
    }
  }

  void _selectSearchResultData(Map<String, dynamic> result) async {
    print('[MapSelector] Selected search result: ${result['name']}');

    final latitude = result['latitude'] as double?;
    final longitude = result['longitude'] as double?;
    final address = result['address'] as String?;

    if (latitude != null && longitude != null) {
      final newLocation = LatLng(latitude, longitude);
      setState(() {
        _selectedLocation = newLocation;
        _selectedAddress = address ?? 'Selected Location';
        _showSearchResults = false;
        _searchController.clear();
      });
      _mapController.move(newLocation, 15);
      print('[MapSelector] Map moved to: $latitude, $longitude');
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Destination'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _handleCurrentLocation,
            icon: const Icon(Icons.my_location),
            tooltip: 'Current Location',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 13,
              onTap: (tapPosition, latLng) => _handleMapTap(latLng),
            ),
            children: [
              // Map layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              // Markers
              MarkerLayer(
                markers: [
                  Marker(
                    width: 80,
                    height: 80,
                    point: _selectedLocation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.primaryYellow,
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
                            color: AppColors.primaryBlack,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Center marker circle
          Center(
            child: IgnorePointer(
              child: Icon(
                Icons.add_circle,
                color: AppColors.infoBlue.withOpacity(0.5),
                size: 48,
              ),
            ),
          ),

          // Search bar at top
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: TextField(
                controller: _searchController,
                onChanged: (query) {
                  _onSearchChanged(query);
                },
                decoration: InputDecoration(
                  hintText: 'Search places...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.primaryYellow),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchDebounceTimer?.cancel();
                            setState(() {
                              _showSearchResults = false;
                              _searchResultsData = [];
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          // Search results dropdown
          if (_showSearchResults && _searchResultsData.isNotEmpty)
            Positioned(
              top: 70,
              left: 12,
              right: 12,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResultsData.length,
                    itemBuilder: (context, index) {
                      final result = _searchResultsData[index];
                      
                      return ListTile(
                        leading: const Icon(Icons.location_on, color: AppColors.primaryYellow),
                        title: Text(
                          result['name'] ?? 'Unknown',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          result['address'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () => _selectSearchResultData(result),
                      );
                    },
                  ),
                ),
              ),
            ),

          // Loading indicator
          if (_isSearching)
            Positioned(
              top: 70,
              left: 12,
              right: 12,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: const SizedBox(
                    height: 24,
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Bottom sheet with address and confirm button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.lg),
                  topRight: Radius.circular(AppRadius.lg),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(AppPadding.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coordinates display
                  Container(
                    padding: const EdgeInsets.all(AppPadding.md),
                    decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coordinates',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.mediumGray,
                              ),
                        ),
                        const SizedBox(height: AppPadding.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Lat: ${_selectedLocation.latitude.toStringAsFixed(4)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Lng: ${_selectedLocation.longitude.toStringAsFixed(4)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppPadding.lg),

                  // Address display
                  Text(
                    'Address',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mediumGray,
                        ),
                  ),
                  const SizedBox(height: AppPadding.sm),
                  Container(
                    padding: const EdgeInsets.all(AppPadding.md),
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.primaryYellow),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _isLoadingAddress
                              ? Row(
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    const SizedBox(width: AppPadding.md),
                                    Text(
                                      'Getting address...',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                )
                              : Text(
                                  _selectedAddress,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppPadding.lg),

                  // Confirm button
                  GestureDetector(
                    onTap: _handleConfirm,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: AppPadding.lg),
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        'Confirm Destination',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.primaryBlack,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
