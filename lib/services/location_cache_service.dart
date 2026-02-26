import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocationCacheService {
  static const String _lastLocationKey = 'last_location';
  static const String _lastLocationTimeKey = 'last_location_time';
  static const Duration _cacheValidity = Duration(hours: 24); // Cache valid for 24 hours

  /// Save location to cache
  static Future<void> saveLocation({
    required double lat,
    required double lng,
    required String address,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationData = {
        'lat': lat,
        'lng': lng,
        'address': address,
      };
      await prefs.setString(_lastLocationKey, json.encode(locationData));
      await prefs.setInt(_lastLocationTimeKey, DateTime.now().millisecondsSinceEpoch);
      print('📍 Location cached: $address');
    } catch (e) {
      print('Error saving location cache: $e');
    }
  }

  /// Get cached location if valid
  static Future<Map<String, dynamic>?> getLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationJson = prefs.getString(_lastLocationKey);
      final timestamp = prefs.getInt(_lastLocationTimeKey);

      if (locationJson == null || timestamp == null) {
        return null;
      }

      // Check if cache is still valid
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      if (now.difference(cacheTime) > _cacheValidity) {
        print('📍 Location cache expired');
        return null;
      }

      final locationData = json.decode(locationJson) as Map<String, dynamic>;
      print('📍 Using cached location: ${locationData['address']}');
      return locationData;
    } catch (e) {
      print('Error reading location cache: $e');
      return null;
    }
  }

  /// Clear location cache
  static Future<void> clearLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastLocationKey);
      await prefs.remove(_lastLocationTimeKey);
      print('📍 Location cache cleared');
    } catch (e) {
      print('Error clearing location cache: $e');
    }
  }

  /// Check if location cache exists and is valid
  static Future<bool> hasValidCache() async {
    final location = await getLocation();
    return location != null;
  }
}
