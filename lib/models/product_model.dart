class ProductModel {
  final String productId;
  final String storeId;
  final String name;
  final String category;
  final String? brand;
  final double price;
  final double? mrp;
  final String? unit;
  final double stockQuantity; // Changed from int to double
  final String? imageUrl;
  final List<String>? tags;

  ProductModel({
    required this.productId,
    required this.storeId,
    required this.name,
    required this.category,
    this.brand,
    required this.price,
    this.mrp,
    this.unit,
    required this.stockQuantity,
    this.imageUrl,
    this.tags,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      productId: json['product_id'] ?? '',
      storeId: json['store_id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      brand: json['brand'],
      price: (json['price'] ?? 0).toDouble(),
      mrp: json['mrp'] != null ? (json['mrp']).toDouble() : null,
      unit: json['unit'],
      stockQuantity: (json['stock_quantity'] ?? 0).toDouble(), // Ensure double
      imageUrl: json['image_url'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'store_id': storeId,
      'name': name,
      'category': category,
      'brand': brand,
      'price': price,
      'mrp': mrp,
      'unit': unit,
      'stock_quantity': stockQuantity,
      'image_url': imageUrl,
      'tags': tags,
    };
  }

  bool get hasDiscount => mrp != null && mrp! > price;
  
  double get discountPercent {
    if (!hasDiscount) return 0;
    return ((mrp! - price) / mrp!) * 100;
  }

  bool get inStock => stockQuantity > 0;
}
