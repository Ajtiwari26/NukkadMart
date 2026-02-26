import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // Initialize - Check if user is logged in
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    
    if (userId != null) {
      try {
        _user = await _authService.getUserById(userId);
        // Load local addresses if needed, or rely on _user to have them from backend
        notifyListeners();
      } catch (e) {
        // User data not found, clear local storage
        await logout();
      }
    }
  }

  // Quick Register/Login
  Future<bool> quickRegister(String name, String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.quickRegister(name, phone);
      
      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', _user!.userId);
      await prefs.setString('userName', _user!.name);
      await prefs.setString('userPhone', _user!.phone);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Refresh User Data
  Future<void> refreshUserData() async {
    if (_user == null) return;

    try {
      _user = await _authService.getUserById(_user!.userId);
      
      // Update local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', _user!.name);
      await prefs.setString('userPhone', _user!.phone);
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Save Address & Set as Preferred
  Future<bool> saveAddress(Map<String, dynamic> addressData) async {
    if (_user == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Call Service (Backend)
      final newAddress = await _authService.saveAddress(_user!.userId, addressData);
      
      // 2. Update Local User Model
      // Create a mutable copy of addresses
      final currentAddresses = List<AddressModel>.from(_user!.addresses);
      // If new is default, unset others (logic depends on your needs)
      currentAddresses.add(newAddress);
      
      _user = UserModel(
        userId: _user!.userId,
        name: _user!.name,
        phone: _user!.phone,
        email: _user!.email,
        totalPurchases: _user!.totalPurchases,
        totalOrders: _user!.totalOrders,
        createdAt: _user!.createdAt,
        addresses: currentAddresses,
      );

      // 3. Persist "Preferred Location" to SharedPreferences for Startup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('preferred_lat', newAddress.lat);
      await prefs.setDouble('preferred_lng', newAddress.lng);
      await prefs.setString('preferred_address_text', newAddress.fullAddress);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Load Preferred Address (for Startup)
  Future<Map<String, dynamic>?> loadPreferredAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('preferred_lat');
    final lng = prefs.getDouble('preferred_lng');
    final text = prefs.getString('preferred_address_text');

    if (lat != null && lng != null) {
      return {
        'lat': lat,
        'lng': lng,
        'address': text ?? '',
      };
    }
    return null;
  }

  // Logout
  Future<void> logout() async {
    _user = null;
    
    final prefs = await SharedPreferences.getInstance();
    // Clear Auth
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userPhone');
    // Clear Preferred Location? (Optional, maybe keep it for convenience)
    // await prefs.remove('preferred_lat');
    // await prefs.remove('preferred_lng');
    
    notifyListeners();
  }
}
