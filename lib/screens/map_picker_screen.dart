import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import '../utils/map_style.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _initialPosition = const LatLng(23.2599, 77.4126); // Default: Bhopal
  LatLng? _currentCenter;
  bool _isLoading = true;
  String _address = 'Fetching location...';
  String _city = '';
  String _pincode = '';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _initialPosition = latLng;
        _currentCenter = latLng;
        _isLoading = false;
      });

      // Move camera if map is already created
      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(latLng, 18));
      }
      
      _getAddressFromLatLng(latLng);
    } catch (e) {
      debugPrint("Error getting location: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getAddressFromLatLng(LatLng pos) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _address = '${place.street}, ${place.subLocality}, ${place.locality}';
          _city = place.locality ?? '';
          _pincode = place.postalCode ?? '';
        });
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
      setState(() {
        _address = 'Unknown Location';
      });
    }
  }

  void _onCameraMove(CameraPosition position) {
    _currentCenter = position.target;
  }

  void _onCameraIdle() {
    if (_currentCenter != null) {
      _getAddressFromLatLng(_currentCenter!);
    }
  }

  void _confirmLocation() {
    if (_currentCenter == null) return;
    
    // Return result structure matching AddressForm expectations if needed, 
    // or just the distinct parts
    Navigator.pop(context, {
      'lat': _currentCenter!.latitude,
      'lng': _currentCenter!.longitude,
      'address': _address,
      'city': _city,
      'pincode': _pincode,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with search
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context), 
                    icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary)
                  ),
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.surface, 
                        borderRadius: BorderRadius.circular(12), 
                        border: Border.all(color: AppColors.border)
                      ),
                      child: TextField(
                        style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search city, area or street...',
                          hintStyle: TextStyle(fontSize: 14, color: AppColors.textTertiary),
                          prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppColors.textTertiary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onSubmitted: (value) async {
                          if (value.trim().isEmpty) return;
                          setState(() => _isLoading = true);
                          try {
                            List<Location> locations = await locationFromAddress(value);
                            if (locations.isNotEmpty) {
                              final loc = locations.first;
                              final latLng = LatLng(loc.latitude, loc.longitude);
                              
                              _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 18));
                              setState(() {
                                _currentCenter = latLng;
                                _isLoading = false;
                              });
                              _getAddressFromLatLng(latLng);
                            } else {
                              setState(() => _isLoading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Location not found')),
                              );
                            }
                          } catch (e) {
                            debugPrint("Search Error: $e"); // Log detailed error
                            setState(() => _isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Could not find "$value"')),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Map area
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _isLoading
                  ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _initialPosition,
                        zoom: 15,
                      ),
                      // cloudMapId: 'bdb471a5894873f375dfe02e', // Disabled to use local style
                      tiltGesturesEnabled: false, // 2D only
                      onMapCreated: (controller) {
                        _mapController = controller;
                        debugPrint("🗺️ Google Map Created");
                        try {
                          controller.setMapStyle(MapStyle.dark);
                          debugPrint("🗺️ Map Style applied");
                        } catch (e) {
                          debugPrint("❌ Error applying map style: $e");
                        }
                      },
                      onCameraMove: _onCameraMove,
                      onCameraIdle: _onCameraIdle,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapType: MapType.normal,
                    ),
                    
                  // Center pin
                  Icon(Icons.location_on, size: 48, color: AppColors.primary),
                  
                  // Use current location button
                  Positioned(
                    bottom: 32, right: 32,
                    child: GestureDetector(
                      onTap: _getCurrentLocation,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface, 
                          shape: BoxShape.circle, 
                          border: Border.all(color: AppColors.border), 
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)]
                        ),
                        child: Icon(Icons.my_location_rounded, size: 22, color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom sheet
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Delivery Location', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            Text(_address, style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: _confirmLocation,
                      style: AppTheme.primaryButton,
                      child: Text('Confirm Location', style: AppTheme.button),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
