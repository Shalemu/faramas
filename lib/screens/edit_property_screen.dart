import 'dart:convert';
import 'dart:io';

import 'package:faramas/config/app_colors.dart';
import 'package:faramas/config/app_routes.dart';
import 'package:faramas/home_screens.dart';
import 'package:faramas/providers/auth_provider.dart';
import 'package:faramas/services/property_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/facility_model.dart';

class EditPropertyScreen extends StatefulWidget {
  final PropertyModel property;

  const EditPropertyScreen({super.key, required this.property});

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
  late String _selectedType = "";
  late String _selectedCategory = "";
  final List<String> _propertyTypes = [
    'House',
    'Apartment',
    'Room',
    'Land',
    'Office',
    'Construction'
  ];
  final List<String> _categories = ['Rent', 'Sale', 'Short Stay'];
  late List<Facility> _selectedFacilities =
      List<Facility>.from(widget.property.facilities);
  List<String> _uploadedImages = [];
  final int _maxImages = 5;

  final Map<String, IconData> facilityIcons = {
    'Parking': Icons.local_parking,
    'Swimming Pool': Icons.pool,
    'Garden': Icons.park,
    'Security': Icons.security,
    'Gym': Icons.fitness_center,
    'Internet': Icons.wifi,
    'Air Conditioning': Icons.ac_unit,
    'Furnished': Icons.chair,
  };

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.property.name);
    _priceController =
        TextEditingController(text: widget.property.price.toString());
    _descriptionController =
        TextEditingController(text: widget.property.description);
    _addressController = TextEditingController(text: widget.property.address);

    _selectedFacilities = List<Facility>.from(widget.property.facilities);
    _uploadedImages = List<String>.from(widget.property.images);

    _selectedType = _propertyTypes.contains(widget.property.type)
        ? widget.property.type
        : _propertyTypes.first;

    _selectedCategory = (_categories.contains(widget.property.category)
        ? widget.property.category
        : _categories.first)!;
  }

  final List<String> mergedImages = [];

