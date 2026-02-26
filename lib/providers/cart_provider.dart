import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class CartProvider with ChangeNotifier {
  final List<CartItemModel> _items = [];
  String? _storeId;
  String _fulfillmentType = 'DELIVERY'; // 'DELIVERY' or 'TAKEAWAY'
  bool _isInitialized = false;

  List<CartItemModel> get items => _items;
  String? get storeId => _storeId;
  String get fulfillmentType => _fulfillmentType;
  int get itemCount => _items.length;
  bool get isEmpty => _items.isEmpty;
  bool get isDelivery => _fulfillmentType == 'DELIVERY';

  // Initialize cart from storage
  Future<void> initializeCart() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString('cart_items');
      final storeId = prefs.getString('cart_store_id');
      final fulfillmentType = prefs.getString('cart_fulfillment_type');
      
      if (cartJson != null) {
        final List<dynamic> cartList = json.decode(cartJson);
        _items.clear();
        for (var item in cartList) {
          _items.add(CartItemModel.fromJson(item));
        }
        print('🛒 Restored ${_items.length} items from cart');
      }
      
      if (storeId != null) {
        _storeId = storeId;
      }
      
      if (fulfillmentType != null) {
        _fulfillmentType = fulfillmentType;
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error loading cart: $e');
      _isInitialized = true;
    }
  }

  // Save cart to storage
  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_items.isEmpty) {
        await prefs.remove('cart_items');
        await prefs.remove('cart_store_id');
        await prefs.remove('cart_fulfillment_type');
      } else {
        final cartJson = json.encode(_items.map((item) => item.toJson()).toList());
        await prefs.setString('cart_items', cartJson);
        
        if (_storeId != null) {
          await prefs.setString('cart_store_id', _storeId!);
        }
        
        await prefs.setString('cart_fulfillment_type', _fulfillmentType);
      }
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  // Calculate subtotal
  double get subtotal {
    return _items.fold(0, (sum, item) => sum + item.subtotal);
  }

  // Calculate tax (5% GST)
  double get tax => subtotal * 0.05;

  // Calculate delivery fee based on order value (mirrors backend logic)
  double get deliveryFee {
    if (_fulfillmentType == 'TAKEAWAY') return 0.0;

    // Free delivery for orders >= Rs 199
    if (subtotal >= 199) return 0.0;

    // Estimated delivery fee based on order value
    // (exact fee calculated on backend with distance)
    if (subtotal < 50) return 35.0;
    if (subtotal < 100) return 30.0;
    if (subtotal < 150) return 25.0;
    return 20.0;
  }

  // Calculate total
  double get total => subtotal + tax + deliveryFee;

  // Set fulfillment type
  void setFulfillmentType(String type) {
    _fulfillmentType = type;
    _saveCart();
    notifyListeners();
  }

  // Add item to cart
  void addItem(ProductModel product, {String? storeId, double quantity = 1.0}) {
    // Check if adding from different store
    if (_storeId != null && storeId != null && _storeId != storeId) {
      throw Exception('Cannot add items from different stores');
    }

    _storeId = storeId;

    // Check if item already exists
    final existingIndex = _items.indexWhere(
      (item) => item.product.productId == product.productId,
    );

    if (existingIndex >= 0) {
      // Increase quantity
      _items[existingIndex].quantity += quantity;
    } else {
      // Add new item
      _items.add(CartItemModel(product: product, quantity: quantity));
    }

    _saveCart();
    notifyListeners();
  }

  // Remove item from cart
  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.productId == productId);
    
    if (_items.isEmpty) {
      _storeId = null;
    }
    
    _saveCart();
    notifyListeners();
  }

  // Update item quantity
  void updateQuantity(String productId, double quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final index = _items.indexWhere(
      (item) => item.product.productId == productId,
    );

    if (index >= 0) {
      _items[index].quantity = quantity;
      _saveCart();
      notifyListeners();
    }
  }

  // Increase quantity
  void increaseQuantity(String productId) {
    final index = _items.indexWhere(
      (item) => item.product.productId == productId,
    );

    if (index >= 0) {
      _items[index].quantity += 1.0;
      _saveCart();
      notifyListeners();
    }
  }

  // Decrease quantity
  void decreaseQuantity(String productId) {
    final index = _items.indexWhere(
      (item) => item.product.productId == productId,
    );

    if (index >= 0) {
      if (_items[index].quantity > 1.0) {
        _items[index].quantity -= 1.0;
        _saveCart();
        notifyListeners();
      } else {
        removeItem(productId);
      }
    }
  }

  // Clear cart
  void clearCart() {
    _items.clear();
    _storeId = null;
    _fulfillmentType = 'DELIVERY';
    _saveCart();
    notifyListeners();
  }

  // Get item quantity
  double getItemQuantity(String productId) {
    final item = _items.firstWhere(
      (item) => item.product.productId == productId,
      orElse: () => CartItemModel(
        product: ProductModel(
          productId: '',
          storeId: '',
          name: '',
          category: '',
          price: 0,
          stockQuantity: 0,
        ),
        quantity: 0,
      ),
    );
    return item.quantity;
  }

  // Check if product is in cart
  bool isInCart(String productId) {
    return _items.any((item) => item.product.productId == productId);
  }
}
