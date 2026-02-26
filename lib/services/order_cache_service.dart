import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class OrderCacheService {
  static const String _recentOrdersKey = 'recent_orders';
  static const String _recentOrdersTimeKey = 'recent_orders_time';
  static const String _activeOrderPrefix = 'active_order_';
  static const String _activeOrderTimePrefix = 'active_order_time_';
  static const Duration _recentOrdersCacheValidity = Duration(minutes: 5);
  static const Duration _activeOrderCacheValidity = Duration(minutes: 2);

  /// Save recent orders to cache
  static Future<void> saveRecentOrders(List<Map<String, dynamic>> orders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_recentOrdersKey, json.encode(orders));
      await prefs.setInt(_recentOrdersTimeKey, DateTime.now().millisecondsSinceEpoch);
      print('📦 Cached ${orders.length} recent orders');
    } catch (e) {
      print('Error saving orders cache: $e');
    }
  }

  /// Get cached recent orders if valid
  static Future<List<Map<String, dynamic>>?> getRecentOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ordersJson = prefs.getString(_recentOrdersKey);
      final timestamp = prefs.getInt(_recentOrdersTimeKey);

      if (ordersJson == null || timestamp == null) {
        return null;
      }

      // Check if cache is still valid
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cacheTime) > _recentOrdersCacheValidity) {
        print('📦 Orders cache expired');
        return null;
      }

      final ordersList = json.decode(ordersJson) as List;
      final orders = ordersList.map((o) => o as Map<String, dynamic>).toList();
      print('📦 Using cached orders: ${orders.length} orders');
      return orders;
    } catch (e) {
      print('Error reading orders cache: $e');
      return null;
    }
  }

  /// Save active order details to cache
  static Future<void> saveActiveOrder(String orderId, Map<String, dynamic> order) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_activeOrderPrefix$orderId', json.encode(order));
      await prefs.setInt('$_activeOrderTimePrefix$orderId', DateTime.now().millisecondsSinceEpoch);
      print('📦 Cached active order: $orderId');
    } catch (e) {
      print('Error saving active order cache: $e');
    }
  }

  /// Get cached active order if valid
  static Future<Map<String, dynamic>?> getActiveOrder(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orderJson = prefs.getString('$_activeOrderPrefix$orderId');
      final timestamp = prefs.getInt('$_activeOrderTimePrefix$orderId');

      if (orderJson == null || timestamp == null) {
        return null;
      }

      // Check if cache is still valid
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cacheTime) > _activeOrderCacheValidity) {
        print('📦 Active order cache expired: $orderId');
        return null;
      }

      final order = json.decode(orderJson) as Map<String, dynamic>;
      print('📦 Using cached active order: $orderId');
      return order;
    } catch (e) {
      print('Error reading active order cache: $e');
      return null;
    }
  }

  /// Clear recent orders cache
  static Future<void> clearRecentOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentOrdersKey);
      await prefs.remove(_recentOrdersTimeKey);
      print('📦 Recent orders cache cleared');
    } catch (e) {
      print('Error clearing orders cache: $e');
    }
  }

  /// Clear specific active order cache
  static Future<void> clearActiveOrder(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_activeOrderPrefix$orderId');
      await prefs.remove('$_activeOrderTimePrefix$orderId');
      print('📦 Active order cache cleared: $orderId');
    } catch (e) {
      print('Error clearing active order cache: $e');
    }
  }

  /// Clear all order cache
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_recentOrdersKey) || 
            key.startsWith(_activeOrderPrefix) ||
            key.startsWith(_activeOrderTimePrefix)) {
          await prefs.remove(key);
        }
      }
      print('📦 All order cache cleared');
    } catch (e) {
      print('Error clearing all order cache: $e');
    }
  }
}
