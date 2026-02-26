class OrderModel {
  final String orderId;
  final String userId;
  final String storeId;
  final String? storeName;
  final List<OrderItem> items;
  final OrderPricing pricing;
  final String fulfillmentType;
  final DeliveryAddress? deliveryAddress;
  final String status;
  final String? paymentMethod;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.storeId,
    this.storeName,
    required this.items,
    required this.pricing,
    required this.fulfillmentType,
    this.deliveryAddress,
    required this.status,
    this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json['order_id'] ?? '',
      userId: json['user_id'] ?? '',
      storeId: json['store_id'] ?? '',
      storeName: json['store_name'],
      items: (json['items'] as List?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      pricing: OrderPricing.fromJson(json['pricing'] ?? {}),
      fulfillmentType: json['fulfillment_type'] ?? 'DELIVERY',
      deliveryAddress: json['delivery_address'] != null
          ? DeliveryAddress.fromJson(json['delivery_address'])
          : null,
      status: _normalizeStatus(json['status']),
      paymentMethod: json['payment_method'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  static String _normalizeStatus(String? status) {
    if (status == null) return 'created';
    final lower = status.toLowerCase();
    if (lower == 'picked_up') return 'delivered';
    return lower;
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'user_id': userId,
      'store_id': storeId,
      'store_name': storeName,
      'items': items.map((item) => item.toJson()).toList(),
      'pricing': pricing.toJson(),
      'fulfillment_type': fulfillmentType,
      'delivery_address': deliveryAddress?.toJson(),
      'status': status,
      'payment_method': paymentMethod,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class OrderItem {
  final String productId;
  final String name;
  final double quantity;
  final double unitPrice;
  final double subtotal;

  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'] ?? '',
      name: json['name'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'name': name,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
    };
  }
}

class OrderPricing {
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double tax;
  final double total;

  OrderPricing({
    required this.subtotal,
    this.discount = 0,
    this.deliveryFee = 0,
    this.tax = 0,
    required this.total,
  });

  factory OrderPricing.fromJson(Map<String, dynamic> json) {
    return OrderPricing(
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      deliveryFee: (json['delivery_fee'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subtotal': subtotal,
      'discount': discount,
      'delivery_fee': deliveryFee,
      'tax': tax,
      'total': total,
    };
  }
}

class DeliveryAddress {
  final String name;
  final String street;
  final String? landmark;
  final String city;
  final String pincode;
  final String phone;

  DeliveryAddress({
    required this.name,
    required this.street,
    this.landmark,
    required this.city,
    required this.pincode,
    required this.phone,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      name: json['name'] ?? '',
      street: json['street'] ?? '',
      landmark: json['landmark'],
      city: json['city'] ?? '',
      pincode: json['pincode'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'street': street,
      'landmark': landmark,
      'city': city,
      'pincode': pincode,
      'phone': phone,
    };
  }
}
