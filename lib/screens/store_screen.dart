import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/store_provider.dart';
import '../providers/cart_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import '../widgets/product_card.dart';
import '../widgets/cart_bottom_bar.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  String _selectedCategory = 'All Items';
  bool _isDelivery = true;
  bool _initialized = false;
  final _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final storeId = ModalRoute.of(context)?.settings.arguments as String?;
      if (storeId != null) {
        Provider.of<StoreProvider>(context, listen: false).selectStore(storeId);
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = Provider.of<StoreProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final store = storeProvider.selectedStore;

    final categories = ['All Items', ...storeProvider.categories];
    final filteredProducts = _selectedCategory == 'All Items'
        ? storeProvider.products
        : storeProvider.getProductsByCategory(_selectedCategory);

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
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.storefront_rounded,
                          size: 22,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            store?.name ?? 'Store',
                            style: AppTheme.heading3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Search — Coming Soon!'), backgroundColor: AppColors.primary),
                      );
                    },
                    icon: Icon(
                      Icons.search_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Delivery / Takeaway Toggle
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isDelivery = true),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _isDelivery
                                ? AppColors.surfaceVariant
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Delivery',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  _isDelivery ? FontWeight.w600 : FontWeight.w400,
                              color: _isDelivery
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isDelivery = false),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: !_isDelivery
                                ? AppColors.surfaceVariant
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Takeaway',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  !_isDelivery ? FontWeight.w600 : FontWeight.w400,
                              color: !_isDelivery
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Store info
            if (store != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${store.distanceKm?.toStringAsFixed(1) ?? "--"} km away • ${store.displayAddress}',
                        style: AppTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      store.rating?.toStringAsFixed(1) ?? '--',
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            // Category pills
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = cat == _selectedCategory;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                              ? null
                              : Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? AppColors.buttonText
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Products Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedCategory == 'All Items'
                        ? 'Featured Products'
                        : _selectedCategory,
                    style: AppTheme.heading3.copyWith(fontSize: 16),
                  ),
                  if (_selectedCategory == 'All Items')
                    Text(
                      'SEE ALL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                ],
              ),
            ),

            // Products list
            Expanded(
              child: storeProvider.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 48,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No products found',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredProducts.length + 1, // +1 for AI banner
                          itemBuilder: (context, index) {
                            if (index == filteredProducts.length) {
                              // AI Assistant banner at bottom
                              return _AiBanner(
                                onTap: () =>
                                    Navigator.pushNamed(context, '/ai-scanner'),
                              );
                            }
                            return ProductCard(
                              product: filteredProducts[index],
                              storeId: store?.storeId,
                            );
                          },
                        ),
            ),

            // Cart bottom bar
            const CartBottomBar(),
          ],
        ),
      ),
    );
  }
}

class _AiBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _AiBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.surface,
              AppColors.surfaceVariant,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI ASSISTANT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Have a handwritten list?',
                    style: AppTheme.heading3.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scan it instantly to add items to cart.',
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.document_scanner_outlined,
              size: 40,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
