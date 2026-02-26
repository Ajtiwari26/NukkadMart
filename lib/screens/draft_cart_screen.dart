import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui'; // For ImageFilter
import 'package:google_fonts/google_fonts.dart';
import '../config/api_config.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../providers/store_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';

import '../services/store_service.dart';

class DraftCartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> matchedItems;
  final List<Map<String, dynamic>> unmatchedItems;
  final List<Map<String, dynamic>> suggestions;
  final String storeId;

  const DraftCartScreen({
    super.key,
    required this.matchedItems,
    required this.unmatchedItems,
    required this.suggestions,
    required this.storeId,
  });

  @override
  State<DraftCartScreen> createState() => _DraftCartScreenState();
}

class _DraftCartScreenState extends State<DraftCartScreen> {
  // New Design Colors
  static const Color kPrimaryColor = Color(0xFF5bec13);
  static const Color kBackgroundLight = Color(0xFFf6f8f6);
  static const Color kBackgroundDark = Color(0xFF162210); 
  
  late List<Map<String, dynamic>> _perfectMatches;
  late List<Map<String, dynamic>> _adjustedItems;
  late List<Map<String, dynamic>> _ambiguousItems;
  late List<Map<String, dynamic>> _unresolvedItems;

  bool _isAddingToCart = false;
  final Map<String, bool> _manualLoadingMap = {}; // Tracks loading state for each manual item
  final StoreService _storeService = StoreService();

  @override
  void initState() {
    super.initState();
    _organizeItems();
  }

  void _organizeItems() {
    _perfectMatches = [];
    _adjustedItems = [];
    _ambiguousItems = [];
    _unresolvedItems = [];

    // Heuristic: If these terms are matched to something very specific, force user to verify.
    final genericTerms = ['milk', 'curd', 'paneer', 'bread', 'butter', 'cheese', 'egg', 'eggs', 'sugar', 'salt', 'rice', 'dal', 'oil'];
    final variantKeywords = ['full', 'cream', 'toned', 'double', 'cow', 'buffalo', 'slim', 'skim', 'premium', 'gold', 'taaza', 'shakti'];

    // Organize matched items
    for (var item in widget.matchedItems) {
      bool forceAmbiguous = false;
      
      // Use original_query as the raw_text if raw_text is not present
      String rawText = (item['raw_text'] ?? item['original_query'] ?? '').toString().toLowerCase();
      String productName = (item['name'] ?? '').toString().toLowerCase();
      
      // Ensure raw_text is set for display
      if (item['raw_text'] == null && item['original_query'] != null) {
        item['raw_text'] = item['original_query'];
      }
      
      // Set display_name to English translation for better UX
      if (item['search_term_english'] != null) {
        item['display_name'] = item['search_term_english'];
      } else if (item['original_query'] != null) {
        item['display_name'] = item['original_query'];
      } else {
        item['display_name'] = item['raw_text'];
      }
      
      // Remove quantity info from raw text for cleaner comparison (e.g. "milk - 3" -> "milk")
      String cleanRaw = rawText.replaceAll(RegExp(r'\s*-\s*\d+.*$'), '').trim();

      for (var term in genericTerms) {
        if (cleanRaw.contains(term)) {
           // Check if product name has variant keywords not in raw text
           for (var variant in variantKeywords) {
             if (productName.contains(variant) && !cleanRaw.contains(variant)) {
               forceAmbiguous = true;
               break;
             }
           }
           
           // Also keep length check as fallback
           if (!forceAmbiguous && productName.length > cleanRaw.length + 5) {
             forceAmbiguous = true;
           }
           break;
        }
      }

      if (item['status'] == 'ambiguous' || forceAmbiguous) {
        // Ensure alternatives exist or default to empty
        if (item['alternatives'] == null) item['alternatives'] = [];
        
        // If we forced ambiguity, ensuring we reset status for UI logic if needed
        item['status'] = 'ambiguous'; 
        _ambiguousItems.add(item);
      } else if (item['status'] == 'perfect') {
        _perfectMatches.add(item);
      } else {
        _adjustedItems.add(item);
      }
    }

    // Organize unmatched items
    for (var item in widget.unmatchedItems) {
      final text = item['raw_text'] as String?;
      if (text != null && text.length < 2) continue; 
      
      // Use a unique key for the map if possible, else use raw_text
      _unresolvedItems.add({
        ...item,
        'manual_query': text ?? '',
        'key': DateTime.now().millisecondsSinceEpoch.toString() + (text ?? ''),
      });
    }
  }

