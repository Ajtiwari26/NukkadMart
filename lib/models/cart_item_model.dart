import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  double quantity;

  CartItemModel({
    required this.product,
    this.quantity = 1.0,
  });

  double get subtotal => product.price * quantity;

  // For local storage (includes full product)
  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
    };
  }

  // For API requests (only product_id and quantity)
  Map<String, dynamic> toOrderJson() {
    return {
      'product_id': product.productId,
      'quantity': quantity,
    };
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      product: ProductModel.fromJson(json['product']),
      quantity: (json['quantity'] as num).toDouble(),
    );
  }

  CartItemModel copyWith({double? quantity}) {
    return CartItemModel(
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }
}
