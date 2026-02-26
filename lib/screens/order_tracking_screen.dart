import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models/order_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final orderId = ModalRoute.of(context)?.settings.arguments as String?;
      if (orderId != null) {
        Provider.of<OrderProvider>(context, listen: false).loadOrder(orderId);
      }
      _initialized = true;
    }
  }

  int _getStatusStep(String status) {
    switch (status) {
      case 'confirmed':
      case 'preparing':
        return 0;
      case 'out_for_delivery':
        return 1;
      case 'delivered':
        return 2;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final order = orderProvider.currentOrder;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                  ),
                  Expanded(child: Text('Track Order', style: AppTheme.heading3)),
                  if (order != null)
                    GestureDetector(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Order Options — Coming Soon!'), backgroundColor: AppColors.primary),
                      ),
                      child: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),

            // Map placeholder
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.map_outlined, size: 80, color: AppColors.textTertiary.withOpacity(0.3)),
                    // ETA badge
                    Positioned(
                      top: 16, right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary, borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time, size: 16, color: AppColors.buttonText),
                            const SizedBox(width: 6),
                            Text('12 min', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.buttonText)),
                          ],
                        ),
                      ),
                    ),
                    // Route markers
                    Positioned(
                      bottom: 40, left: 40,
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: Icon(Icons.storefront_rounded, size: 18, color: AppColors.buttonText),
                      ),
                    ),
                    Positioned(
                      top: 60, right: 60,
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                        child: Icon(Icons.delivery_dining, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Bottom panel
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: AppColors.border),
                ),
                child: orderProvider.isLoading
                    ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : order == null
                        ? Center(child: Text('Order not found', style: AppTheme.bodyMedium))
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Drag handle
                                Center(
                                  child: Container(
                                    width: 40, height: 4,
                                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Status title
                                Text(
                                  order.status == 'delivered' ? 'Order Delivered!' : 'Order is on the way',
                                  style: AppTheme.heading2,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  order.status == 'delivered' ? 'Your order has been delivered successfully' : 'Arriving in ~12 minutes',
                                  style: AppTheme.bodySmall.copyWith(fontSize: 14),
                                ),

                                const SizedBox(height: 20),

                                // Progress bar
                                _ProgressBar(currentStep: _getStatusStep(order.status)),

                                const SizedBox(height: 20),

                                // Rider info
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: AppColors.primary.withOpacity(0.2),
                                        child: Icon(Icons.person_rounded, color: AppColors.primary),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Delivery Partner', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                            Row(children: [
                                              Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                                              const SizedBox(width: 4),
                                              Text('4.8', style: AppTheme.bodySmall),
                                              Text(' • Bike', style: AppTheme.bodySmall),
                                            ]),
                                          ],
                                        ),
                                      ),
                                      _circleButton(Icons.call_rounded, Colors.green, 'Call Delivery Partner'),
                                      const SizedBox(width: 8),
                                      _circleButton(Icons.chat_rounded, Colors.blue, 'Chat with Delivery Partner'),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Order summary
                                Text('Order Summary', style: AppTheme.heading3.copyWith(fontSize: 15)),
                                const SizedBox(height: 8),
                                Text('Order #${order.orderId.length > 6 ? order.orderId.substring(order.orderId.length - 6) : order.orderId}', style: AppTheme.bodySmall),
                                Text('${order.items.length} items • ₹${order.pricing.total.toStringAsFixed(2)}', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, Color color, String label) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label — Coming Soon!'), backgroundColor: color),
      ),
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int currentStep;
  const _ProgressBar({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = ['Prepared', 'On the Way', 'Delivered'];
    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final stepIndex = index ~/ 2;
          return Expanded(
            child: Container(
              height: 3,
              color: stepIndex < currentStep ? AppColors.primary : AppColors.border,
            ),
          );
        }
        final stepIndex = index ~/ 2;
        final isCompleted = stepIndex <= currentStep;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.primary : AppColors.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(color: isCompleted ? AppColors.primary : AppColors.border, width: 2),
              ),
              child: isCompleted ? Icon(Icons.check, size: 14, color: AppColors.buttonText) : null,
            ),
            const SizedBox(height: 6),
            Text(steps[stepIndex], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isCompleted ? AppColors.primary : AppColors.textTertiary)),
          ],
        );
      }),
    );
  }
}
