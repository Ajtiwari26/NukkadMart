import 'package:flutter/foundation.dart';
import '../models/store_model.dart';
import '../models/product_model.dart';
import '../services/store_service.dart';
import '../services/store_cache_service.dart';

class StoreProvider with ChangeNotifier {
  final StoreService _storeService = StoreService();
  
  List<StoreModel> _stores = [];
  StoreModel? _selectedStore;
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _error;

  List<StoreModel> get stores => _stores;
  StoreModel? get selectedStore => _selectedStore;
  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Set stores from cache (no loading state)
  void setStoresFromCache(List<StoreModel> cachedStores) {
    _stores = cachedStores;
    notifyListeners();
  }

  // Load nearby stores
  Future<void> loadNearbyStores(double latitude, double longitude) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Loading stores for location: $latitude, $longitude');
      _stores = await _storeService.getNearbyStores(
        latitude: latitude,
        longitude: longitude,
      );
      print('Loaded ${_stores.length} stores');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading stores: $e');
      _error = e.toString();
      _stores = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  // Select store
  Future<void> selectStore(String storeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedStore = await _storeService.getStoreById(storeId);
      await loadStoreProducts(storeId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load store products with cache
  Future<void> loadStoreProducts(String storeId) async {
    // Try cache first
    final cachedProducts = await StoreCacheService.getStoreProducts(storeId);
    if (cachedProducts != null && cachedProducts.isNotEmpty) {
      _products = cachedProducts;
      notifyListeners();
      print('📦 Loaded ${cachedProducts.length} products from cache');
      
      // Refresh in background
      _refreshProductsInBackground(storeId);
      return;
    }

    // Load from API
    try {
      _products = await _storeService.getStoreProducts(storeId);
      // Cache the products
      if (_products.isNotEmpty) {
        await StoreCacheService.saveStoreProducts(storeId, _products);
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> _refreshProductsInBackground(String storeId) async {
    try {
      final freshProducts = await _storeService.getStoreProducts(storeId);
      _products = freshProducts;
      // Update cache
      if (freshProducts.isNotEmpty) {
        await StoreCacheService.saveStoreProducts(storeId, freshProducts);
      }
      notifyListeners();
    } catch (e) {
      print('Background product refresh error: $e');
    }
  }

  // Search products
  Future<void> searchProducts(String storeId, String query) async {
    if (query.isEmpty) {
      await loadStoreProducts(storeId);
      return;
    }

    try {
      _products = await _storeService.searchProducts(storeId, query);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Get products by category
  List<ProductModel> getProductsByCategory(String category) {
    return _products.where((p) => p.category == category).toList();
  }

  // Get all categories
  List<String> get categories {
    return _products.map((p) => p.category).toSet().toList();
  }
}
