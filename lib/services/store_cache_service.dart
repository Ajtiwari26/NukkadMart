import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/store_model.dart';
import '../models/product_model.dart';

class StoreCacheService {
  static const String _nearbyStoresKey = 'nearby_stores';
  static const String _nearbyStoresTimeKey = 'nearby_stores_time';
  static const String _storeProductsPrefix = 'store_products_';
  static const String _storeProductsTimePrefix = 'store_products_time_';
  static const Duration _storesCacheValidity = Duration(minutes: 30);
  static const Duration _productsCacheValidity = Duration(minutes: 15);

  /// Save nearby stores to cache
  static Future<void> saveNearbyStores(List<StoreModel> stores) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storesJson = stores.map((s) => s.toJson()).toList();
      await prefs.setString(_nearbyStoresKey, json.encode(storesJson));
      await prefs.setInt(_nearbyStoresTimeKey, DateTime.now().millisecondsSinceEpoch);
      print('🏪 Cached ${stores.length} nearby stores');
    } catch (e) {
      print('Error saving stores cache: $e');
    }
  }

  /// Get cached nearby stores if valid
  static Future<List<StoreModel>?> getNearbyStores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storesJson = prefs.getString(_nearbyStoresKey);
      final timestamp = prefs.getInt(_nearbyStoresTimeKey);

      if (storesJson == null || timestamp == null) {
        return null;
      }

      // Check if cache is still valid
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cacheTime) > _storesCacheValidity) {
        print('🏪 Stores cache expired');
        return null;
      }

      final storesList = json.decode(storesJson) as List;
      final stores = storesList.map((s) => StoreModel.fromJson(s)).toList();
      print('🏪 Using cached stores: ${stores.length} stores');
      return stores;
    } catch (e) {
      print('Error reading stores cache: $e');
      return null;
    }
  }

  /// Save store products to cache
  static Future<void> saveStoreProducts(String storeId, List<ProductModel> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final productsJson = products.map((p) => p.toJson()).toList();
      await prefs.setString('$_storeProductsPrefix$storeId', json.encode(productsJson));
      await prefs.setInt('$_storeProductsTimePrefix$storeId', DateTime.now().millisecondsSinceEpoch);
      print('📦 Cached ${products.length} products for store $storeId');
    } catch (e) {
      print('Error saving products cache: $e');
    }
  }

  /// Get cached store products if valid
  static Future<List<ProductModel>?> getStoreProducts(String storeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final productsJson = prefs.getString('$_storeProductsPrefix$storeId');
      final timestamp = prefs.getInt('$_storeProductsTimePrefix$storeId');

      if (productsJson == null || timestamp == null) {
        return null;
      }

      // Check if cache is still valid
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cacheTime) > _productsCacheValidity) {
        print('📦 Products cache expired for store $storeId');
        return null;
      }

      final productsList = json.decode(productsJson) as List;
      final products = productsList.map((p) => ProductModel.fromJson(p)).toList();
      print('📦 Using cached products: ${products.length} products');
      return products;
    } catch (e) {
      print('Error reading products cache: $e');
      return null;
    }
  }

  /// Clear all cache
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_nearbyStoresKey) || 
            key.startsWith(_storeProductsPrefix) ||
            key.startsWith(_storeProductsTimePrefix)) {
          await prefs.remove(key);
        }
      }
      print('🗑️ All store cache cleared');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Clear cache for specific store
  static Future<void> clearStoreCache(String storeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_storeProductsPrefix$storeId');
      await prefs.remove('$_storeProductsTimePrefix$storeId');
      print('🗑️ Cache cleared for store $storeId');
    } catch (e) {
      print('Error clearing store cache: $e');
    }
  }
}
