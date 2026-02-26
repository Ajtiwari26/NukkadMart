import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final String? storeId;

  const ProductCard({
    super.key,
    required this.product,
    this.storeId,
  });

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final quantity = cartProvider.getItemQuantity(product.productId);
    final isInCart = quantity > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: isInCart ? AppTheme.cardDecorationAccent : AppTheme.cardDecoration,
      child: Row(
        children: [
          // Product image
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(width: 14),
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: AppTheme.heading3.copyWith(fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if (product.unit != null)
                  Text(
                    product.unit!,
                    style: AppTheme.bodySmall,
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (product.hasDiscount) ...[
                      Text(
                        '₹${product.mrp!.toStringAsFixed(0)}',
                        style: AppTheme.priceMrp,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      '₹${product.price.toStringAsFixed(0)}',
                      style: AppTheme.priceStyle,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Add / Quantity controls
          isInCart
              ? _QuantityControls(
                  quantity: quantity,
                  onIncrease: () => cartProvider.increaseQuantity(product.productId),
                  onDecrease: () => cartProvider.decreaseQuantity(product.productId),
                )
              : _AddButton(
                  onTap: () {
                    try {
                      cartProvider.addItem(product, storeId: storeId);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Cannot add items from different stores'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: Icon(
        Icons.shopping_bag_outlined,
        size: 32,
        color: AppColors.textTertiary,
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Text(
          'ADD',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _QuantityControls extends StatelessWidget {
  final double quantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const _QuantityControls({
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _controlButton(Icons.remove, onDecrease),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _controlButton(Icons.add, onIncrease),
        ],
      ),
    );
  }

  Widget _controlButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }
}
