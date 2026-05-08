// lib/screens/property_detail_screen.dart
import 'dart:convert';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:faramas/config/app_routes.dart';
import 'package:faramas/models/user_model.dart';
import 'package:faramas/providers/favorites_provider.dart';
import 'package:faramas/screens/airbnb_booking_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../config/app_colors.dart';
import '../models/property_model.dart';
import '../services/property_service.dart';
import '../providers/auth_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PropertyDetailScreen extends StatefulWidget {
  final PropertyModel property;

  const PropertyDetailScreen({required this.property, super.key});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

UserModel? currentUser;

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  bool _showFullDescription = false;
  int _currentImageIndex = 0;
  bool _isBooking = false;
  late PropertyModel _currentProperty;
  final formatter = NumberFormat("#,##0", "en_US");
  UserModel? currentUser;

  String getTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return "Unknown";

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute(s) ago';
    }
    if (difference.inHours < 24) return '${difference.inHours} hour(s) ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} day(s) ago';

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  void initState() {
    super.initState();
    _currentProperty = widget.property;
    _loadCurrentUser();
  }




  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    // ignore: unused_local_variable
    final token = prefs.getString('token') ?? '';

    // Example: fetch user from API or stored JSON
    final userJson = prefs.getString('user');
    if (userJson != null) {
      setState(() {
        currentUser = UserModel.fromJson(jsonDecode(userJson));
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void showContactDialog(
      BuildContext context, String phoneNumber, String uploaderName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.phone_android,
                    size: 40, color: Colors.greenAccent),
                const SizedBox(height: 10),
                Text(
                  uploaderName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'Phone Number: $phoneNumber',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.white)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent[700],
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.call),
                      label: const Text('Call Now'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _makePhoneCall(phoneNumber);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// 🔹 Open WhatsApp Chat
  Future<void> _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: 'https://wa.me/$cleanPhone',
        package: 'com.whatsapp',
      );
      await intent.launch();
    } catch (e) {
      _showSnackBar('Could not open WhatsApp: $e');
    }
  }

// 🔹 Open SMS App
  Future<void> _openSMS(String phone) async {
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.SENDTO',
        data: 'smsto:$phone',
      );
      await intent.launch();
    } catch (e) {
      _showSnackBar('Could not open SMS app: $e');
    }
  }

