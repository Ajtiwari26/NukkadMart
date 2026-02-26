import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';

class OrderDeliveredScreen extends StatelessWidget {
  const OrderDeliveredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Accept optional arguments for dynamic data
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final storeName = args?['storeName'] ?? 'Store';
    final orderId = args?['orderId'] ?? '';
    final amount = args?['amount'] ?? 0.0;
    final deliveryTime = args?['deliveryTime'] ?? '~25 min';

    final displayOrderId = orderId.isNotEmpty
        ? '#${orderId.length > 6 ? orderId.substring(orderId.length - 6).toUpperCase() : orderId.toUpperCase()}'
        : '#------';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Checkmark
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded, size: 64, color: AppColors.success),
              ),
              const SizedBox(height: 24),
              Text('Order Delivered!', style: AppTheme.heading1),
              const SizedBox(height: 8),
              Text('Your order has been delivered successfully', style: AppTheme.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              // Summary card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.cardDecoration,
                child: Column(
                  children: [
                    _SummaryRow('Store', storeName),
                    _SummaryRow('Order No.', displayOrderId),
                    _SummaryRow('Delivery Time', deliveryTime),
                    const Divider(height: 24),
                    _SummaryRow('Amount Paid', '₹${(amount as num).toStringAsFixed(2)}', isBold: true),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              // Buttons
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/order-rating'),
                  style: AppTheme.primaryButton,
                  child: Text('Review Order', style: AppTheme.button),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 56,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false),
                  style: AppTheme.outlineButton,
                  child: Text('Go to Home', style: AppTheme.button.copyWith(color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final bool isBold;
  const _SummaryRow(this.label, this.value, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodyMedium.copyWith(color: AppColors.textSecondary)),
          Text(value, style: isBold ? AppTheme.priceStyle.copyWith(fontSize: 16) : AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
