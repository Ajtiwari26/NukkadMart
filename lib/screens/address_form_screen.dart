import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';

class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _houseController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _landmarkController = TextEditingController();
  String _selectedLabel = 'Home';

  double? _selectedLat;
  double? _selectedLng;

  @override
  void dispose() {
    _houseController.dispose();
    _apartmentController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    child: Text('Add Address', style: AppTheme.heading3),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Map preview
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.pushNamed(context, '/map-picker');
                          if (result != null && result is Map) {
                            setState(() {
                              _selectedLat = result['lat'];
                              _selectedLng = result['lng'];
                              
                              // Auto-fill form if address parts available
                              if (result['address'] != null) {
                                // Simple heuristic to split address
                                final parts = result['address'].toString().split(',');
                                if (parts.isNotEmpty) _houseController.text = parts[0].trim();
                                if (parts.length > 1) _apartmentController.text = parts.sublist(1).join(',').trim();
                              }
                            });
                          }
                        },
                        child: Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.map_outlined,
                                    size: 48,
                                    color: _selectedLat != null ? AppColors.primary : AppColors.textTertiary,
                                  ),
                                  if (_selectedLat != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        "Location Selected", 
                                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)
                                      ),
                                    ),
                                ],
                              ),
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _selectedLat != null ? 'Change' : 'Pick Location',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.buttonText,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // House / Flat
                      Text('House / Flat No.', style: AppTheme.label),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _houseController,
                        style: AppTheme.bodyLarge,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Flat 302, Block A',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter house/flat number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Apartment / Road
                      Text('Apartment / Road', style: AppTheme.label),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _apartmentController,
                        style: AppTheme.bodyLarge,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Green Park Colony',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter apartment/road';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Landmark
                      Text('Landmark (Optional)', style: AppTheme.label),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _landmarkController,
                        style: AppTheme.bodyLarge,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Near City Mall',
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Save as label
                      Text('Save As', style: AppTheme.label),
                      const SizedBox(height: 12),
                      Row(
                        children: ['Home', 'Work', 'Other'].map((label) {
                          final isSelected = _selectedLabel == label;
                          IconData icon;
                          switch (label) {
                            case 'Home':
                              icon = Icons.home_rounded;
                              break;
                            case 'Work':
                              icon = Icons.work_rounded;
                              break;
                            default:
                              icon = Icons.location_on_rounded;
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedLabel = label),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: isSelected
                                      ? null
                                      : Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      icon,
                                      size: 18,
                                      color: isSelected
                                          ? AppColors.buttonText
                                          : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? AppColors.buttonText
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 32),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: Consumer<AuthProvider>(
                          builder: (context, auth, child) {
                            return ElevatedButton(
                              onPressed: auth.isLoading
                                  ? null
                                  : () async {
                                      if (_formKey.currentState!.validate()) {
                                          final addressData = {
                                          'house': _houseController.text.trim(),
                                          'apartment': _apartmentController.text.trim(),
                                          'landmark': _landmarkController.text.trim(),
                                          'label': _selectedLabel,
                                          'lat': _selectedLat ?? 23.2599,
                                          'lng': _selectedLng ?? 77.4126,
                                        };

                                        final success = await auth.saveAddress(addressData);

                                        if (success && context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Address saved successfully!'),
                                              backgroundColor: AppColors.success,
                                            ),
                                          );
                                          Navigator.pop(context, addressData);
                                        } else if (context.mounted) {
                                           ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(auth.error ?? 'Failed to save address'),
                                              backgroundColor: AppColors.error,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              style: AppTheme.primaryButton,
                              child: auth.isLoading 
                                ? CircularProgressIndicator(color: AppColors.buttonText)
                                : Text('Save Address', style: AppTheme.button),
                            );
                          },
                        ),
                      ),
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
}
