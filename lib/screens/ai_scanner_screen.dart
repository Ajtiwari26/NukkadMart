import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../models/product_model.dart';
import '../providers/store_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import 'draft_cart_screen.dart';

class AiScannerScreen extends StatefulWidget {
  const AiScannerScreen({super.key});

  @override
  State<AiScannerScreen> createState() => _AiScannerScreenState();
}

class _AiScannerScreenState extends State<AiScannerScreen> {
  File? _capturedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  String? _errorMessage;
  String? _selectedStoreId;
  String? _selectedStoreName;

  /// Show store picker before scanning (like voice cart)
  void _showStorePicker({required VoidCallback onStoreSelected}) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isDemoMode = authProvider.isDemoMode;

    if (isDemoMode) {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          final demoStores = [
            {'id': 'DEMO_STORE_1', 'name': 'TestShop 1 - Kirana Corner'},
            {'id': 'DEMO_STORE_2', 'name': 'TestShop 2 - Daily Needs'},
            {'id': 'DEMO_STORE_3', 'name': 'TestShop 3 - Fresh Mart'},
          ];
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select a Shop', style: AppTheme.heading3),
                const SizedBox(height: 4),
                Text('Choose which shop to scan your list for',
                    style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                ...demoStores.map((store) => ListTile(
                  leading: const Icon(Icons.storefront_rounded, color: AppColors.primary),
                  title: Text(store['name']!, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _selectedStoreId = store['id'];
                      _selectedStoreName = store['name'];
                    });
                    onStoreSelected();
                  },
                )),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );
    } else {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      final stores = storeProvider.stores;

      if (stores.isEmpty) {
        setState(() {
          _errorMessage = 'No stores available. Please go back and ensure location is enabled.';
        });
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select a Shop', style: AppTheme.heading3),
                const SizedBox(height: 4),
                Text('Choose which shop to scan your list for',
                    style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                ...stores.take(5).map((store) => ListTile(
                  leading: const Icon(Icons.storefront_rounded, color: AppColors.primary),
                  title: Text(store.name, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _selectedStoreId = store.storeId;
                      _selectedStoreName = store.name;
                    });
                    onStoreSelected();
                  },
                )),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );
    }
  }

  /// Process image with backend OCR
  Future<void> _processImage(File imageFile) async {
    setState(() {
      _capturedImage = imageFile;
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Use selected store from store picker
      String storeId = _selectedStoreId ?? '';

      if (storeId.isEmpty) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'No store selected. Please select a store first.';
        });
        return;
      }

      // Upload image using multipart request
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isDemo = authProvider.isDemoMode;
      
      final uri = Uri.parse(
        '${ApiConfig.ocr}/upload-and-match?store_id=$storeId&wait_for_result=true&is_demo=$isDemo',
      );

      // Determine content type from file extension
      final ext = imageFile.path.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'image/png' 
          : ext == 'webp' ? 'image/webp' 
          : 'image/jpeg';

      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          filename: 'scan_${DateTime.now().millisecondsSinceEpoch}.$ext',
          contentType: MediaType.parse(mimeType),
        ),
      );

      print('Uploading to OCR: $uri');
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      print('OCR Response status: ${response.statusCode}');
      print('OCR Response body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final matched = List<Map<String, dynamic>>.from(data['matched'] ?? []);
        final unmatched = List<Map<String, dynamic>>.from(data['unmatched'] ?? []);
        final suggestions = List<Map<String, dynamic>>.from(data['suggestions'] ?? []);

        setState(() {
          _isProcessing = false;
        });

        // Navigate to Draft Cart Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DraftCartScreen(
              matchedItems: matched,
              unmatchedItems: unmatched,
              suggestions: suggestions,
              storeId: storeId,
            ),
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _isProcessing = false;
          _errorMessage = errorData['detail'] ?? 'OCR processing failed';
        });
      }
    } catch (e) {
      print('OCR error: $e');
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Failed to process image: ${e.toString().replaceAll('Exception:', '').trim()}';
      });
    }
  }

  Future<void> _captureImage() async {
    if (_selectedStoreId == null) {
      _showStorePicker(onStoreSelected: _captureImage);
      return;
    }
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (photo != null) {
      await _processImage(File(photo.path));
    }
  }

  Future<void> _pickFromGallery() async {
    if (_selectedStoreId == null) {
      _showStorePicker(onStoreSelected: _pickFromGallery);
      return;
    }
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (image != null) {
      await _processImage(File(image.path));
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text('AI Scanner Help', style: AppTheme.heading3),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _helpStep('1', 'Write your shopping list on paper'),
            const SizedBox(height: 12),
            _helpStep('2', 'Take a photo or pick an image from gallery'),
            const SizedBox(height: 12),
            _helpStep('3', 'AI reads your list and matches items to store products'),
            const SizedBox(height: 12),
            _helpStep('4', 'Review matched items and add to cart'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _helpStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: Center(child: Text(number, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.buttonText))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: AppTheme.bodyMedium)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary)),
                  Row(children: [
                    Icon(Icons.auto_awesome, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('AI SCANNER', style: AppTheme.heading3.copyWith(color: AppColors.primary, letterSpacing: 1)),
                  ]),
                  const Spacer(),
                  // Store selector chip
                  GestureDetector(
                    onTap: _isProcessing ? null : () => _showStorePicker(onStoreSelected: () {}),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _selectedStoreId != null ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _selectedStoreId != null ? AppColors.primary.withOpacity(0.3) : AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.storefront_rounded, size: 14, color: _selectedStoreId != null ? AppColors.primary : AppColors.textTertiary),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 90),
                            child: Text(
                              _selectedStoreName?.split(' - ').first ?? 'Select Shop',
                              style: AppTheme.caption.copyWith(
                                color: _selectedStoreId != null ? AppColors.primary : AppColors.textTertiary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_drop_down, size: 16, color: _selectedStoreId != null ? AppColors.primary : AppColors.textTertiary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _showHelpDialog,
                    icon: Icon(Icons.help_outline_rounded, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Camera viewfinder / Captured image
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: _capturedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(19),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_capturedImage!, fit: BoxFit.cover),
                            if (_isProcessing)
                              Container(
                                color: Colors.black54,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(color: AppColors.primary),
                                      const SizedBox(height: 16),
                                      Text('AI is reading your list...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 8),
                                      Text('This may take a few seconds', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 64, color: AppColors.textTertiary.withOpacity(0.3)),
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: CustomPaint(painter: _ScanFramePainter(color: AppColors.primary)),
                            ),
                          ),
                          Positioned(
                            bottom: 24,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
                              child: Text('Point camera at your shopping list', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
             // Error message or Instructions
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 18, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage!, style: TextStyle(fontSize: 12, color: Colors.red[700]))),
                  ],
                ),
              )
            else if (!_isProcessing)
               Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Text(
                   "Capture a clear photo of your handwritten list. The AI will extract items and find the best matches in the store.",
                   textAlign: TextAlign.center,
                   style: TextStyle(color: AppColors.textSecondary),
                 ),
               ),
              
              const Spacer(),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'gallery',
            onPressed: _isProcessing ? null : _pickFromGallery,
            backgroundColor: _isProcessing ? AppColors.surfaceVariant : AppColors.surface,
            child: Icon(Icons.photo_library_rounded, color: _isProcessing ? AppColors.textTertiary : AppColors.primary),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'capture',
            onPressed: _isProcessing ? null : _captureImage,
            backgroundColor: _isProcessing ? AppColors.surfaceVariant : AppColors.primary,
            icon: Icon(Icons.camera_alt_rounded, color: _isProcessing ? AppColors.textTertiary : AppColors.buttonText),
            label: Text('Capture', style: TextStyle(color: _isProcessing ? AppColors.textTertiary : AppColors.buttonText, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  final Color color;
  _ScanFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLen = 30.0;

    canvas.drawLine(Offset.zero, Offset(cornerLen, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, cornerLen), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLen, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLen), paint);
    canvas.drawLine(Offset(0, size.height), Offset(cornerLen, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLen), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLen, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLen), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
