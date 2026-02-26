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

  /// Process image with backend OCR
  Future<void> _processImage(File imageFile) async {
    setState(() {
      _capturedImage = imageFile;
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Get a store_id to match against
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      String storeId = '';
      if (storeProvider.selectedStore != null) {
        storeId = storeProvider.selectedStore!.storeId;
      } else if (storeProvider.stores.isNotEmpty) {
        storeId = storeProvider.stores.first.storeId;
      }

      if (storeId.isEmpty) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'No store selected. Please go back and select a store first.';
        });
        return;
      }

      // Upload image using multipart request
      final uri = Uri.parse(
        '${ApiConfig.ocr}/upload-and-match?store_id=$storeId&wait_for_result=true',
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