// 🔹 Make a phone call
  void _makePhoneCall(String phoneNumber) {
    if (Platform.isAndroid) {
      final intent = AndroidIntent(
        action: 'android.intent.action.DIAL',
        data: Uri.encodeFull('tel:$phoneNumber'),
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      intent.launch();
    } else {
      launchUrl(Uri.parse('tel:$phoneNumber'));
    }
  }

  // ignore: unused_element
  Future<void> _bookProperty() async {
    debugPrint("Booking started for property: ${_currentProperty.name}");

    if (_currentProperty.isBooked) {
      _showAnimatedDialog(
        _currentProperty,
        type: DialogType.booked,
        message: 'This property is already secured.',
      );
      return;
    }
    debugPrint("Airbnb field: ${_currentProperty.airbnb}");
    if (_currentProperty.airbnb != null) {
      Navigator.of(context).pushNamed(
        '/airbnb-booking',
        arguments: _currentProperty,
      );
      return;
    }

    setState(() => _isBooking = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final accessToken = authProvider.accessToken;
      final user = authProvider.user;

      if (accessToken == null || user == null || user.id == null) {
        _showAnimatedDialog(
          _currentProperty,
          type: DialogType.booked,
          message: 'Please log in to book this property.',
        );
        return;
      }

      final response = await PropertyService.bookProperty(
        token: accessToken,
        propertyId: _currentProperty.id!,
        userId: user.id!,
      );

      if (response['payment_required'] == true) {
        _showAnimatedDialog(
          _currentProperty,
          type: DialogType.payment,
          message: response['message'] ??
              'To book this property, payment is required. Tap "Pay Now" to proceed.',
          onAction: () {
            Navigator.of(context).pop();
            Navigator.of(context)
                .pushNamed('/generatePayment', arguments: _currentProperty);
          },
        );
      } else if (response['success'] == true) {
        _showAnimatedDialog(
          _currentProperty,
          type: DialogType.success,
          message: response['message'] ?? 'Property booked successfully!',
        );
      } else {
        _showAnimatedDialog(
          _currentProperty,
          type: DialogType.booked,
          message: response['message'] ?? 'Booking failed. Please try again.',
        );
      }
    } catch (e) {
      _showAnimatedDialog(
        _currentProperty,
        type: DialogType.payment,
        message:
            'Booking failed or payment is required. Tap "Pay Now" to complete booking.',
        onAction: () {
          Navigator.of(context).pop();
          Navigator.of(context)
              .pushNamed('/generatePayment', arguments: _currentProperty);
        },
      );
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

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

  

  Widget _buildInfoIcon(IconData icon, String text) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 28),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  

  IconData _getFacilityIcon(String facilityName) {
    switch (facilityName.toLowerCase()) {
      case 'parking':
        return Icons.local_parking;
      case 'swimming pool':
        return Icons.pool;
      case 'gym':
        return Icons.fitness_center;
      case 'internet':
        return Icons.wifi;
      case 'air conditioning':
        return Icons.ac_unit;
      case 'security':
        return Icons.security;
      case 'garden':
        return Icons.park;
      default:
        return Icons.check;
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, color: AppColors.primary, size: 24),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final property = _currentProperty;

    

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
 
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              property.isBooked ? Icons.bookmark : Icons.bookmark_border,
              color: property.isBooked ? AppColors.primary : AppColors.error,
            ),
            onPressed: () {
              _showSnackBar(property.isBooked
                  ? 'Property is Secured, cannot bookmark.'
                  : 'Bookmark functionality not implemented yet');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
  Stack(
  children: [
    SizedBox(
      height: 300,
      width: double.infinity,
      child: Builder(
        builder: (context) {
          final images = property.safeImages;
          final videoUrl = property.videoUrl;

          final hasVideo =
              videoUrl != null && videoUrl.isNotEmpty;

          final totalCount = images.length + (hasVideo ? 1 : 0);

        
          print("IMAGES LENGTH: ${images.length}");
          print("IMAGES LIST: $images");
          print("VIDEO URL: $videoUrl");
          print("HAS VIDEO: $hasVideo");
          print("TOTAL PAGE COUNT: $totalCount");
        

          return PageView.builder(
            itemCount: totalCount, 
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });

              print("CURRENT PAGE INDEX: $index");
            },
            itemBuilder: (context, index) {
              print("BUILDING PAGE INDEX: $index");

             
              if (hasVideo && index == images.length) {
                print("SHOWING VIDEO AT INDEX: $index");

                return VideoPreviewPlayer(
                  videoSource: videoUrl!,
                );
              }

          
              if (index < images.length) {
                final imageUrl = images[index];

                print("SHOWING IMAGE: $imageUrl");

                return Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder:
                      (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      print("IMAGE LOADED SUCCESS: $imageUrl");
                      return child;
                    }
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print("IMAGE FAILED: $imageUrl");
                    print("ERROR: $error");

                    return Image.asset(
                      'assets/images/placeholder.png',
                      fit: BoxFit.cover,
                    );
                  },
                );
              }

              
              return Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              );
            },
          );
        },
      ),
    ),

   
    Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.center,
            colors: [
              Colors.black.withOpacity(0.35),
              Colors.transparent,
            ],
          ),
        ),
      ),
    ),

   
    Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Builder(
        builder: (_) {
          final images = property.safeImages;
          final videoUrl = property.videoUrl;

          final hasVideo =
              videoUrl != null && videoUrl.isNotEmpty;

          final totalCount = images.length + (hasVideo ? 1 : 0);

          print("DOT COUNT: $totalCount");

          if (totalCount <= 1) {
            return const SizedBox(); // hide dots if only 1 item
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalCount, (index) {
              return Container(
                width: 8,
                height: 8,
                margin:
                    const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentImageIndex == index
                      ? AppColors.primary
                      : Colors.grey.withOpacity(0.4),
                ),
              );
            }),
          );
        },
      ),
    ),
  ],
),
            Container(
              color: AppColors.background,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            getTimeAgo(property.createdAt),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              property.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              context
                                      .read<FavoritesProvider>()
                                      .isFavorite(_currentProperty)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: context
                                      .read<FavoritesProvider>()
                                      .isFavorite(_currentProperty)
                                  ? Colors.red
                                  : Colors.redAccent,
                            ),
                            onPressed: () {
                              setState(() {
                                context
                                    .read<FavoritesProvider>()
                                    .toggleFavorite(_currentProperty);
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: AppColors.secondary, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.address,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: property.category! == "Rent"
                              ? AppColors.primary
                              : Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "for ${property.category!}",
                          style: const TextStyle(color: AppColors.textLight),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (property.isBooked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'SECURED',
                            style: TextStyle(
                                color: AppColors.textLight,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${property.uploaderRole}',
                          style: const TextStyle(color: AppColors.textLight),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Property Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _showFullDescription
                        ? property.description
                        : '${property.description.substring(0, property.description.length > 100 ? 100 : property.description.length)}${property.description.length > 100 ? '... ' : ''}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  if (property.description.length > 100)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showFullDescription = !_showFullDescription;
                        });
                      },
                      child: Text(
                        _showFullDescription ? 'Read Less' : 'Read More',
                        style: const TextStyle(
                          color: AppColors.buttonSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Airbnb Details
                  if (property.airbnb != null) ...[
                    const Text(
                      "Short Stay Details",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoIcon(Icons.people,
                            "${property.airbnb!.maxGuests} Guests"),
                        _buildInfoIcon(
                            Icons.bed, "${property.airbnb!.bedrooms} Bedrooms"),
                        _buildInfoIcon(Icons.bathtub,
                            "${property.airbnb!.bathrooms} Bathrooms"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Amenities",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: property.airbnb!.amenities.map((amenity) {
                        IconData icon;
                        switch (amenity.toLowerCase()) {
                          case 'wifi':
                            icon = Icons.wifi;
                            break;
                          case 'kitchen':
                            icon = Icons.kitchen;
                            break;
                          case 'parking':
                            icon = Icons.local_parking;
                            break;
                          default:
                            icon = Icons.check;
                        }
                        return Chip(
                          avatar: Icon(icon, size: 18, color: Colors.white),
                          label: Text(amenity,
                              style: const TextStyle(color: Colors.white)),
                          backgroundColor: AppColors.primary,
                        );
                      }).toList(),
                    ),
                  ],

                  // Regular property facilities
                  if (property.airbnb == null &&
                      property.facilities.isNotEmpty) ...[
                    const Text(
                      'Facilities',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: property.facilities.map((facility) {
                        final iconData = _getFacilityIcon(facility.name);
                        return Chip(
                          avatar: Icon(iconData, size: 18, color: Colors.white),
                          label: Text(facility.name,
                              style: const TextStyle(color: Colors.white)),
                          backgroundColor: AppColors.primary,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Cost section for regular properties
                  if (property.airbnb == null) ...[
                    const Text(
                      'Cost of Living',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Property Price',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Text(
                                'Tzs. ${NumberFormat("#,##0", "en_US").format(property.price)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Maintenance Charges (Per Month)',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Text(
                                'Tzs ${property.maintenance}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Total Cost',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                'Tzs ${formatter.format(property.price + property.maintenance)}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Pricing for Airbnb properties
                  if (property.airbnb != null) ...[
                    const Text(
                      'Pricing',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Price per night',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            'Tzs. ${NumberFormat("#,##0", "en_US").format(property.price)}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Owner Info section
                  const Text(
                    'Owner Info',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (_currentProperty.category?.toLowerCase() == 'sale')
                          _buildActionButton(
                            icon: Icons.message,
                            label: 'Message',
                            onPressed: () {
                              final phone = _currentProperty.uploaderPhone;
                              if (phone != null && phone.isNotEmpty) {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20)),
                                  ),
                                  builder: (context) => Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Contact via',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Divider(),
                                        const SizedBox(height: 10),
                                        ListTile(
                                          leading: const Icon(Icons.sms,
                                              color: Colors.blue),
                                          title: const Text('Send SMS'),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _openSMS(phone);
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(
                                              FontAwesomeIcons.whatsapp,
                                              color: Colors.green),
                                          title: const Text('WhatsApp Message'),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _openWhatsApp(phone);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              } else {
                                _showSnackBar('Phone number not available');
                              }
                            },
                          ),
                        _buildActionButton(
                          icon: Icons.call,
                          label: 'Call',
                          onPressed: () {
                            final phone = _currentProperty.uploaderPhone;
                            if (phone != null && phone.isNotEmpty) {
                              _makePhoneCall(phone);
                            } else {
                              _showSnackBar('Phone number not available');
                            }
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.directions_walk,
                          label: 'Tour',
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              '/tour',
                              arguments: _currentProperty.id,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (property.airbnb != null)
                    SizedBox(
                      width: double.infinity,
                      child: Consumer<AuthProvider>(
                        builder: (context, authProvider, child) =>
                            ElevatedButton(
                          onPressed: (_currentProperty.isBooked) || _isBooking
                              ? null
                              : () async {
                                  // --- 1. Check login ---
                                  if (!authProvider.isAuthenticated) {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) =>
                                          AnimatedPaymentDialog(
                                        property: property,
                                        message:
                                            "You need to login to secure this booking.",
                                        type: DialogType.loginRequired,
                                        onAction: () {
                                          Navigator.of(context).pop();
                                          Navigator.of(context)
                                              .pushNamed(AppRoutes.login);
                                        },
                                      ),
                                    );
                                    return;
                                  }

                                  // --- 2. Check phone number ---
                                  final user = authProvider.user!;
                                  if (user.phone == null ||
                                      user.phone!.isEmpty) {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) =>
                                          AnimatedPaymentDialog(
                                        property: property,
                                        message:
                                            "Please update your phone number to continue.",
                                        type: DialogType
                                            .phoneRequired, // new type
                                        onAction: () {
                                          Navigator.of(context).pop();
                                          Navigator.of(context)
                                              .pushNamed("/edit_profile");
                                        },
                                      ),
                                    );
                                    return;
                                  }

                                  // --- 3. Proceed to booking ---
                                  setState(() => _isBooking = true);
                                  try {
                                    final token = authProvider.accessToken!;
                                    debugPrint("Booking User ID: ${user.id}");
                                    debugPrint(
                                        "Booking Property ID: ${property.id}");

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AirbnbBookingScreen(
                                          property: property,
                                          token: token,
                                          user: user,
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Error: $e"),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } finally {
                                    setState(() => _isBooking = false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (_currentProperty.isBooked)
                                ? Colors.grey
                                : AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: _isBooking
                              ? const CircularProgressIndicator(
                                  color: AppColors.textLight)
                              : Text(
                                  (_currentProperty.isBooked)
                                      ? 'Property Secured'
                                      : 'Secure Booking',
                                  style: const TextStyle(
                                      color: AppColors.textLight),
                                ),
                        ),
                      ),
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum DialogType {
  payment,
  booked,
  success,
  loginRequired,
  phoneRequired
} // added loginRequired

class AnimatedPaymentDialog extends StatefulWidget {
  final PropertyModel property;
  final String message;
  final DialogType type;
  final VoidCallback? onAction;

  const AnimatedPaymentDialog({
    required this.property,
    required this.message,
    required this.type,
    this.onAction,
    super.key,
  });

  @override
  State<AnimatedPaymentDialog> createState() => _AnimatedPaymentDialogState();
}

class _AnimatedPaymentDialogState extends State<AnimatedPaymentDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _bounceController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _bounceAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleController.forward();
    _bounceController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _bounceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;
    String title;
    bool showActionButton = false;
    String actionText = '';

    switch (widget.type) {
      case DialogType.payment:
        icon = Icons.payment_rounded;
        iconColor = AppColors.primary;
        title = 'Payment Required';
        showActionButton = true;
        actionText = 'Pay Now';
        break;
      case DialogType.booked:
        icon = Icons.cancel_rounded;
        iconColor = Colors.red;
        title = 'Already Booked';
        break;
      case DialogType.success:
        icon = Icons.check_circle_rounded;
        iconColor = Colors.green;
        title = 'Success';
        break;
      case DialogType.loginRequired:
        icon = Icons.login_rounded;
        iconColor = Colors.orange;
        title = 'Login Required';
        showActionButton = true;
        actionText = 'Login Now';
        break;
      case DialogType.phoneRequired: // <-- new case
        icon = Icons.phone_iphone_rounded;
        iconColor = Colors.orange;
        title = 'Phone Number Required';
        showActionButton = true;
        actionText = 'Update Phone';
        break;
    }

    return Material(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 320,
                margin: const EdgeInsets.symmetric(horizontal: 30),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Color(0xFFF8F9FA)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 10,
                      offset: const Offset(0, 15),
                    ),
                    BoxShadow(
                      color: iconColor.withOpacity(0.1),
                      blurRadius: 40,
                      spreadRadius: 20,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated Icon
                      AnimatedBuilder(
                        animation: _bounceAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _bounceAnimation.value,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: widget.type != DialogType.payment
                                    ? iconColor.withOpacity(0.2)
                                    : null,
                                gradient: widget.type == DialogType.payment
                                    ? LinearGradient(
                                        colors: [
                                          AppColors.primary,
                                          AppColors.primary.withOpacity(0.7),
                                        ],
                                      )
                                    : null,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                icon,
                                color: iconColor,
                                size: 40,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Title
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Message
                      Text(
                        widget.message,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 25),

                      // Property info
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.home_rounded,
                                color: AppColors.primary,
                                size: 25,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.property.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Action button
                      if (showActionButton)
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: ElevatedButton.icon(
                                onPressed: widget.onAction ??
                                    () {
                                      Navigator.of(context).pop();
                                    },
                                icon: Icon(
                                  widget.type == DialogType.phoneRequired
                                      ? Icons.phone_iphone_rounded
                                      : Icons.payment_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                label: Text(actionText),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 20),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15)),
                                  backgroundColor:
                                      widget.type == DialogType.phoneRequired
                                          ? Colors.orange
                                          : AppColors.primary,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class VideoPreviewPlayer extends StatefulWidget {
  /// Can be a Base64 string OR a remote URL
  final String videoSource;

  const VideoPreviewPlayer({Key? key, required this.videoSource})
      : super(key: key);

  @override
  State<VideoPreviewPlayer> createState() => _VideoPreviewPlayerState();
}

class _VideoPreviewPlayerState extends State<VideoPreviewPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _loading = false;
  bool _error = false;

  String? _thumbnailPath;
  File? _videoFile;

  @override
  void initState() {
    super.initState();
    _prepareVideo();
  }

  // Prepare video (generate temp file if Base64, generate thumbnail)

  Future<void> _prepareVideo() async {
    setState(() => _loading = true);

    try {
      if (widget.videoSource.startsWith("http")) {
        // ------------------- Remote URL -------------------
        print("Detected remote URL: ${widget.videoSource}");

        // Generate thumbnail only
        final thumb = await VideoThumbnail.thumbnailFile(
          video: widget.videoSource,
          imageFormat: ImageFormat.PNG,
          maxHeight: 300,
          quality: 85,
        );

        setState(() => _thumbnailPath = thumb);
        print("Thumbnail generated: $thumb");
      } else {
        // ------------------- Base64 video -------------------
        print("🔹 Decoding Base64 video...");

        final cleanBase64 = widget.videoSource.split(',').last.trim();
        final bytes = base64Decode(cleanBase64);

        final tempDir = await getTemporaryDirectory();
        final videoPath =
            "${tempDir.path}/video_${DateTime.now().millisecondsSinceEpoch}.mp4";
        final file = File(videoPath);
        await file.writeAsBytes(bytes, flush: true);

        final thumb = await VideoThumbnail.thumbnailFile(
          video: videoPath,
          imageFormat: ImageFormat.PNG,
          maxHeight: 300,
          quality: 85,
        );

        setState(() {
          _videoFile = file;
          _thumbnailPath = thumb;
        });

        print("Base64 video saved to $videoPath");
        print("Thumbnail generated: $thumb");
      }
    } catch (e) {
      print("Error preparing video: $e");
      setState(() => _error = true);
    } finally {
      setState(() => _loading = false);
    }
  }

  // Initialize video controller

  Future<void> _initializeVideo() async {
    if (_initialized || _loading) return;

    setState(() => _loading = true);

    try {
      print("Initializing video controller...");

      VideoPlayerController controller;

      if (widget.videoSource.startsWith("http")) {
        controller = VideoPlayerController.network(widget.videoSource);
      } else {
        if (_videoFile == null) {
          print("Video file not ready yet!");
          setState(() => _loading = false);
          return;
        }
        controller = VideoPlayerController.file(_videoFile!);
      }

      await controller.initialize();

      controller.addListener(() {
        if (controller.value.hasError) {
          print("Video error: ${controller.value.errorDescription}");
        }
        if (controller.value.isPlaying) {
          print("Video is playing!");
        }
        if (mounted) setState(() {});
      });

      setState(() {
        _controller = controller;
        _initialized = true;
        _error = false;
      });

      print("Playing video...");
      await controller.play();
      print("Video PLAY executed!");
    } catch (e) {
      print("Video initialization failed: $e");
      setState(() => _error = true);
    } finally {
      setState(() => _loading = false);
    }
  }

  // Toggle play/pause

  void _togglePlayPause() {
    if (_controller == null) return;

    if (_controller!.value.isPlaying) {
      print("⏸ Pausing video...");
      _controller!.pause();
    } else {
      print("Playing video...");
      _controller!
          .play()
          .then((_) => print("🎬 Play executed"))
          .catchError((e) => print("Play failed: $e"));
    }

    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // Build UI

  @override
  Widget build(BuildContext context) {
    final isPlaying = _controller?.value.isPlaying ?? false;

    return Container(
      height: 240,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black12,
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video player
          if (_initialized && !_loading && !_error)
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),

          // Thumbnail
          if (!_initialized && _thumbnailPath != null)
            Image.file(
              File(_thumbnailPath!),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),

          // Fallback icon
          if (!_initialized && _thumbnailPath == null && !_loading)
            const Icon(Icons.video_library, color: Colors.white70, size: 80),

          // Loading spinner
          if (_loading) const Center(child: CircularProgressIndicator()),

          // Error message
          if (_error)
            const Center(
              child: Text(
                "Failed to load video",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),

          // Play button (before initialization)
          if (!_initialized && !_loading && !_error)
            GestureDetector(
              onTap: _initializeVideo,
              child: const Icon(
                Icons.play_circle_fill,
                size: 70,
                color: Colors.white,
              ),
            ),

          // Play/pause toggle (after initialization)
          if (_initialized && !_loading && !_error && _controller != null)
            GestureDetector(
              onTap: _togglePlayPause,
              child: Icon(
                isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                size: 70,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