  void _resolveItem(Map<String, dynamic> originalItem, ProductModel product, {bool isAmbiguous = false}) {
    setState(() {
      // Create a resolved item map
      final resolved = {
        'product_id': product.productId,
        'name': product.name,
        'price': product.price,
        'mrp': product.mrp,
        'stock_quantity': product.stockQuantity,
        'unit': product.unit,
        'thumbnail': product.imageUrl,
        'brand': product.brand,
        'matched_quantity': originalItem['req_qty'] ?? 1, // Preserve requested qty if available
        'status': 'perfect',
        'confirmed': true,
        'line_total': (originalItem['req_qty'] ?? 1) * product.price,
      };

      _perfectMatches.add(resolved);

      if (isAmbiguous) {
        _ambiguousItems.remove(originalItem);
      } else {
        _unresolvedItems.remove(originalItem);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Added: ${product.name}")));
  }

  Future<void> _checkManualItem(Map<String, dynamic> item, String query) async {
    if (query.isEmpty) return;
    
    final itemKey = item['key'];
    setState(() {
      _manualLoadingMap[itemKey] = true;
    });
  
    try {
      // Use StoreService to search actual inventory
      print("Searching for: $query in store ${widget.storeId}");
      final results = await _storeService.searchProducts(widget.storeId, query);
      
      if (results.isNotEmpty) {
         if (results.length == 1) {
           _resolveItem(item, results.first);
         } else {
           _showSelectionDialog(item, results, isAmbiguous: false);
         }
      } else {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No items found for '$query'")));
      }
    } catch (e) {
      print("Error searching: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connection error: $e")));
    } finally {
      if (mounted) {
        setState(() {
           _manualLoadingMap.remove(itemKey);
        });
      }
    }
  }

  void _showSelectionDialog(Map<String, dynamic> originalItem, List<ProductModel> results, {required bool isAmbiguous}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kBackgroundDark,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Select Item", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: results.length,
                  itemBuilder: (ctx, index) {
                    final product = results[index];
                    return ListTile(
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(4),
                          image: (product.imageUrl?.isNotEmpty ?? false)
                            ? DecorationImage(image: NetworkImage(product.imageUrl!), fit: BoxFit.cover)
                            : null,
                        ),
                        child: (product.imageUrl?.isEmpty ?? true) ? Icon(Icons.image, color: Colors.grey) : null,
                      ),
                      title: Text(product.name, style: TextStyle(color: Colors.white)),
                      subtitle: Text("₹${product.price} • ${product.unit}", style: TextStyle(color: kPrimaryColor)),
                      onTap: () {
                        _resolveItem(originalItem, product, isAmbiguous: isAmbiguous);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAmbiguityOptions(Map<String, dynamic> item) {
    final alternatives = (item['alternatives'] as List?) ?? [];
    List<ProductModel> searchResults = [];
    
    // Start with alternatives view if available, otherwise show search
    bool showSearchView = alternatives.isEmpty;
    bool isSearching = false;
    
    TextEditingController searchController = TextEditingController();
    
    // Pre-fill search with raw text
    String initialQuery = item['raw_text'] ?? '';
    initialQuery = initialQuery.replaceAll(RegExp(r'[#@*]'), '').trim();
    searchController.text = initialQuery;

    showModalBottomSheet(
      context: context,
      backgroundColor: kBackgroundDark,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, scrollController) => Container(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Select Product",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'For: "${item['display_name'] ?? item['search_term_english'] ?? item['original_query'] ?? item['raw_text'] ?? 'Unknown'}"',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (showSearchView && searchResults.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              showSearchView = false;
                              searchResults.clear();
                              searchController.clear();
                            });
                          },
                          child: Text("Back", style: TextStyle(color: kPrimaryColor)),
                        ),
                      if (!showSearchView && alternatives.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              showSearchView = true;
                            });
                          },
                          child: Text("Search", style: TextStyle(color: kPrimaryColor)),
                        ),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  // Search Bar (only show in search view)
                  if (showSearchView) ...[
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for products...',
                        hintStyle: TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        suffixIcon: isSearching 
                          ? Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: kPrimaryColor,
                              ),
                            )
                          : IconButton(
                              icon: Icon(Icons.send, color: kPrimaryColor),
                              onPressed: () => _performSearch(
                                searchController.text,
                                setModalState,
                                (results) {
                                  searchResults = results;
                                  isSearching = false;
                                },
                              ),
                            ),
                      ),
                      style: TextStyle(color: Colors.white),
                      onSubmitted: (query) => _performSearch(
                        query,
                        setModalState,
                        (results) {
                          searchResults = results;
                          isSearching = false;
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                  
                  // Content Area
                  Expanded(
                    child: isSearching 
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: kPrimaryColor),
                              SizedBox(height: 16),
                              Text(
                                "Finding best matches...",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : showSearchView
                          ? _buildSearchResultsList(searchResults, item, ctx)
                          : _buildAlternativesList(alternatives, item, ctx, scrollController),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Future<void> _performSearch(String query, StateSetter setModalState, Function(List<ProductModel>) onDone) async {
      if (query.isEmpty) return;
      setModalState(() => setModalState(() {})); // just verify state update
      // actually we want to set isSearching = true inside the builder state
      // But we can't easily access the boolean variable reference unless we wrap it or use the setter passed.
      // simpler: just run logic
      
      try {
        final results = await _storeService.searchProducts(widget.storeId, query);
        setModalState(() {
           onDone(results);
        });
      } catch (e) {
        print("Search error: $e");
        setModalState(() {
           onDone([]);
        });
      }
  }

  Widget _buildSearchResultsList(List<ProductModel> results, Map<String, dynamic> item, BuildContext modalContext) {
    if (results.isEmpty) {
      return Center(child: Text("No items found", style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final product = results[index];
        return ListTile(
          leading: Container(
             width: 40, height: 40,
             decoration: BoxDecoration(
               color: Colors.white10,
               borderRadius: BorderRadius.circular(4),
               image: (product.imageUrl?.isNotEmpty ?? false)
                 ? DecorationImage(image: NetworkImage(product.imageUrl!), fit: BoxFit.cover)
                 : null,
             ),
             child: (product.imageUrl?.isEmpty ?? true) ? Icon(Icons.image, color: Colors.grey) : null,
          ),
          title: Text(product.name, style: TextStyle(color: Colors.white)),
          subtitle: Text("₹${product.price} • ${product.unit}", style: TextStyle(color: kPrimaryColor)),
          onTap: () {
            _resolveItem(item, product, isAmbiguous: true);
            Navigator.pop(modalContext);
          },
        );
      },
    );
  }

  Widget _buildAlternativesList(List<dynamic> alternatives, Map<String, dynamic> item, BuildContext modalContext, ScrollController scrollController) {
    if (alternatives.isEmpty) {
       return Center(
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Icon(Icons.search_off, size: 48, color: Colors.white24),
             SizedBox(height: 12),
             Text("No options available", style: TextStyle(color: Colors.white70, fontSize: 16)),
             SizedBox(height: 8),
             Text("Use the search button above to find products", style: TextStyle(color: Colors.grey, fontSize: 13)),
           ],
         ),
       );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Options (${alternatives.length})',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: alternatives.length,
            itemBuilder: (ctx, i) {
               final alt = alternatives[i];
               final name = alt['name'] ?? 'Unknown Item';
               final price = alt['price'] ?? 0;
               final thumbnail = alt['thumbnail'];
               final unit = alt['unit'] ?? '';
               final brand = alt['brand'] ?? '';
               
               return Container(
                 margin: EdgeInsets.only(bottom: 12),
                 decoration: BoxDecoration(
                   color: Colors.white.withOpacity(0.05),
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: Colors.white.withOpacity(0.1)),
                 ),
                 child: ListTile(
                   contentPadding: EdgeInsets.all(12),
                   leading: Container(
                     width: 60,
                     height: 60,
                     decoration: BoxDecoration(
                       color: Colors.white10,
                       borderRadius: BorderRadius.circular(8),
                       image: thumbnail != null 
                         ? DecorationImage(
                             image: NetworkImage(thumbnail),
                             fit: BoxFit.cover,
                             onError: (_, __) {},
                           )
                         : null,
                     ),
                     child: thumbnail == null ? Icon(Icons.shopping_bag, color: Colors.grey) : null,
                   ),
                   title: Text(
                     name,
                     style: TextStyle(
                       color: Colors.white,
                       fontWeight: FontWeight.w600,
                       fontSize: 16,
                     ),
                   ),
                   subtitle: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       if (brand.isNotEmpty) ...[
                         SizedBox(height: 4),
                         Text(
                           brand,
                           style: TextStyle(color: Colors.grey, fontSize: 12),
                         ),
                       ],
                       SizedBox(height: 4),
                       Row(
                         children: [
                           Text(
                             "₹$price",
                             style: TextStyle(
                               color: kPrimaryColor,
                               fontWeight: FontWeight.bold,
                               fontSize: 15,
                             ),
                           ),
                           if (unit.isNotEmpty) ...[
                             SizedBox(width: 8),
                             Text(
                               "• $unit",
                               style: TextStyle(color: Colors.grey, fontSize: 13),
                             ),
                           ],
                         ],
                       ),
                     ],
                   ),
                   trailing: Icon(Icons.arrow_forward_ios, color: kPrimaryColor, size: 16),
                   onTap: () {
                      final product = ProductModel(
                        productId: alt['product_id'] ?? '',
                        storeId: widget.storeId,
                        name: name,
                        category: '',
                        price: (price is int) ? price.toDouble() : (price ?? 0.0),
                        mrp: (alt['mrp'] is int) ? (alt['mrp'] as int).toDouble() : (alt['mrp'] ?? 0.0),
                        stockQuantity: 100,
                        unit: unit,
                        imageUrl: thumbnail ?? '',
                        brand: brand,
                      );
                      
                      _resolveItem(item, product, isAmbiguous: true);
                      Navigator.pop(modalContext);
                   },
                ),
               );
            },
          ),
        ),
      ],
    );
  }

  void _addToCartAndFinish() async {
    setState(() => _isAddingToCart = true);

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      
      // Add perfect matches (skip removed items)
      for (var item in _perfectMatches) {
        if (item['confirmed'] == false || item['removed'] == true) continue;
        _addItemToCart(cartProvider, item);
      }

      // Add accepted adjustments (skip rejected items)
      for (var item in _adjustedItems) {
        if (item['rejected'] == true) continue;
        _addItemToCart(cartProvider, item);
      }
      
      // Add accepted ambiguous items
      for (var item in _ambiguousItems) {
          _addItemToCart(cartProvider, item);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Items added to cart!'),
          backgroundColor: Colors.green, 
        ),
      );
      
      // Artificial delay for UX if needed, or just pop
      await Future.delayed(Duration(milliseconds: 500));
      
      if (mounted) {
        Navigator.of(context).pop(); 
        Navigator.of(context).pop(); 
      }
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error adding to cart: $e")));
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  void _addItemToCart(CartProvider provider, Map<String, dynamic> item) {
    final product = ProductModel(
      productId: item['product_id'],
      storeId: widget.storeId,
      name: item['name'],
      category: '', 
      price: (item['price'] ?? 0).toDouble(),
      mrp: (item['mrp'] ?? 0).toDouble(),
      stockQuantity: (item['stock_quantity'] ?? 0).toDouble(),
      unit: item['unit'],
      imageUrl: item['thumbnail'],
      brand: item['brand'],
    );
    
    final qty = (item['matched_quantity'] ?? 1).toDouble();
    provider.addItem(product, storeId: widget.storeId, quantity: qty);
  }

  double get _totalEstimated {
    double total = 0;
    for (var item in _perfectMatches) {
      if (item['removed'] != true) {
        total += (item['line_total'] ?? 0);
      }
    }
    for (var item in _adjustedItems) {
       if (item['rejected'] != true) total += (item['line_total'] ?? 0);
    }
    for (var item in _ambiguousItems) total += (item['line_total'] ?? 0);
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = _perfectMatches.where((i) => i['removed'] != true).length + 
                       _adjustedItems.where((i) => i['rejected'] != true).length + 
                       _ambiguousItems.length;

    return Scaffold(
      backgroundColor: kBackgroundDark, // DARK THEME
      extendBody: true, 
      appBar: AppBar(
        title: Text(
          'Review Scanned Items',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white, // White items for dark theme
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: kBackgroundDark.withOpacity(0.8),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent, 
            ),
            child: Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          )
        ],
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: kPrimaryColor.withOpacity(0.1),
            height: 1.0,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Scrollable Content
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120), 
            children: [
              // Needs Your Help (Priority)
              if (_unresolvedItems.isNotEmpty) ...[
                _buildSectionTitle('Needs Your Help', Icons.error, Colors.red),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: _unresolvedItems.map((item) => _buildUnresolvedItem(item)).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Clarification Needed
              if (_ambiguousItems.isNotEmpty) ...[
                _buildSectionTitle('Clarification Needed', Icons.help_center, Colors.blue),
                ..._ambiguousItems.map((item) => _buildAmbiguousItem(item)),
                const SizedBox(height: 24),
              ],

              // Smart Adjustments
              if (_adjustedItems.isNotEmpty) ...[
                _buildSectionTitle('Smart Adjustments', Icons.auto_fix_high, Colors.orange),
                ..._adjustedItems.map((item) => _buildAdjustedItem(item)),
                const SizedBox(height: 24),
              ],

              // Perfect Matches
              if (_perfectMatches.isNotEmpty) ...[
                 _buildSectionTitle('Perfect Matches (${_perfectMatches.length})', Icons.check_circle, kPrimaryColor),
                 Column(
                   children: _perfectMatches.map((item) => _buildPerfectMatchItem(item)).toList(),
                 ),
                 const SizedBox(height: 24),
              ],
            ],
          ),

          // Fixed Bottom Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kBackgroundDark.withOpacity(0.95), // Dark background
                    border: Border(top: BorderSide(color: kPrimaryColor.withOpacity(0.2))),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TOTAL ESTIMATED',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                Text(
                                  '₹${_totalEstimated.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.white, // White text
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: kPrimaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$totalItems ITEMS READY',
                                style: TextStyle(
                                  color: kPrimaryColor, // Green text
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: (totalItems > 0 && !_isAddingToCart) ? _addToCartAndFinish : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: Colors.black, // Text color matches design (black on green)
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              shadowColor: kPrimaryColor.withOpacity(0.3),
                            ),
                            child: _isAddingToCart 
                              ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Add $totalItems Items to Cart',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.shopping_cart),
                                  ],
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white, // White text
            ),
          ),
        ],
      ),
    );
  }

  // --- Item Builders ---

  Widget _buildUnresolvedItem(Map<String, dynamic> item) {
    final TextEditingController controller = TextEditingController(text: item['manual_query']);
    final isLoading = _manualLoadingMap[item['key']] == true;
    final rawText = item['raw_text'] ?? 'Unknown';
    // Check if rawText is likely garbage (very short or mostly special chars) to label it appropriately
    final isGarbage = rawText.length < 3 || rawText.contains(RegExp(r'[^a-zA-Z0-9\s\u0900-\u097F]')); // Simple check, includes Hindi range

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.broken_image, color: Colors.white54),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI IDENTIFICATION FAILED',
                      style: TextStyle(
                        color: Colors.red[400],
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      isGarbage ? 'Unrecognized text from list' : 'Could not match: "$rawText"',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontStyle: isGarbage ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                    if (isGarbage)
                       Padding(
                         padding: const EdgeInsets.only(top: 2.0),
                         child: Text(
                           '"$rawText"',
                           style: TextStyle(
                             color: Colors.white30,
                             fontSize: 10,
                             fontFamily: 'Courier', // Monospace for raw garbage
                           ),
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                         ),
                       ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'PLEASE ENTER ITEM NAME MANUALLY',
            style: TextStyle(
              color: kPrimaryColor, // Highlight instruction
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Type item name...',
                      hintStyle: TextStyle(color: Colors.white30),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      isDense: true,
                    ),
                    style: TextStyle(fontSize: 14, color: Colors.white),
                    onSubmitted: (value) => _checkManualItem(item, value),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Container(
                 decoration: BoxDecoration(
                   color: kPrimaryColor,
                   borderRadius: BorderRadius.circular(8),
                 ),
                 child: IconButton(
                   icon: isLoading 
                     ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) 
                     : Icon(Icons.check, size: 20, color: Colors.black),
                   onPressed: isLoading ? null : () => _checkManualItem(item, controller.text),
                   constraints: BoxConstraints(minWidth: 44, minHeight: 44),
                 ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmbiguousItem(Map<String, dynamic> item) {
    final alternatives = (item['alternatives'] as List?) ?? [];
    final hasOptions = alternatives.isNotEmpty;
    
    // Use the AI-extracted English name from the list (search_term_english)
    // This is what the user wrote in their list, translated to English
    String displayName = item['search_term_english'] ?? item['name'] ?? 'Unknown Item';
    
    // Clean up the display name (remove quantity info if any)
    displayName = displayName.replaceAll(RegExp(r'\s*-\s*\d+.*'), '').trim();
    
    // Get the original text for context (what user wrote)
    String originalText = item['original_query'] ?? item['raw_text'] ?? '';
    originalText = originalText.replaceAll(RegExp(r'\s*-\s*\d+.*'), '').trim();
    
    return GestureDetector(
      onTap: () => _showAmbiguityOptions(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.help_outline, color: Colors.blue[300], size: 40),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show the English translation or cleaned name
                  Text(
                    displayName, 
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  // Show how many options are available
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      hasOptions 
                        ? '${alternatives.length} options available'
                        : 'Tap to search options',
                      style: TextStyle(
                        color: Colors.blue[300],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.touch_app, color: kPrimaryColor, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Tap to select product',
                        style: TextStyle(
                          color: kPrimaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.blue[300], size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustedItem(Map<String, dynamic> item) {
    final isRejected = item['rejected'] == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRejected ? Colors.grey.withOpacity(0.05) : Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
             color: isRejected ? Colors.grey.withOpacity(0.2) : Colors.orange.withOpacity(0.2)
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                   image: item['thumbnail'] != null 
                      ? DecorationImage(image: NetworkImage(item['thumbnail']), fit: BoxFit.cover)
                      : null,
                ),
                child: item['thumbnail'] == null ? Icon(Icons.image, color: Colors.white54) : null,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(item['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white))),
                        Text(
                          '₹${item['price']}',
                          style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        border: Border.all(color: Colors.orange.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info, size: 14, color: Colors.orange),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              (item['modification_reason'] ?? 'Adjusted').toUpperCase(),
                              style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // Action Buttons (Undo/Remove)
          Align(
            alignment: Alignment.centerRight,
            child: isRejected 
              ? TextButton.icon(
                  onPressed: () => setState(() => item['rejected'] = false),
                  icon: Icon(Icons.undo, size: 16, color: kPrimaryColor),
                  label: Text('Undo', style: TextStyle(color: kPrimaryColor)),
                )
              : TextButton.icon(
                  onPressed: () => setState(() => item['rejected'] = true),
                  icon: Icon(Icons.close, size: 16, color: Colors.red),
                  label: Text('Remove', style: TextStyle(color: Colors.red)),
                ),
          )
        ],
      ),
    );
  }

  Widget _buildPerfectMatchItem(Map<String, dynamic> item) {
    final quantity = (item['matched_quantity'] ?? 1).toInt();
    final isRemoved = item['removed'] == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRemoved 
            ? Colors.grey.withOpacity(0.05) 
            : kPrimaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRemoved 
              ? Colors.grey.withOpacity(0.2) 
              : kPrimaryColor.withOpacity(0.1)
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
              image: item['thumbnail'] != null 
                  ? DecorationImage(image: NetworkImage(item['thumbnail']), fit: BoxFit.cover)
                  : null,
            ),
            child: item['thumbnail'] == null ? Icon(Icons.image, size: 20, color: Colors.white54) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.w600, 
                    fontSize: 15, 
                    color: isRemoved ? Colors.grey : Colors.white,
                    decoration: isRemoved ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '₹${item['price']}',
                      style: TextStyle(
                        color: isRemoved ? Colors.grey : kPrimaryColor, 
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (item['unit'] != null) ...[
                      Text(
                        ' • ${item['unit']}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Compact quantity controls and delete button on the right
          if (!isRemoved) ...[
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Compact counter with editable text field
                Container(
                  width: 90,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Minus button
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (quantity > 1) {
                              item['matched_quantity'] = quantity - 1;
                              item['line_total'] = item['price'] * item['matched_quantity'];
                            }
                          });
                        },
                        child: Container(
                          width: 28,
                          height: 36,
                          alignment: Alignment.center,
                          child: Icon(Icons.remove, size: 16, color: Colors.white),
                        ),
                      ),
                      // Editable quantity text field
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(text: '$quantity')..selection = TextSelection.fromPosition(TextPosition(offset: '$quantity'.length)),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          onSubmitted: (value) {
                            final newQty = int.tryParse(value);
                            if (newQty != null && newQty > 0) {
                              setState(() {
                                item['matched_quantity'] = newQty;
                                item['line_total'] = item['price'] * newQty;
                              });
                            }
                          },
                        ),
                      ),
                      // Plus button
                      InkWell(
                        onTap: () {
                          setState(() {
                            item['matched_quantity'] = quantity + 1;
                            item['line_total'] = item['price'] * item['matched_quantity'];
                          });
                        },
                        child: Container(
                          width: 28,
                          height: 36,
                          alignment: Alignment.center,
                          child: Icon(Icons.add, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Delete/bin icon
                InkWell(
                  onTap: () {
                    setState(() {
                      item['removed'] = true;
                    });
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Undo button when removed
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                setState(() {
                  item['removed'] = false;
                });
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.undo, size: 18, color: kPrimaryColor),
              ),
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildChip(String label, {required bool selected, required Color color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? color.withOpacity(0.1) : Colors.transparent,
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