Future<void> _uploadProperty() async {
  if (!(_formKey.currentState?.validate() ?? false)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill all required fields.')),
    );
    return;
  }

  if (_uploadedImages.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select at least one image.')),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    final service = PropertyService();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken;

    
    final List<Map<String, dynamic>> apiImages = [];
    for (var imgPath in _uploadedImages) {
      if (imgPath.startsWith('http')) {
        apiImages.add({"filename": imgPath.split('/').last, "data": imgPath});
      } else {
        final bytes = await File(imgPath).readAsBytes();
        apiImages.add({
          "filename": imgPath.split('/').last,
          "data": base64Encode(bytes),
        });
      }
    }

 
    final property = PropertyModel(
      id: widget.property.id,
      name: _nameController.text,
      type: _selectedType,
      address: _addressController.text,
      price: double.tryParse(_priceController.text.replaceAll(',', '').trim()) ?? 0.0,
      isRent: _selectedCategory == 'Rent',
      category: _selectedCategory,
      description: _descriptionController.text,
      totalPrice: widget.property.totalPrice,
      maintenance: widget.property.maintenance,
      facilities: _selectedFacilities,
      images: _uploadedImages,
      latitude: widget.property.latitude,
      longitude: widget.property.longitude,
      region: widget.property.region,
      district: widget.property.district,
    );


    final payload = {
      'name': property.name,
      'type': property.type,
      'category': property.category ?? "",
      'address': property.address,
      'price': property.price.toString(),
      'description': property.description,
      'is_rent': property.isRent,
      'facilities': property.facilities.map((f) => f.name).toList(), // or f.id if backend expects IDs
      'images': apiImages,
    };


    debugPrint("=== FULL PROPERTY PAYLOAD ===");
    debugPrint(const JsonEncoder.withIndent('  ').convert(payload));
    debugPrint("============================");

   
   
    final result = await service.updateProperty(
      token!,
      widget.property.id!.toString(),
      property,
      apiImages,
    );

    final statusCode = result['statusCode'];
    final responseData = result['data'] ?? {};

    debugPrint("Update status code: $statusCode");
    debugPrint("Update response data: $responseData");

    if (statusCode == 200 || statusCode == 201) {
      _showAnimatedDialog(
        property,
        type: DialogType.success,
        message: "Property updated successfully!",
        onAction: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        },
      );
    } else {
      _showAnimatedDialog(
        property,
        type: DialogType.error,
        message: responseData['error'] ?? "Failed to update property. Please try again.",
      );
    }
  } catch (e) {
    debugPrint("Exception in _uploadProperty: $e");
    _showAnimatedDialog(
      widget.property,
      type: DialogType.error,
      message: "Error: $e",
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}


// --- Dialog Helper ---
void _showAnimatedDialog(
  PropertyModel property, {
  required DialogType type,
  required String message,
  VoidCallback? onAction,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AnimatedPaymentDialog(
      property: property,
      message: message,
      type: type,
      onAction: onAction,
    ),
  );
}


  Widget _buildImageUploadGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _maxImages,
      itemBuilder: (context, index) {
        // Check if we have an image for this index
        final bool hasImage = index < _uploadedImages.length;

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: InkWell(
            onTap: () async {
              if (_uploadedImages.length < _maxImages) {
                final ImagePicker picker = ImagePicker();
                final XFile? pickedFile =
                    await picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  setState(() {
                    _uploadedImages.add(pickedFile.path);
                  });
                }
              }
            },
            child: hasImage
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _uploadedImages[index].startsWith('http')
                            ? Image.network(
                                _uploadedImages[index],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                  child: Icon(Icons.broken_image, size: 40),
                                ),
                              )
                            : Image.file(
                                File(_uploadedImages[index]),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _uploadedImages.removeAt(index);
                            });
                          },
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 32,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add Image',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Edit Property',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Property Images (Max 5)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildImageUploadGrid(),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Property Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter property name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Property Type',
                        border: OutlineInputBorder(),
                      ),
                      items: _propertyTypes.map((String type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedType = newValue!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((String category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategory = newValue!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (Tsh)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Facilities',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedFacilities.map((facility) {
                  final isSelected = _selectedFacilities.contains(facility);
                  return FilterChip(
                    avatar: Icon(
                      facilityIcons[facility.name],
                      size: 18,
                      color: isSelected ? const Color(0xFF1E4B6C) : Colors.grey,
                    ),
                    label: Text(facility.name),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedFacilities.add(facility);
                        } else {
                          _selectedFacilities.remove(facility);
                        }
                      });
                    },
                    selectedColor: const Color(0xFF1E4B6C).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF1E4B6C),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _uploadProperty(),
                  icon: const Icon(Icons.save,
                  color:Colors.white),
                  label: const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 16, color: AppColors.textLight),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}

enum DialogType { payment, success, error }

class AnimatedPaymentDialog extends StatefulWidget {
  final PropertyModel property;
  final String message;
  final DialogType type;
  final VoidCallback? onAction;

  const AnimatedPaymentDialog({
    super.key,
    required this.property,
    required this.message,
    required this.type,
    this.onAction,
  });

  @override
  _AnimatedPaymentDialogState createState() => _AnimatedPaymentDialogState();
}

class _AnimatedPaymentDialogState extends State<AnimatedPaymentDialog>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    String title;
    IconData icon;
    Color color;

    // ✅ Cover all enum values
    switch (widget.type) {
      case DialogType.payment:
        title = "Payment";
        icon = Icons.payment;
        color = Colors.blue;
        break;
      case DialogType.success:
        title = "Success";
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case DialogType.error:
        title = "Error";
        icon = Icons.error;
        color = Colors.red;
        break;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                child: Icon(icon, color: color, size: 64),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            if (widget.onAction != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: widget.onAction,
                child: Text(
                  widget.type == DialogType.success
                      ? "Go Home"
                      : widget.type == DialogType.payment
                          ? "Proceed"
                          : "Close",
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
