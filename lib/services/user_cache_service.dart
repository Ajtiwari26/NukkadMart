import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserCacheService {
  static const String _userProfileKey = 'user_profile';
  static const String _userProfileTimeKey = 'user_profile_time';
  static const String _savedAddressesKey = 'saved_addresses';
  static const String _savedAddressesTimeKey = 'saved_addresses_time';
  static const Duration _profileCacheValidity = Duration(hours: 6);
  static const Duration _addressesCacheValidity = Duration(hours: 12);

  /// Save user profile to cache
  static Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userProfileKey, json.encode(profile));
      await prefs.setInt(_userProfileTimeKey, DateTime.now().millisecondsSinceEpoch);
      print('👤 User profile cached');
    } catch (e) {
      print('Error saving user profile cache: $e');
    }
  }

  /// Get cached user profile if valid
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_userProfileKey);
      final timestamp = prefs.getInt(_userProfileTimeKey);

      if (profileJson == null || timestamp == null) {
        return null;
      }

      // Check if cache is still valid
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cacheTime) > _profileCacheValidity) {
        print('👤 User profile cache expired');
        return null;
      }

      final profile = json.decode(profileJson) as Map<String, dynamic>;
      print('👤 Using cached user profile');
      return profile;
    } catch (e) {
      print('Error reading user profile cache: $e');
      return null;
    }
  }

  /// Save saved addresses to cache
  static Future<void> saveSavedAddresses(List<Map<String, dynamic>> addresses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_savedAddressesKey, json.encode(addresses));
      await prefs.setInt(_savedAddressesTimeKey, DateTime.now().millisecondsSinceEpoch);
      print('📍 Saved ${addresses.length} addresses to cache');
    } catch (e) {
      print('Error saving addresses cache: $e');
    }
  }

  /// Get cached saved addresses if valid
  static Future<List<Map<String, dynamic>>?> getSavedAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final addressesJson = prefs.getString(_savedAddressesKey);
      final timestamp = prefs.getInt(_savedAddressesTimeKey);

      if (addressesJson == null || timestamp == null) {
        return null;
      }

      // Check if cache is still valid
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cacheTime) > _addressesCacheValidity) {
        print('📍 Addresses cache expired');
        return null;
      }

      final addressesList = json.decode(addressesJson) as List;
      final addresses = addressesList.map((a) => a as Map<String, dynamic>).toList();
      print('📍 Using cached addresses: ${addresses.length} addresses');
      return addresses;
    } catch (e) {
      print('Error reading addresses cache: $e');
      return null;
    }
  }

  /// Clear user profile cache
  static Future<void> clearUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userProfileKey);
      await prefs.remove(_userProfileTimeKey);
      print('👤 User profile cache cleared');
    } catch (e) {
      print('Error clearing user profile cache: $e');
    }
  }

  /// Clear saved addresses cache
  static Future<void> clearSavedAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_savedAddressesKey);
      await prefs.remove(_savedAddressesTimeKey);
      print('📍 Addresses cache cleared');
    } catch (e) {
      print('Error clearing addresses cache: $e');
    }
  }

  /// Clear all user-related cache
  static Future<void> clearAll() async {
    await clearUserProfile();
    await clearSavedAddresses();
  }
}
