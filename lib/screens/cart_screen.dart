import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    if (cartProvider.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          ),
          title: Text('Your Cart', style: AppTheme.heading3),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_cart_outlined,
                  size: 64, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text('Your cart is empty',
                  style: AppTheme.heading3.copyWith(
                    color: AppColors.textSecondary,
                  )),
              const SizedBox(height: 8),
              Text('Start adding items from a store nearby',
                  style: AppTheme.bodySmall),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, '/home', (route) => false),
                style: AppTheme.primaryButton,
                child: Text('Browse Stores', style: AppTheme.button),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_rounded,
                        color: AppColors.textPrimary),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Cart', style: AppTheme.heading3),
                        if (cartProvider.storeId != null)
                          Text(
                            '${cartProvider.itemCount} items',
                            style: AppTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      cartProvider.clearCart();
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Cart Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Items
                  ...cartProvider.items.map((item) => _CartItemTile(item: item)),

                  const SizedBox(height: 16),

                  // Delivery / Takeaway Toggle
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fulfillment', style: AppTheme.heading3),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => cartProvider.setFulfillmentType('DELIVERY'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: cartProvider.isDelivery
                                        ? AppColors.primary
                                        : AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: cartProvider.isDelivery
                                          ? AppColors.primary
                                          : AppColors.border,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.delivery_dining_rounded,
                                        size: 20,
                                        color: cartProvider.isDelivery
                                            ? AppColors.buttonText
                                            : AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Delivery',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: cartProvider.isDelivery
                                              ? AppColors.buttonText
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => cartProvider.setFulfillmentType('TAKEAWAY'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: !cartProvider.isDelivery
                                        ? AppColors.primary
                                        : AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: !cartProvider.isDelivery
                                          ? AppColors.primary
                                          : AppColors.border,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.shopping_bag_outlined,
                                        size: 20,
                                        color: !cartProvider.isDelivery
                                            ? AppColors.buttonText
                                            : AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Takeaway',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: !cartProvider.isDelivery
                                              ? AppColors.buttonText
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (cartProvider.isDelivery && cartProvider.subtotal >= 199)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              children: [
                                Icon(Icons.local_offer_rounded, size: 14, color: AppColors.success),
                                const SizedBox(width: 6),
                                Text(
                                  'Free delivery on this order!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Recommendations
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'You might also like',
                              style: AppTheme.heading3.copyWith(fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Based on your cart items',
                          style: AppTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bill Details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bill Details', style: AppTheme.heading3),
                        const SizedBox(height: 12),
                        _BillRow(label: 'Subtotal', value: cartProvider.subtotal),
                        // Only show delivery and handling charges for delivery orders
                        if (cartProvider.isDelivery) ...[
                          _BillRow(
                            label: 'Delivery Charges',
                            value: cartProvider.deliveryFee,
                            suffix: cartProvider.deliveryFee == 0 ? 'FREE' : null,
                          ),
                          _BillRow(label: 'Handling Fee', value: cartProvider.tax),
                        ],
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(),
                        ),
                        _BillRow(
                          label: 'Total',
                          value: cartProvider.isDelivery 
                              ? cartProvider.total 
                              : cartProvider.subtotal, // For takeaway, total = subtotal
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Payment Method
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.cardDecoration,
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.payment_rounded,
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Payment Method',
                                  style: AppTheme.bodySmall.copyWith(
                                      fontWeight: FontWeight.w500)),
                              Text('Pay via UPI',
                                  style: AppTheme.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Text(
                          'Change',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),

            // Bottom Bar
            _CheckoutBar(cartProvider: cartProvider),
          ],
        ),
      ),
    );
  }
}

class _CartItemTile extends StatefulWidget {
  final dynamic item; // CartItemModel

  const _CartItemTile({required this.item});

  @override
  State<_CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends State<_CartItemTile> {
  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final quantity = widget.item.quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.cardDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: widget.item.product.imageUrl != null &&
                    widget.item.product.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      widget.item.product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.shopping_bag_outlined,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  )
                : Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColors.textTertiary,
                  ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.product.name,
                  style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.item.product.unit != null)
                  Text(widget.item.product.unit!, style: AppTheme.bodySmall),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (widget.item.product.hasDiscount) ...[
                      Text(
                        '₹${widget.item.product.mrp!.toStringAsFixed(0)}',
                        style: AppTheme.priceMrp.copyWith(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      '₹${widget.item.product.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Compact quantity controls and delete button on the right
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Compact counter with editable text field
              Container(
                width: 90,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Minus button
                    InkWell(
                      onTap: () => cartProvider.decreaseQuantity(widget.item.product.productId),
                      child: Container(
                        width: 28,
                        height: 36,
                        alignment: Alignment.center,
                        child: Icon(Icons.remove, size: 16, color: AppColors.primary),
                      ),
                    ),
                    // Editable quantity text field
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(
                          text: quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString()
                        )..selection = TextSelection.fromPosition(
                          TextPosition(offset: (quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString()).length)
                        ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onSubmitted: (value) {
                          final newQty = double.tryParse(value);
                          if (newQty != null && newQty > 0) {
                            // Update quantity by removing and adding back
                            final currentQty = widget.item.quantity;
                            if (newQty > currentQty) {
                              for (int i = 0; i < (newQty - currentQty); i++) {
                                cartProvider.increaseQuantity(widget.item.product.productId);
                              }
                            } else if (newQty < currentQty) {
                              for (int i = 0; i < (currentQty - newQty); i++) {
                                cartProvider.decreaseQuantity(widget.item.product.productId);
                              }
                            }
                          }
                        },
                      ),
                    ),
                    // Plus button
                    InkWell(
                      onTap: () => cartProvider.increaseQuantity(widget.item.product.productId),
                      child: Container(
                        width: 28,
                        height: 36,
                        alignment: Alignment.center,
                        child: Icon(Icons.add, size: 16, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Delete/bin icon
              InkWell(
                onTap: () => cartProvider.removeItem(widget.item.product.productId),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isTotal;
  final String? suffix;

  const _BillRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w700)
                : AppTheme.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          Row(
            children: [
              if (suffix != null)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    suffix!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ),
              Text(
                '₹${value.toStringAsFixed(2)}',
                style: isTotal
                    ? AppTheme.priceStyle
                    : AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  final CartProvider cartProvider;

  const _CheckoutBar({required this.cartProvider});

  @override
  Widget build(BuildContext context) {
    // For takeaway, total = subtotal (no delivery or handling charges)
    final displayTotal = cartProvider.isDelivery 
        ? cartProvider.total 
        : cartProvider.subtotal;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TOTAL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '₹${displayTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _placeOrder(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Place Order',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.buttonText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded,
                        size: 20, color: AppColors.buttonText),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrder(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login first'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text('Placing order...', style: AppTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );

    try {
      final orderService = OrderService();
      final order = await orderService.createOrder(
        userId: authProvider.user!.userId,
        storeId: cartProvider.storeId!,
        items: cartProvider.items,
        fulfillmentType: cartProvider.fulfillmentType,
      );

      cartProvider.clearCart();

      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        Navigator.pushReplacementNamed(
          context,
          '/order-tracking',
          arguments: order.orderId,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
