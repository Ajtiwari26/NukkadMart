import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../services/store_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final StoreService _storeService = StoreService();
  
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isDemoMode = authProvider.isDemoMode;

      List<String> storeIds = [];
      if (isDemoMode) {
        storeIds = ['DEMO_STORE_1', 'DEMO_STORE_2', 'DEMO_STORE_3'];
      } else {
        // In production, get nearby stores from StoreProvider
        // For now, use demo stores as fallback
        storeIds = ['DEMO_STORE_1', 'DEMO_STORE_2', 'DEMO_STORE_3'];
      }

      // Search across all stores
      List<Map<String, dynamic>> allResults = [];
      
      for (String storeId in storeIds) {
        try {
          final products = await _storeService.searchProducts(storeId, query);
          
          for (var product in products) {
            allResults.add({
              'product': product,
              'store_id': storeId,
              'store_name': _getStoreName(storeId),
              'distance': _getStoreDistance(storeId),
            });
          }
        } catch (e) {
          print('Error searching store $storeId: $e');
        }
      }

      // Sort by relevance (you can add more sophisticated sorting)
      allResults.sort((a, b) {
        // Sort by distance first, then by price
        int distanceCompare = (a['distance'] as double).compareTo(b['distance'] as double);
        if (distanceCompare != 0) return distanceCompare;
        
        return (a['product'] as ProductModel).price.compareTo((b['product'] as ProductModel).price);
      });

      setState(() {
        _searchResults = allResults;
        _isSearching = false;
      });
    } catch (e) {
      print('Search error: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  String _getStoreName(String storeId) {
    const storeNames = {
      'DEMO_STORE_1': 'TestShop 1',
      'DEMO_STORE_2': 'TestShop 2',
      'DEMO_STORE_3': 'TestShop 3',
    };
    return storeNames[storeId] ?? 'Store';
  }

  double _getStoreDistance(String storeId) {
    // Mock distances - in production, calculate from actual coordinates
    const distances = {
      'DEMO_STORE_1': 0.5,
      'DEMO_STORE_2': 1.2,
      'DEMO_STORE_3': 2.0,
    };
    return distances[storeId] ?? 5.0;
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Search Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                  ),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Search across all nearby shops...',
                          hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 22),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchResults = [];
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Results
            Expanded(
              child: _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_rounded, size: 64, color: AppColors.textTertiary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'Search for products',
              style: AppTheme.heading3.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Find items across all nearby shops',
              style: AppTheme.bodySmall.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.textTertiary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: AppTheme.heading3.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: AppTheme.bodySmall.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        final product = result['product'] as ProductModel;
        final storeName = result['store_name'] as String;
        final distance = result['distance'] as double;
        final storeId = result['store_id'] as String;

        return _buildProductCard(product, storeName, distance, storeId);
      },
    );
  }

  Widget _buildProductCard(ProductModel product, String storeName, double distance, String storeId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Info (Left)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.storefront_rounded, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        storeName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: AppColors.textTertiary),
                    const SizedBox(width: 2),
                    Text(
                      '${distance.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Product Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                image: product.imageUrl?.isNotEmpty == true
                    ? DecorationImage(
                        image: NetworkImage(product.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: product.imageUrl?.isEmpty != false
                  ? const Icon(Icons.shopping_bag, color: AppColors.textTertiary, size: 24)
                  : null,
            ),
            const SizedBox(width: 12),

            // Product Info (Center)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.brand?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      product.brand!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      if (product.unit?.isNotEmpty == true) ...[
                        const SizedBox(width: 4),
                        Text(
                          '/ ${product.unit}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Add Button (Right)
            Consumer<CartProvider>(
              builder: (context, cart, _) {
                final isInCart = cart.items.any((item) => item.product.productId == product.productId);
                
                return GestureDetector(
                  onTap: () {
                    if (!isInCart) {
                      cart.addItem(product, storeId: storeId, quantity: 1);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} added to cart'),
                          backgroundColor: AppColors.success,
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isInCart ? AppColors.success.withOpacity(0.2) : AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isInCart ? Icons.check : Icons.add,
                      color: isInCart ? AppColors.success : AppColors.buttonText,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
