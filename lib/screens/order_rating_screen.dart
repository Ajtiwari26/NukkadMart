import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';

class OrderRatingScreen extends StatefulWidget {
  const OrderRatingScreen({super.key});

  @override
  State<OrderRatingScreen> createState() => _OrderRatingScreenState();
}

class _OrderRatingScreenState extends State<OrderRatingScreen> {
  int _shopRating = 0;
  int _deliveryRating = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary)),
                  Expanded(child: Text('Rate your Order', style: AppTheme.heading3)),
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('Skip', style: TextStyle(color: AppColors.textSecondary))),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 18, color: AppColors.success),
                          const SizedBox(width: 8),
                          Text('Delivered on time', style: AppTheme.bodyMedium.copyWith(color: AppColors.success, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Rate the shop
                    Text('Rate the Shop', style: AppTheme.heading3),
                    const SizedBox(height: 4),
                    Text('How was the product quality?', style: AppTheme.bodySmall),
                    const SizedBox(height: 16),
                    _StarRating(rating: _shopRating, onChanged: (r) => setState(() => _shopRating = r)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _commentController,
                      maxLines: 3,
                      style: AppTheme.bodyMedium,
                      decoration: InputDecoration(hintText: 'Add a comment (optional)'),
                    ),
                    const SizedBox(height: 32),
                    // Rate delivery
                    Text('Rate the Delivery', style: AppTheme.heading3),
                    const SizedBox(height: 4),
                    Text('How was the delivery experience?', style: AppTheme.bodySmall),
                    const SizedBox(height: 16),
                    _StarRating(rating: _deliveryRating, onChanged: (r) => setState(() => _deliveryRating = r)),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
                  },
                  style: AppTheme.primaryButton,
                  child: Text('Submit Feedback', style: AppTheme.button),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;
  const _StarRating({required this.rating, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () => onChanged(index + 1),
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 40,
              color: index < rating ? Colors.amber : AppColors.textTertiary,
            ),
          ),
        );
      }),
    );
  }
}
