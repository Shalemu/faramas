import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user_model.dart';
import '../../../config/app_colors.dart';
import '../../../services/auth_services.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  File? _pickedImage;
  bool _isLoading = true;
  UserModel? _currentUserDetails;

  String? _statusMessage; // Inline success/error message
  Color _statusColor = Colors.green;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();

    _fetchUserDetails();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserDetails() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.accessToken;
      if (token == null) throw Exception("Authentication token not found.");

      final authService = AuthService();
      _currentUserDetails = await authService.getUserDetails(accessToken: token);

      _firstNameController.text = _currentUserDetails?.firstName ?? '';
      _lastNameController.text = _currentUserDetails?.lastName ?? '';
      _emailController.text = _currentUserDetails?.email ?? '';
      _phoneController.text = _currentUserDetails?.phone ?? '';
    } catch (e) {
      debugPrint('Profile fetch error: $e');
      setState(() {
        _statusMessage = 'Failed to load profile: $e';
        _statusColor = Colors.red;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (image != null) {
      setState(() => _pickedImage = File(image.path));
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = _currentUserDetails;
      final token = authProvider.accessToken;
      final authService = AuthService();

      if (user == null || token == null) {
        throw Exception("User data or authentication token not available.");
      }

      // Update phone number if changed
      if (_phoneController.text != (user.phone ?? '')) {
        try {
          await authService.updatePhoneNumber(
            accessToken: token,
            phoneNumber: _phoneController.text,
          );
          debugPrint('Phone number updated successfully: ${_phoneController.text}');
        } catch (e) {
          debugPrint('Failed to update phone number: $e');
          setState(() {
            _statusMessage = 'Failed to update phone number: $e';
            _statusColor = Colors.red;
          });
          return;
        }
      }

      // Update other profile fields
      final updatedUserModel = UserModel(
        id: user.id,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        userImage: _pickedImage == null ? user.userImage : null,
      );

      try {
        final returnedUserModel = await authService.updateUserProfile(
          userId: user.id!,
          data: updatedUserModel,
          imageFile: _pickedImage,
          accessToken: token,
        );
        await authProvider.updateUser(returnedUserModel);

        debugPrint('Profile updated successfully for user: ${returnedUserModel.id}');
        setState(() {
          _statusMessage = 'Profile updated successfully!';
          _statusColor = Colors.green;
        });
      } catch (e) {
        debugPrint('Failed to update profile: $e');
        setState(() {
          _statusMessage = 'Failed to update profile: $e';
          _statusColor = Colors.red;
        });
        return;
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[200]!, width: 2),
                          ),
                          child: _pickedImage != null
                              ? CircleAvatar(
                                  radius: 58,
                                  backgroundImage: FileImage(_pickedImage!),
                                )
                              : (_currentUserDetails?.userImage != null &&
                                      _currentUserDetails!.userImage!.isNotEmpty
                                  ? CircleAvatar(
                                      radius: 58,
                                      backgroundImage:
                                          NetworkImage(_currentUserDetails!.userImage!),
                                      onBackgroundImageError: (e, s) =>
                                          debugPrint('Error loading image: $e'),
                                    )
                                  : CircleAvatar(
                                      radius: 58,
                                      backgroundColor: Colors.grey[200],
                                      child: const Icon(Icons.person, size: 60, color: Colors.grey),
                                    )),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Inline status message
                    if (_statusMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: _statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _statusColor),
                        ),
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(color: _statusColor, fontWeight: FontWeight.w500),
                        ),
                      ),

                    // Form Fields
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Please enter your first name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Please enter your last name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please enter your email';
                        if (!v.contains('@')) return 'Please enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Please enter your phone number' : null,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Save Changes', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
