import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../providers/store_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../config/api_config.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/store_card.dart';
import '../services/location_cache_service.dart';
import '../services/store_cache_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  final _searchController = TextEditingController();
  String _locationText = 'Detecting location...';
  double _currentLat = ApiConfig.defaultLatitude;
  double _currentLng = ApiConfig.defaultLongitude;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      // 1. Try cached location first (FASTEST - no API calls)
      final cachedLocation = await LocationCacheService.getLocation();
      if (cachedLocation != null) {
        print("📍 Using cached location: ${cachedLocation['address']}");
        _currentLat = cachedLocation['lat'];
        _currentLng = cachedLocation['lng'];
        setState(() {
          _locationText = cachedLocation['address'];
        });
        await _loadStores();
        return; // Skip GPS if cache is valid
      }

      // 2. Check for Preferred Address (Fast Path)
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final preferred = await authProvider.loadPreferredAddress();
      
      if (preferred != null) {
        print("📍 Using Preferred Address: ${preferred['address']}");
        _currentLat = preferred['lat'];
        _currentLng = preferred['lng'];
        setState(() {
          _locationText = preferred['address'];
        });
        // Cache this location for future use
        await LocationCacheService.saveLocation(
          lat: _currentLat,
          lng: _currentLng,
          address: preferred['address'],
        );
        await _loadStores();
        return; // Skip GPS if preferred found
      }

      // 3. Fallback to GPS (Slow Path - only if no cache/preferred)
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locationText = 'Location services disabled');
        _loadStoresWithDefaults();
        return;
      }

      // Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _locationText = 'Location permission denied');
          _loadStoresWithDefaults();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _locationText = 'Location permission permanently denied');
        _loadStoresWithDefaults();
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentLat = position.latitude;
      _currentLng = position.longitude;

      print('GPS Location: $_currentLat, $_currentLng');

      // Reverse geocode to get address
      String addressText = 'Lat: ${_currentLat.toStringAsFixed(4)}, Lng: ${_currentLng.toStringAsFixed(4)}';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final area = p.subLocality?.isNotEmpty == true ? p.subLocality : p.locality;
          final city = p.locality ?? '';
          final state = p.administrativeArea ?? '';
          addressText = '$area, $city, $state';
        }
      } catch (e) {
        print('Geocoding error: $e');
      }

      setState(() {
        _locationText = addressText;
      });

      // Cache the GPS location for future use
      await LocationCacheService.saveLocation(
        lat: _currentLat,
        lng: _currentLng,
        address: addressText,
      );

      // Load stores with real location
      await _loadStores();
    } catch (e) {
      print('Location error: $e');
      setState(() => _locationText = 'Could not detect location');
      _loadStoresWithDefaults();
    }
  }

  Future<void> _loadStoresWithDefaults() async {
    _currentLat = ApiConfig.defaultLatitude;
    _currentLng = ApiConfig.defaultLongitude;
    await _loadStores();
  }

  Future<void> _loadStores() async {
    // Try to load from cache first
    final cachedStores = await StoreCacheService.getNearbyStores();
    if (cachedStores != null && cachedStores.isNotEmpty) {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      storeProvider.setStoresFromCache(cachedStores);
      print('🏪 Loaded ${cachedStores.length} stores from cache');
      
      // Refresh in background (don't await)
      _refreshStoresInBackground();
      return;
    }

    // No cache, load from API
    await _loadStoresFromAPI();
  }

  Future<void> _loadStoresFromAPI() async {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    await storeProvider.loadNearbyStores(_currentLat, _currentLng);
    
    // Cache the loaded stores
    if (storeProvider.stores.isNotEmpty) {
      await StoreCacheService.saveNearbyStores(storeProvider.stores);
    }
  }

  Future<void> _refreshStoresInBackground() async {
    // Refresh stores in background without blocking UI
    try {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      await storeProvider.loadNearbyStores(_currentLat, _currentLng);
      
      // Update cache with fresh data
      if (storeProvider.stores.isNotEmpty) {
        await StoreCacheService.saveNearbyStores(storeProvider.stores);
      }
    } catch (e) {
      print('Background refresh error: $e');
    }
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        break; // Already on home
      case 1:
        Navigator.pushNamed(context, '/ai-scanner');
        break;
      case 2:
        Navigator.pushNamed(context, '/cart');
        break;
      case 3:
        Navigator.pushNamed(context, '/order-history');
        break;
      case 4:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = Provider.of<StoreProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStores,
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      // Logo
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.shopping_cart_rounded,
                          size: 22,
                          color: AppColors.buttonText,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'NUKKAD ',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                'MART',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Market at your fingertip',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Notification bell
                      GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Notifications — Coming Soon!'), backgroundColor: AppColors.primary),
                        ),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.notifications_outlined,
                                size: 22,
                                color: AppColors.textPrimary,
                              ),
                              Positioned(
                                right: 10,
                                top: 10,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Location bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/map-picker'),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _locationText,
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 22,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: GestureDetector(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Search — Coming Soon!'), backgroundColor: AppColors.primary),
                    ),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          Icon(
                            Icons.search_rounded,
                            size: 22,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Search for items or shops...',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: AppColors.border,
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Voice Search — Coming Soon!'), backgroundColor: AppColors.primary),
                            ),
                            child: Icon(
                              Icons.mic_outlined,
                              size: 22,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(width: 14),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Categories
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Categories', style: AppTheme.heading3),
                          Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _CategoryItem(
                            icon: Icons.shopping_basket_rounded,
                            label: 'Groceries',
                            isSelected: true,
                          ),
                          _CategoryItem(
                            icon: Icons.local_pharmacy_rounded,
                            label: 'Pharmacy',
                          ),
                          _CategoryItem(
                            icon: Icons.eco_rounded,
                            label: 'Fresh',
                          ),
                          _CategoryItem(
                            icon: Icons.edit_note_rounded,
                            label: 'Stationery',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // AI Scan Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/ai-scanner'),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.15),
                            AppColors.primary.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Upload List via AI',
                                  style: AppTheme.heading3.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Scan your handwritten list and let our AI create your cart instantly.',
                                  style: AppTheme.bodySmall.copyWith(
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.qr_code_scanner_rounded,
                                        size: 16,
                                        color: AppColors.buttonText,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Scan Now',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.buttonText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.document_scanner_outlined,
                              size: 32,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Nearby Shops Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Nearby Shops', style: AppTheme.heading3),
                      Row(
                        children: [
                          Text(
                            'Distance',
                            style: AppTheme.bodySmall.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.sort_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Store List
              if (storeProvider.isLoading)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
              else if (storeProvider.error != null)
                SliverToBoxAdapter(
                  child: _ErrorWidget(
                    message: storeProvider.error!,
                    onRetry: _loadStores,
                  ),
                )
              else if (storeProvider.stores.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.store_outlined,
                            size: 48,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No stores found nearby',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final store = storeProvider.stores[index];
                        return StoreCard(
                          store: store,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/store',
                              arguments: store.storeId,
                            );
                          },
                        );
                      },
                      childCount: storeProvider.stores.length,
                    ),
                  ),
                ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const _CategoryItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : AppColors.surface,
            shape: BoxShape.circle,
            border: isSelected
                ? null
                : Border.all(color: AppColors.border),
          ),
          child: Icon(
            icon,
            size: 28,
            color: isSelected
                ? AppColors.buttonText
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Could not load stores',
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh, color: AppColors.primary),
              label: Text(
                'Retry',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
