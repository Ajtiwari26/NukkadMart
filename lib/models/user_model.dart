class AddressModel {
  final String id;
  final String label; // Home, Work, Other
  final String house;
  final String apartment;
  final String landmark;
  final double lat;
  final double lng;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.label,
    required this.house,
    required this.apartment,
    required this.landmark,
    required this.lat,
    required this.lng,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      label: json['label'] ?? 'Home',
      house: json['house'] ?? '',
      apartment: json['apartment'] ?? '',
      landmark: json['landmark'] ?? '',
      lat: (json['lat'] ?? 23.2599).toDouble(),
      lng: (json['lng'] ?? 77.4126).toDouble(),
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'house': house,
      'apartment': apartment,
      'landmark': landmark,
      'lat': lat,
      'lng': lng,
      'is_default': isDefault,
    };
  }

  String get fullAddress => 
      '$house, $apartment${landmark.isNotEmpty ? ', Near $landmark' : ''}';
}

class UserModel {
  final String userId;
  final String name;
  final String phone;
  final String? email;
  final double totalPurchases;
  final int totalOrders;
  final DateTime? createdAt;
  final List<AddressModel> addresses;

  UserModel({
    required this.userId,
    required this.name,
    required this.phone,
    this.email,
    this.totalPurchases = 0.0,
    this.totalOrders = 0,
    this.createdAt,
    this.addresses = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    var addrList = <AddressModel>[];
    if (json['addresses'] != null) {
      addrList = (json['addresses'] as List)
          .map((i) => AddressModel.fromJson(i))
          .toList();
    }

    return UserModel(
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      totalPurchases: (json['total_purchases'] ?? 0).toDouble(),
      totalOrders: json['total_orders'] ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      addresses: addrList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'phone': phone,
      'email': email,
      'total_purchases': totalPurchases,
      'total_orders': totalOrders,
      'created_at': createdAt?.toIso8601String(),
      'addresses': addresses.map((e) => e.toJson()).toList(),
    };
  }
}
