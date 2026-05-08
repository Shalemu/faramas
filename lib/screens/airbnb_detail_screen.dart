// lib/screens/airbnb_detail_screen.dart

import 'package:faramas/models/airbnb_property_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';

import '../services/airbnb_property_service.dart';
import '../providers/auth_provider.dart';

class AirbnbDetailScreen extends StatefulWidget {
  final AirbnbModel property;

  const AirbnbDetailScreen({required this.property, super.key});

  @override
  State<AirbnbDetailScreen> createState() => _AirbnbDetailScreenState();
}

class _AirbnbDetailScreenState extends State<AirbnbDetailScreen> {
  bool _showFullDescription = false;
  bool _isBooking = false;
  final formatter = NumberFormat("#,##0", "en_US");
  late AirbnbModel _currentProperty;
  int _currentImageIndex = 0;
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _guests = 1;

  @override
  void initState() {
    super.initState();
    _currentProperty = widget.property;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _bookProperty() async {
    if (_checkInDate == null || _checkOutDate == null) {
      _showSnackBar('Please select check-in and check-out dates.');
      return;
    }

    if (_guests > _currentProperty.maxGuests) {
      _showSnackBar('Number of guests exceeds maximum allowed (${_currentProperty.maxGuests}).');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final accessToken = authProvider.accessToken;

    if (user == null || accessToken == null) {
      _showSnackBar('Please log in to book this property.');
      return;
    }

    if (_currentProperty.isBooked) {
      _showSnackBar('This property is already booked for the selected dates.');
      return;
    }

    setState(() {
      _isBooking = true;
    });

    try {
      await AirbnbPropertyService.bookAirbnbProperty(
        token: accessToken,
        propertyId: _currentProperty.id!,
        userId: user.id!,
        checkInDate: _checkInDate!,
        checkOutDate: _checkOutDate!,
        guests: _guests,
      );

      setState(() {
        _isBooking = false;
        _currentProperty = _currentProperty.copyWith(isBooked: true);
      });

      _showSnackBar('Airbnb property booked successfully!');
    } catch (e) {
      setState(() {
        _isBooking = false;
      });
      _showSnackBar('Failed to book property: ${e.toString()}');
    }
  }

  Future<void> _selectDate(bool isCheckIn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
          // Reset checkout date if it's before checkin
          if (_checkOutDate != null && _checkOutDate!.isBefore(picked)) {
            _checkOutDate = null;
          }
        } else {
          if (_checkInDate != null && picked.isAfter(_checkInDate!)) {
            _checkOutDate = picked;
          } else {
            _showSnackBar('Check-out date must be after check-in date.');
          }
        }
      });
    }
  }

  int _calculateNights() {
    if (_checkInDate != null && _checkOutDate != null) {
      return _checkOutDate!.difference(_checkInDate!).inDays;
    }
    return 0;
  }

  double _calculateTotalCost() {
    final nights = _calculateNights();
    if (nights > 0) {
      return _currentProperty.getTotalStayCost(nights);
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final property = _currentProperty;
    final nights = _calculateNights();
    final totalCost = _calculateTotalCost();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: Icon(
                  property.isBooked
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  color: property.isBooked
                      ? AppColors.primary
                      : Colors.white,
                ),
                onPressed: () {
                  _showSnackBar(property.isBooked
                      ? 'Property is already booked.'
                      : 'Added to bookmarks.');
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  if (property.images.isNotEmpty)
                    PageView.builder(
                      itemCount: property.images.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return Image.network(
                          property.images[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        );
                      },
                    ),
                  // Image indicators
                  if (property.images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          property.images.length,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Property basic info
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              property.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${property.propertySubType} • ${property.type}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          property.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: property.isFavorite
                              ? Colors.red
                              : Colors.grey,
                        ),
                      onPressed: () {
                setState(() {
                  _currentProperty = _currentProperty.copyWith(
                    isFavorite: !(_currentProperty.isFavorite),
                  );
                });
              },

                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.address,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Property details
                  Row(
                    children: [
                      _buildDetailChip('${property.maxGuests} guests'),
                      const SizedBox(width: 8),
                      _buildDetailChip('${property.bedrooms} bedrooms'),
                      const SizedBox(width: 8),
                      _buildDetailChip('${property.bathrooms} bathrooms'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Host info
                  if (property.uploaderRole != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: property.uploaderImage != null
                                ? NetworkImage(property.uploaderImage!)
                                : null,
                            child: property.uploaderImage == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hosted by ${property.uploaderName ?? 'Host'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                property.uploaderRole!,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'About this place',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _showFullDescription
                        ? property.description
                        : '${property.description.substring(0, property.description.length > 150 ? 150 : property.description.length)}${property.description.length > 150 ? '...' : ''}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (property.description.length > 150)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showFullDescription = !_showFullDescription;
                        });
                      },
                      child: Text(
                        _showFullDescription ? 'Show less' : 'Show more',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Amenities
                  if (property.amenities.isNotEmpty) ...[
                    Text(
                      'Amenities',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: property.amenities.map((amenity) {
                        return Chip(
                          label: Text(amenity),
                          backgroundColor: Colors.grey[200],
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // House Rules
                  if (property.houseRules.isNotEmpty) ...[
                    Text(
                      'House Rules',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...property.houseRules.map((rule) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(child: Text(rule)),
                        ],
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],

                  // Check-in/out times
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.login, color: Colors.green),
                            const SizedBox(width: 8),
                            Text('Check-in: ${property.checkInTime}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.logout, color: Colors.red),
                            const SizedBox(width: 8),
                            Text('Check-out: ${property.checkOutTime}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Booking section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Tzs ${formatter.format(property.price)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(' / night'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Date selection
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectDate(true),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('CHECK-IN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                      Text(_checkInDate != null 
                                          ? DateFormat('MMM dd').format(_checkInDate!)
                                          : 'Add date'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectDate(false),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('CHECK-OUT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                      Text(_checkOutDate != null 
                                          ? DateFormat('MMM dd').format(_checkOutDate!)
                                          : 'Add date'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Guests selection
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('GUESTS'),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _guests > 1 ? () {
                                      setState(() {
                                        _guests--;
                                      });
                                    } : null,
                                    icon: const Icon(Icons.remove),
                                  ),
                                  Text('$_guests'),
                                  IconButton(
                                    onPressed: _guests < property.maxGuests ? () {
                                      setState(() {
                                        _guests++;
                                      });
                                    } : null,
                                    icon: const Icon(Icons.add),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        if (nights > 0) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Tzs ${formatter.format(property.price)} x $nights nights'),
                              Text('Tzs ${formatter.format(property.price * nights)}'),
                            ],
                          ),
                          if (property.cleaningFee > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Cleaning fee'),
                                Text('Tzs ${formatter.format(property.cleaningFee)}'),
                              ],
                            ),
                          ],
                          if (property.securityDeposit > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Security deposit'),
                                Text('Tzs ${formatter.format(property.securityDeposit)}'),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Tzs ${formatter.format(totalCost)}', 
                                   style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isBooking || (property.isBooked) ? null : _bookProperty,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isBooking
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  property.isBooked ? 'Already Booked' : 'Reserve',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
