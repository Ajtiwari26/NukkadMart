class StoreModel {
  final String storeId;
  final String name;
  final String ownerName;
  final String phone;
  final String? email;
  final StoreAddress? address;
  final String? addressString;
  final String? googleMapsUrl;
  final StoreSettings settings;
  final String status;
  final double? distanceKm;
  final double? rating;
  final bool? isOpen;
  final bool? deliveryAvailable;
  final int? totalProducts;
  final bool? udhaarEnabled;

  StoreModel({
    required this.storeId,
    required this.name,
    this.ownerName = '',
    this.phone = '',
    this.email,
    this.address,
    this.addressString,
    this.googleMapsUrl,
    required this.settings,
    this.status = 'ACTIVE',
    this.distanceKm,
    this.rating,
    this.isOpen,
    this.deliveryAvailable,
    this.totalProducts,
    this.udhaarEnabled,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing StoreModel from JSON: $json');
      
      // Handle both full store response and nearby store response
      final addressData = json['address'];
      StoreAddress? storeAddress;
      String? addressStr;

      if (addressData is Map<String, dynamic>) {
        // Full store response with address object
        print('Address is a Map, parsing as StoreAddress');
        storeAddress = StoreAddress.fromJson(addressData);
      } else if (addressData is String) {
        // Nearby store response with address as string
        print('Address is a String: $addressData');
        addressStr = addressData;
      }

      // Parse settings safely - nearby stores don't have settings
      StoreSettings settings;
      if (json.containsKey('settings') && json['settings'] != null && json['settings'] is Map<String, dynamic>) {
        print('Parsing settings from JSON');
        settings = StoreSettings.fromJson(json['settings'] as Map<String, dynamic>);
      } else {
        print('No settings in JSON, using defaults');
        settings = StoreSettings();
      }

      final model = StoreModel(
        storeId: json['store_id'] ?? '',
        name: json['name'] ?? '',
        ownerName: json['owner_name'] ?? '',
        phone: json['phone'] ?? '',
        email: json['email'],
        address: storeAddress,
        addressString: addressStr,
        googleMapsUrl: json['google_maps_url'],
        settings: settings,
        status: json['status'] ?? 'ACTIVE',
        distanceKm: json['distance_km']?.toDouble(),
        rating: json['rating']?.toDouble(),
        isOpen: json['is_open'],
        deliveryAvailable: json['delivery_available'],
        totalProducts: json['total_products'],
        udhaarEnabled: json['udhaar_enabled'],
      );
      
      print('Successfully parsed StoreModel: ${model.name}');
      return model;
    } catch (e, stackTrace) {
      print('Error parsing StoreModel: $e');
      print('JSON data: $json');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  String get displayAddress {
    if (addressString != null) return addressString!;
    if (address != null) {
      return '${address!.street}, ${address!.city}';
    }
    return 'Address not available';
  }

  Map<String, dynamic> toJson() {
    return {
      'store_id': storeId,
      'name': name,
      'owner_name': ownerName,
      'phone': phone,
      'email': email,
      'address': address?.toJson() ?? addressString,
      'google_maps_url': googleMapsUrl,
      'settings': settings.toJson(),
      'status': status,
      if (distanceKm != null) 'distance_km': distanceKm,
      if (rating != null) 'rating': rating,
      if (isOpen != null) 'is_open': isOpen,
      if (deliveryAvailable != null) 'delivery_available': deliveryAvailable,
      if (totalProducts != null) 'total_products': totalProducts,
      if (udhaarEnabled != null) 'udhaar_enabled': udhaarEnabled,
    };
  }
}

class StoreAddress {
  final String street;
  final String city;
  final String state;
  final String pincode;
  final Coordinates? coordinates;

  StoreAddress({
    required this.street,
    required this.city,
    required this.state,
    required this.pincode,
    this.coordinates,
  });

  factory StoreAddress.fromJson(Map<String, dynamic> json) {
    try {
      return StoreAddress(
        street: json['street'] ?? '',
        city: json['city'] ?? '',
        state: json['state'] ?? '',
        pincode: json['pincode'] ?? '',
        coordinates: json['coordinates'] != null
            ? Coordinates.fromJson(json['coordinates'])
            : null,
      );
    } catch (e, stackTrace) {
      print('Error parsing StoreAddress: $e');
      print('JSON data: $json');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'pincode': pincode,
      'coordinates': coordinates?.toJson(),
    };
  }
}

class Coordinates {
  final double latitude;
  final double longitude;

  Coordinates({required this.latitude, required this.longitude});

  factory Coordinates.fromJson(dynamic json) {
    try {
      // Handle GeoJSON Point format: {type: "Point", coordinates: [lng, lat]}
      if (json is Map<String, dynamic>) {
        if (json['type'] == 'Point' && json['coordinates'] is List) {
          final coords = json['coordinates'] as List;
          return Coordinates(
            longitude: _toDouble(coords[0]),
            latitude: _toDouble(coords[1]),
          );
        }
        // Handle object format: {lat: X, lng: Y} or {latitude: X, longitude: Y}
        return Coordinates(
          latitude: _toDouble(json['lat'] ?? json['latitude'] ?? 0),
          longitude: _toDouble(json['lng'] ?? json['longitude'] ?? 0),
        );
      }
      // Handle array format: [lng, lat]
      if (json is List && json.length >= 2) {
        return Coordinates(
          longitude: _toDouble(json[0]),
          latitude: _toDouble(json[1]),
        );
      }
      // Default fallback
      return Coordinates(latitude: 0, longitude: 0);
    } catch (e, stackTrace) {
      print('Error parsing Coordinates: $e');
      print('JSON data: $json');
      print('JSON type: ${json.runtimeType}');
      print('Stack trace: $stackTrace');
      return Coordinates(latitude: 0, longitude: 0);
    }
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'type': 'Point',
      'coordinates': [longitude, latitude],
    };
  }
}

class StoreSettings {
  final double maxDiscountPercent;
  final double deliveryRadiusKm;
  final double minOrderValue;
  final bool acceptsTakeaway;
  final bool acceptsDelivery;

  StoreSettings({
    this.maxDiscountPercent = 15.0,
    this.deliveryRadiusKm = 5.0,
    this.minOrderValue = 100.0,
    this.acceptsTakeaway = true,
    this.acceptsDelivery = true,
  });

  factory StoreSettings.fromJson(Map<String, dynamic> json) {
    try {
      // Handle nested structure from backend
      final delivery = json['delivery'] as Map<String, dynamic>?;
      final takeaway = json['takeaway'] as Map<String, dynamic>?;
      final discounts = json['discounts'] as Map<String, dynamic>?;

      return StoreSettings(
        maxDiscountPercent: _toDouble(
          discounts?['max_discount_percent'] ?? 
          json['max_discount_percent'] ?? 
          15.0
        ),
        deliveryRadiusKm: _toDouble(
          delivery?['delivery_radius_km'] ?? 
          json['delivery_radius_km'] ?? 
          5.0
        ),
        minOrderValue: _toDouble(
          delivery?['min_order_value'] ?? 
          json['min_order_value'] ?? 
          100.0
        ),
        acceptsTakeaway: takeaway?['accepts_takeaway'] ?? 
                         json['accepts_takeaway'] ?? 
                         true,
        acceptsDelivery: delivery?['accepts_delivery'] ?? 
                         json['accepts_delivery'] ?? 
                         true,
      );
    } catch (e, stackTrace) {
      print('Error parsing StoreSettings: $e');
      print('JSON data: $json');
      print('Stack trace: $stackTrace');
      // Return default settings on error
      return StoreSettings();
    }
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'max_discount_percent': maxDiscountPercent,
      'delivery_radius_km': deliveryRadiusKm,
      'min_order_value': minOrderValue,
      'accepts_takeaway': acceptsTakeaway,
      'accepts_delivery': acceptsDelivery,
    };
  }
}
