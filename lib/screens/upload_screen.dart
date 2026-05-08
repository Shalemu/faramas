import 'dart:io';
import 'package:faramas/config/app_colors.dart';
import 'package:faramas/config/app_routes.dart';
import 'package:faramas/screens/map_picker.dart';
import 'package:faramas/services/property_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../models/facility_model.dart';
import '../models/property_model.dart';
import '../providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  // GlobalKey for form validation
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _priceController = TextEditingController();
  final NumberFormat _formatter = NumberFormat("#,##0", "en_US");
  @override
  void initState() {
    super.initState();

    _priceController.addListener(() {
      final text =
          _priceController.text.replaceAll(',', '').replaceAll(' Tzs', '');
      if (text.isEmpty) return;

      final num? value = num.tryParse(text);
      if (value != null) {
        final newText = _formatter.format(value);

        if (_priceController.text != newText) {
          final cursorPos = newText.length;
          _priceController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: cursorPos),
          );
        }
      }
    });
  }

  // Image picker instance and list to store selected images
  final ImagePicker _picker = ImagePicker();

  final int _maxImages = 5; // Maximum number of images allowed for upload

  // Text editing controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  // final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController =
      TextEditingController(); // This one will be read-only now
  final TextEditingController _totalPriceController = TextEditingController();

  // Selected property type and category
  String _selectedType = 'House';
  String _selectedCategory = 'Rent';

  // Predefined lists for dropdowns
  final List<String> _propertyTypes = [
    'House',
    'Apartment',
    'Room',
    'Land',
    'Office',
    'Construction'
  ];

  final List<String> _categories = ['Rent', 'Sale', 'Short Stay'];
  // ignore: unused_field
  late AnimationController _animationController;

  // List to store selected facilities
  final List<String> _selectedFacilities = [];
  // ignore: unused_field
  final List<File> _images = [];
  List<XFile> _selectedImages = [];

  XFile? _selectedVideo;
  VideoPlayerController? _videoController;

  // Location data fields
  double? _latitude;
  double? _longitude;
  String? _currentRegion;
  String? _currentDistrict;

  // State variable to manage loading indicator during upload
  bool _isLoading = false;

  // Predefined list of facilities with their names and icons
  final List<Map<String, dynamic>> _facilities = [
    {'name': 'Parking', 'icon': Icons.local_parking},
    {'name': 'Swimming Pool', 'icon': Icons.pool},
    {'name': 'Garden', 'icon': Icons.park},
    {'name': 'Security', 'icon': Icons.security},
    {'name': 'Gym', 'icon': Icons.fitness_center},
    {'name': 'Internet', 'icon': Icons.wifi},
    {'name': 'Air Conditioning', 'icon': Icons.ac_unit},
    {'name': 'Furnished', 'icon': Icons.chair},
  ];

  Future<void> _uploadProperty() async {
    if (_isLoading) return; // Prevent duplicate upload
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image.')),
      );
      return;
    }

    if (_latitude == null ||
        _longitude == null ||
        _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please use "Use Current Location" to fetch address details.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = PropertyService();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.accessToken;

      if (token == null) {
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

//  PHONE NUMBER CHECK ADDED HERE
      if (authProvider.user?.phone == null ||
          authProvider.user!.phone!.isEmpty) {
        showPhoneRequiredPopup(context);
        setState(() => _isLoading = false);
        return;
      }

      // Convert selected images to file paths
      final imagePaths = _selectedImages.map((xfile) => xfile.path).toList();

      final result = await service.createProperty(
        PropertyModel(
          name: _nameController.text,
          type: _selectedType,
          address: _addressController.text,
          price: double.tryParse(
                  _priceController.text.replaceAll(',', '').trim()) ??
              0.0,
          isRent: _selectedCategory == 'Rent',
          category: _selectedCategory,
          description: _descriptionController.text,
          totalPrice: double.tryParse(
                  _totalPriceController.text.replaceAll(',', '').trim()) ??
              0.0,
          maintenance: 0.0,
          facilities:
              _selectedFacilities.map((f) => Facility(name: f)).toList(),
          latitude: _latitude,
          longitude: _longitude,
          region: _currentRegion,
          district: _currentDistrict,
        ),
        token,
        imagePaths,
        videoPath: _selectedVideo?.path, // optional video
      );

      debugPrint("Raw Upload Property Response: $result");

      final statusCode = result['statusCode'];
      final responseData = result['data'] ?? {};

      // --- Handle expired token ---
      if (statusCode == 401 || responseData['detail'] == 'Invalid token.') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Session expired. Please log in again.')),
        );
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      // --- Payment required ---
      if (responseData['payment_required'] == true) {
        _showAnimatedDialog(
          PropertyModel(
            name: _nameController.text,
            type: _selectedType,
            address: _addressController.text,
            price: double.tryParse(
                    _priceController.text.replaceAll(',', '').trim()) ??
                0.0,
            isRent: _selectedCategory == 'Rent',
            category: _selectedCategory,
            description: _descriptionController.text,
            totalPrice: double.tryParse(
                    _totalPriceController.text.replaceAll(',', '').trim()) ??
                0.0,
            maintenance: 0.0,
            facilities:
                _selectedFacilities.map((f) => Facility(name: f)).toList(),
            latitude: _latitude,
            longitude: _longitude,
            region: _currentRegion,
            district: _currentDistrict,
          ),
          type: DialogType.payment,
          message: responseData['error'] ??
              "Payment required before uploading property.",
          onAction: () {
            Navigator.of(context).pop();
            Navigator.of(context)
                .pushNamed('/generatePayment', arguments: null);
          },
        );
        return;
      }

      // --- Upload success ---
      if (statusCode == 200 ||
          statusCode == 201 ||
          responseData['success'] == true) {
        _showAnimatedDialog(
          PropertyModel(
            name: _nameController.text,
            type: _selectedType,
            address: _addressController.text,
            price: double.tryParse(
                    _priceController.text.replaceAll(',', '').trim()) ??
                0.0,
            isRent: _selectedCategory == 'Rent',
            category: _selectedCategory,
            description: _descriptionController.text,
            totalPrice: double.tryParse(
                    _totalPriceController.text.replaceAll(',', '').trim()) ??
                0.0,
            maintenance: 0.0,
            facilities:
                _selectedFacilities.map((f) => Facility(name: f)).toList(),
            latitude: _latitude,
            longitude: _longitude,
            region: _currentRegion,
            district: _currentDistrict,
          ),
          type: DialogType.success,
          message: "Property uploaded successfully!",
          onAction: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushReplacementNamed(AppRoutes.home);
          },
        );
        return;
      }

      // --- Other errors ---
      _showAnimatedDialog(
        PropertyModel(
          name: _nameController.text,
          type: _selectedType,
          address: _addressController.text,
          price: double.tryParse(
                  _priceController.text.replaceAll(',', '').trim()) ??
              0.0,
          isRent: _selectedCategory == 'Rent',
          category: _selectedCategory,
          description: _descriptionController.text,
          totalPrice: double.tryParse(
                  _totalPriceController.text.replaceAll(',', '').trim()) ??
              0.0,
          maintenance: 0.0,
          facilities:
              _selectedFacilities.map((f) => Facility(name: f)).toList(),
          latitude: _latitude,
          longitude: _longitude,
          region: _currentRegion,
          district: _currentDistrict,
        ),
        type: DialogType.error,
        message: responseData['error'] ??
            "Failed to upload property. Please try again.",
      );
    } catch (e) {
      debugPrint("Upload Exception: $e");
      _showAnimatedDialog(
        PropertyModel(
          name: "Unknown Property",
          type: "normal",
          address: "",
          price: 0.0,
          isRent: false,
          description: "",
          totalPrice: 0.0,
          maintenance: 0.0,
          facilities: [],
        ),
        type: DialogType.error,
        message: "Error: $e",
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Reuse animated dialog
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
                      decoration: const BoxDecoration(
                        color: Color(0xFFF7F7F7),
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
  // --- Image Handling UI & Logic ---

  Widget _buildImageUploadGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _selectedImages.length,
      itemBuilder: (context, index) {
        return _buildImageThumbnail(_selectedImages[index]);
      },
    );
  }

  /// Builds the "Add Image" button, which triggers the image picker.
  // ignore: unused_element
  Widget _buildAddImageButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: InkWell(
        onTap: _pickImages, // Call image picker on tap
        child: Column(
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
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a thumbnail widget for a selected image with a remove button.
  Widget _buildImageThumbnail(XFile image) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image:
                  FileImage(File(image.path)), // Display image from file path
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => _removeImage(image), // Remove image on button tap
          ),
        ),
      ],
    );
  }

  Future<void> _playVideo(File videoFile) async {
    try {
      _videoController?.dispose();
      final controller = VideoPlayerController.file(videoFile);
      await controller.initialize();

      setState(() {
        _videoController = controller;
      });

      // Show a dialog with the player
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.pause();
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        ),
      );

      controller.play();
    } catch (e) {
      debugPrint("Error playing video: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error playing video: $e")),
      );
    }
  }

  // ignore: unused_element
  Widget _buildVideoPreview() {
    if (_selectedVideo == null || _videoController == null)
      return const SizedBox();

    return GestureDetector(
      onTap: () {
        _playVideo(
            File(_selectedVideo!.path)); // open full-size video in dialog
      },
      child: Container(
        width: 120,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey),
        ),
        child: Stack(
          children: [
            VideoPlayer(_videoController!),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.red, size: 20),
                onPressed: () {
                  _videoController?.dispose();
                  setState(() {
                    _selectedVideo = null;
                    _videoController = null;
                  });
                },
              ),
            ),
            Center(
              child: Icon(
                _videoController!.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildVideoThumbnail(XFile videoFile) {
    final controller = VideoPlayerController.file(File(videoFile.path));
    return FutureBuilder(
      future: controller.initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        );
      },
    );
  }

  Future<void> _pickVideo() async {
    final pickedVideo = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedVideo != null) {
      _videoController?.dispose();

      final controller = VideoPlayerController.file(File(pickedVideo.path));
      await controller.initialize();

      setState(() {
        _selectedVideo = pickedVideo;
        _videoController = controller;
      });

      _videoController!.play();
    }
  }

  Future<void> _recordVideo() async {
    final recordedVideo = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 1),
    );
    if (recordedVideo != null) {
      _videoController?.dispose();

      final controller = VideoPlayerController.file(File(recordedVideo.path));
      await controller.initialize();

      setState(() {
        _selectedVideo = recordedVideo;
        _videoController = controller;
      });

      _videoController!.play();
    }
  }

  /// Enforces maximum image limit.
  Future<void> _pickImages() async {
    if (_selectedImages.length >= _maxImages) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You can upload up to $_maxImages images')),
      );
      return;
    }

    try {
      // Pick multiple images with specified max dimensions and quality
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        final int remainingSlots = _maxImages - _selectedImages.length;
        // Add only up to the remaining allowed slots
        final List<XFile> imagesToAdd = remainingSlots >= images.length
            ? images
            : images.sublist(0, remainingSlots);

        setState(() {
          _selectedImages.addAll(imagesToAdd);
        });

        // Inform user if some images couldn't be added due to limit
        if (images.length > remainingSlots) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Only $remainingSlots images were added')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick images: $e')),
      );
      debugPrint('Image picker error: $e');
    }
  }

  /// Removes a selected image from the list.
  void _removeImage(XFile image) {
    setState(() {
      _selectedImages.remove(image);
    });
  }

  Future<void> _takePhoto() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(pickedFile); //
      });
    }
  }

  /// Picks an image from the gallery and adds it to the list.
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(pickedFile); //
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  // ignore: unused_element
  Widget _buildImagePreview() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length + 1,
        itemBuilder: (context, index) {
          if (index == _selectedImages.length) {
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
          final image = _selectedImages[index];
          return Stack(
            children: [
              Container(
                width: 100,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                      image: FileImage(File(image.path)), fit: BoxFit.cover),
                ),
              ),
              Positioned(
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImages.removeAt(index);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Upload New Property'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textLight,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // --- Property Images & Video Section ---
              const Text(
                'Property Images (Max 5)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildImageUploadGrid(),
              if (_selectedVideo != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'Selected Video Preview',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    AspectRatio(
                      aspectRatio:
                          _videoController?.value.aspectRatio ?? 16 / 9,
                      child: _videoController != null &&
                              _videoController!.value.isInitialized
                          ? Stack(
                              children: [
                                VideoPlayer(_videoController!),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red),
                                    onPressed: () {
                                      _videoController?.pause();
                                      _videoController?.dispose();
                                      setState(() => _selectedVideo = null);
                                    },
                                  ),
                                ),
                              ],
                            )
                          : const Center(child: CircularProgressIndicator()),
                    ),
                  ],
                ),

              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text('Camera',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: const Icon(Icons.photo_library, color: Colors.white),
                    label: const Text('Gallery',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(children: [
                ElevatedButton.icon(
                  onPressed: _recordVideo,
                  icon: const Icon(Icons.videocam, color: Colors.white),
                  label: const Text('Video (Max 1 min)',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _pickVideo,
                  icon: const Icon(Icons.video_library, color: Colors.white),
                  label: Text(
                    _selectedVideo == null ? 'Add Video' : 'Change Video',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              // --- Property Details Section ---
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
                        return DropdownMenuItem(value: type, child: Text(type));
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
                            value: category, child: Text(category));
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
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (Tzs)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter price';
                  final cleaned =
                      value.replaceAll(',', '').replaceAll(' Tzs', '');
                  if (double.tryParse(cleaned) == null)
                    return 'Enter a valid number';
                  return null;
                },
              ),

              const SizedBox(height: 24),
              // --- Location Section ---
              // Inside your widget build method:
              const Text(
                'Location',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/location_bg.png'),
                    fit: BoxFit.cover,
                    opacity: 0.3,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 50,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 8),
                    if (_latitude != null &&
                        _longitude != null &&
                        _addressController.text.isNotEmpty)
                      Column(
                        children: [
                          Text(
                            'Lat: ${_latitude!.toStringAsFixed(4)}, Lon: ${_longitude!.toStringAsFixed(4)}',
                            style: TextStyle(
                                color: Colors.grey[800], fontSize: 14),
                          ),
                          Text(
                            _addressController.text,
                            style: TextStyle(
                                color: Colors.grey[800], fontSize: 14),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _openMap, // This opens the map
                      icon: const Icon(Icons.map),
                      label: const Text('Pick Property Location'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: const OutlineInputBorder(),
                  suffixIcon: _addressController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _addressController.clear();
                              _latitude = null;
                              _longitude = null;
                            });
                          },
                        )
                      : null,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a location on the map';
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
                maxLines: 4, // Allow multiple lines for description
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // --- Facilities Section ---
              const Text(
                'Facilities',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8, // Horizontal spacing between chips
                runSpacing: 8, // Vertical spacing between lines of chips
                children: _facilities.map((facility) {
                  final isSelected =
                      _selectedFacilities.contains(facility['name']);
                  return FilterChip(
                    avatar: Icon(
                      facility['icon'] as IconData,
                      size: 18,
                      color: isSelected ? AppColors.textLight : Colors.grey,
                    ),
                    label: Text(facility['name'] as String),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedFacilities.add(facility['name'] as String);
                        } else {
                          _selectedFacilities
                              .remove(facility['name'] as String);
                        }
                      });
                    },
                    selectedColor:
                        AppColors.primary, // Using primary color for selected
                    checkmarkColor: AppColors.textLight, // White checkmark
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.textLight : Colors.black87,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // --- Upload Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null // Disable button when loading
                      : () {
                          if (_formKey.currentState!.validate()) {
                            _uploadProperty(); // Trigger upload
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: AppColors.textLight) // Show loading spinner
                      : const Text(
                          'Upload Property',
                          style: TextStyle(
                              fontSize: 16, color: AppColors.textLight),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ]),
          ),
        ));
  }

  void _openMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerScreen()),
    );

    if (result != null) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        _currentRegion = result['region'];
        _currentDistrict = result['district'];
        _addressController.text = result['address'];
      });

      // Optionally print to debug console:
      print('Latitude: $_latitude');
      print('Longitude: $_longitude');
      print('District: $_currentDistrict');
      print('Region: $_currentRegion');
      print('Address: ${_addressController.text}');
    }
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _videoController?.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}

enum DialogType { payment, success, error, warning }

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

      case DialogType.warning: // <-- add this
        title = "Warning";
        icon = Icons.warning;
        color = Colors.yellow;
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
