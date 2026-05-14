import 'dart:io';
import 'package:faramas/config/app_routes.dart';
import 'package:faramas/models/airbnb_data.dart';
import 'package:faramas/models/airbnb_property_model.dart';
import 'package:faramas/models/facility_model.dart';
import 'package:faramas/models/property_model.dart';
import 'package:faramas/providers/auth_provider.dart';
import 'package:faramas/services/property_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_compress/video_compress.dart';
import '../../../config/app_colors.dart';
import '../../../screens/map_picker.dart';

class AirbnbDescriptionScreen extends StatefulWidget {
  final AirbnbData airbnbData;

  const AirbnbDescriptionScreen({super.key, required this.airbnbData});

  @override
  State<AirbnbDescriptionScreen> createState() =>
      _AirbnbDescriptionScreenState();
}

class _AirbnbDescriptionScreenState extends State<AirbnbDescriptionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _propertyNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;

  String? _locationAddress;
  double? _latitude;
  double? _longitude;

  // ignore: unused_field
  bool _isLoading = false;
  final List<File> _images = [];
  File? _selectedVideo;
  final int _maxVideoDurationSeconds = 60; // 1 minute

  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _propertyNameController =
        TextEditingController(text: widget.airbnbData.propertyName ?? '');
    _descriptionController =
        TextEditingController(text: widget.airbnbData.description ?? '');
    _priceController =
        TextEditingController(text: widget.airbnbData.price?.toString() ?? '');

    _locationAddress = widget.airbnbData.address;
    _latitude = widget.airbnbData.latitude;
    _longitude = widget.airbnbData.longitude;

    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _animationController.forward();
  }

  @override
  void dispose() {
    _propertyNameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        final duration = await _getVideoDuration(video.path);
        if (duration > _maxVideoDurationSeconds) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Video must be max 1 minute.')),
          );
          return;
        }

        setState(() => _selectedVideo = File(video.path));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video selected successfully!')),
        );
      }
    } catch (e) {
      debugPrint('Video pick error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select video: $e')),
      );
    }
  }

  Future<int> _getVideoDuration(String path) async {
    final info = await VideoCompress.getMediaInfo(path);
    return (info.duration! / 1000).ceil();
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
      _animationController.forward(from: 0);
    }
  }

  Future<void> _recordVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 60),
      );
      if (video != null) {
        setState(() => _selectedVideo = File(video.path));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video recorded successfully!')),
        );
      }
    } catch (e) {
      debugPrint('Video record error: $e');
    }
  }

  Future<void> _takePhoto() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
      _animationController.forward(from: 0);
    }
  }

  Future<void> _selectLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerScreen()),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _locationAddress = result['address'] as String?;
        _latitude = result['latitude'] as double?;
        _longitude = result['longitude'] as double?;
      });
    }
  }

  double _cleanDouble(String value) {
    return double.tryParse(
            value.replaceAll(',', '').replaceAll('Tzs', '').trim()) ??
        0.0;
  }

  void _updateAirbnbData() {
    widget.airbnbData.propertyName = _propertyNameController.text;
    widget.airbnbData.description = _descriptionController.text;
    widget.airbnbData.price = _cleanDouble(_priceController.text);
    widget.airbnbData.address = _locationAddress;
    widget.airbnbData.latitude = _latitude;
    widget.airbnbData.longitude = _longitude;
  }

  Future<void> _uploadProperty() async {
  if (_isLoading) return;

  if (!(_formKey.currentState?.validate() ?? false)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill all required fields.')),
    );
    return;
  }

  if (_images.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select at least one image.')),
    );
    return;
  }

  if (_latitude == null || _longitude == null || _locationAddress == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a location.')),
    );
    return;
  }

  setState(() => _isLoading = true);
  _updateAirbnbData();

  try {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);

  //  PHONE NUMBER CHECK
  if (authProvider.user?.phone == null || authProvider.user!.phone!.isEmpty) {
    showPhoneRequiredPopup(context);
    setState(() => _isLoading = false);
    return;
  }

  final airbnbModel = AirbnbModel(
    name: _propertyNameController.text,
    description: _descriptionController.text,
    price: double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0,
    address: _locationAddress!,
    latitude: double.parse((_latitude!).toStringAsFixed(6)),
    longitude: double.parse((_longitude!).toStringAsFixed(6)),
    type: widget.airbnbData.placeType ?? 'Apartment',
    isRent: true,
    isBooked: false,
    maxGuests: widget.airbnbData.guests ?? 1,
    bedrooms: widget.airbnbData.bedrooms ?? 1,
    beds: widget.airbnbData.beds ?? 1,
    bathrooms: widget.airbnbData.bathrooms ?? 1,
    amenities: widget.airbnbData.amenities ?? [],
    cleaningFee: widget.airbnbData.cleaningFee ?? 0,
    checkInTime: widget.airbnbData.checkInTime ?? '14:00',
    checkOutTime: widget.airbnbData.checkOutTime ?? '11:00',
    houseRules: widget.airbnbData.houseRules ?? [],
    cancellationPolicy: widget.airbnbData.cancellationPolicy ?? 'Flexible',
    minimumStay: widget.airbnbData.minimumStay ?? 1,
    maximumStay: widget.airbnbData.maximumStay ?? 30,
    instantBook: widget.airbnbData.instantBook ?? false,
    propertySubType: widget.airbnbData.propertySubType ?? 'Entire Place',
    securityDeposit: widget.airbnbData.securityDeposit ?? 0,
    safetyFeatures: widget.airbnbData.safetyFeatures ?? [],
    wifiPassword: widget.airbnbData.wifiPassword ?? '',
    accessInstructions: widget.airbnbData.accessInstructions ?? '',
    totalPrice: 0,
    maintenance: 0,
    facilities: (widget.airbnbData.facilities as List<dynamic>? ?? [])
        .map((f) => f is Facility ? f : Facility.fromJson(f))
        .toList(),
    category: 'Apartment',
  );

    final property = PropertyModel(
      name: airbnbModel.name,
      type: airbnbModel.type,
      isRent: true,
      address: airbnbModel.address,
      price: airbnbModel.price,
      description: airbnbModel.description,
      totalPrice: 0,
      maintenance: 0,
      facilities: [],
      images: [],
      airbnb: airbnbModel,
    );

    final response = await PropertyService().postAirbnbProperty(
      property: property,
      authProvider: authProvider,
      imagePaths: _images.map((f) => f.path).toList(),
      videoPath: _selectedVideo?.path,
    );

    if (!mounted) return;

    if (response['status'] == 401) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please log in again.')),
      );
      await authProvider.logout();
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    if (response['payment_required'] == true) {
      _showAnimatedDialog(
        property,
        type: DialogType.payment,
        message: response['message'] ?? 'Payment required.',
        onAction: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushNamed('/generatePayment', arguments: property);
        },
      );
    } else if (response['success'] == true) {
      _showAnimatedDialog(
        property,
        type: DialogType.success,
        message: response['message'] ?? 'Property uploaded successfully!',
        onAction: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        },
      );
    } else {
      _showAnimatedDialog(
        property,
        type: DialogType.error,
        message: response['message'] ?? 'Failed to upload property.',
      );
    }
  } catch (e) {
    if (!mounted) return;
    _showAnimatedDialog(
      PropertyModel(
        name: 'Unknown',
        type: 'Unknown',
        address: 'Unknown',
        price: 0,
        isRent: false,
        description: 'No description available',
        totalPrice: 0,
        maintenance: 0,
        facilities: [],
      ),
      type: DialogType.error,
      message: "Error: $e",
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

//popup for phone number required
void showPhoneRequiredPopup(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "",
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const SizedBox.shrink(); // required placeholder
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        ),
        child: Opacity(
          opacity: animation.value,
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.80,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    offset: Offset(0, 12),
                    blurRadius: 24,
                    color: Colors.black26,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Airbnb icon-style circle
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration:const  BoxDecoration(
                      color:  Color(0xFFF7F7F7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone_iphone,
                      size: 32,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    "Phone Number Required",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "For safety and verification, please update your phone number before continuing.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 22),

                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, "/edit_profile");
                          },
                          child: const Text(
                            "Update",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

  /// Helper for dialogs
  void _showAnimatedDialog(PropertyModel property,
      {required DialogType type,
      required String message,
      VoidCallback? onAction}) {
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

  Widget _buildImagePreview() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _images.length + 1,
        itemBuilder: (context, index) {
          if (index == _images.length) {
            return GestureDetector(
              onTap: _pickImageFromGallery,
              child: Container(
                width: 100,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_photo_alternate,
                    size: 40, color: Colors.grey),
              ),
            );
          }
          final file = _images[index];
          return Stack(
            children: [
              Container(
                width: 100,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                      image: FileImage(file), fit: BoxFit.cover),
                ),
              ),
              Positioned(
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _images.removeAt(index);
                    });
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

 Widget _buildVideoPreview() {
  if (_selectedVideo == null) return const SizedBox.shrink();

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 12),
    height: 150,
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: Colors.black12,
    ),
    child: Stack(
      children: [
        Center(
          child: Icon(Icons.videocam, size: 50, color: Colors.black54),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => setState(() => _selectedVideo = null),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Short Stay Description'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Price ---
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (Tsh.)',
                  prefixText: 'Tsh. ',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Enter price' : null,
              ),
              const SizedBox(height: 16),

              // --- Property Name ---
              TextFormField(
                controller: _propertyNameController,
                decoration: const InputDecoration(
                  labelText: 'Property Name',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Enter property name'
                    : null,
              ),
              const SizedBox(height: 16),

              // --- Description ---
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Enter description'
                    : null,
              ),
              const SizedBox(height: 16),

              // --- Location Selector ---
              GestureDetector(
                onTap: _selectLocation,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _locationAddress ?? 'Select Location',
                          style: TextStyle(
                            color: _locationAddress == null
                                ? Colors.grey
                                : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Image & Video Buttons ---
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text('Camera', style: TextStyle(
                      color:Colors.white,
                    ),),
                    style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: const Icon(Icons.photo_library,color: Colors.white),
                    label: const Text('Gallery', style: TextStyle(color: Colors.white),),
                    style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                  ),
                  const SizedBox(width: 8),
                 
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [

               ElevatedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.video_library,color: Colors.white),
                    label: Text(
                      _selectedVideo == null ? 'Add Video' : 'Change Video',
                      style: TextStyle(color: Colors.white),
                    ),

                    style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _recordVideo,
                    icon: const Icon(Icons.videocam,color: Colors.white),
                    label: const Text('Record (Max 1 min)',
                    style: TextStyle(color: Colors.white),),
                    style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                  ),
                ]),
                    const SizedBox(height: 16),

              // --- Image Preview ---
              _buildImagePreview(),
              _buildVideoPreview(),

              const SizedBox(height: 24),

              // --- Submit Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _uploadProperty,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit Your Property',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

    switch (widget.type) {
      case DialogType.payment:
        title = "Payment Required";
        icon = Icons.payment;
        color = Colors.orange;
        break;
      case DialogType.success:
        title = "Success";
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case DialogType.error:
        title = "Upload Failed";
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
                  widget.type == DialogType.payment
                      ? "Pay Now"
                      : widget.type == DialogType.success
                          ? "Go Home"
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
