import 'package:faramas/screens/upload_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../models/property_model.dart'; // Import your PropertyModel
import '../providers/auth_provider.dart'; // Import your AuthProvider
import '../services/property_service.dart'; // Import your PropertyService
import 'edit_property_screen.dart';
// ignore: unused_import
import 'property_detail_screen.dart'; // To navigate to property details

class MyPostedPropertiesScreen extends StatefulWidget {
  const MyPostedPropertiesScreen({super.key});

  @override
  State<MyPostedPropertiesScreen> createState() =>
      _MyPostedPropertiesScreenState();
}

class _MyPostedPropertiesScreenState extends State<MyPostedPropertiesScreen> {
  late Future<List<PropertyModel>> _myPropertiesFuture;
  String? _accessToken;
  int? _currentUserId; // To store the logged-in user's ID
  List<PropertyModel> _properties = [];
  List<PropertyModel> _filteredProperties = [];

  final TextEditingController _searchController = TextEditingController();


  @override
  void initState() {
    super.initState();
   _searchController.addListener(_filterProperties);
    // _myPropertiesFuture is initialized in didChangeDependencies
  }

    @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_accessToken == null || _currentUserId == null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _accessToken = authProvider.accessToken;
      _currentUserId = authProvider.user?.id; 

      if (_accessToken != null && _currentUserId != null) {
        _fetchMyProperties();
      } else {
        // Handle case where user is not logged in or ID is missing
        setState(() {
          _myPropertiesFuture =
              Future.error('Authentication required. Please log in.');
        });
        _showSnackBar('Please log in to view your posted properties.',
            isError: true);
      }
    }
  }

    void _filterProperties() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredProperties = List.from(_properties);
      } else {
        _filteredProperties = _properties.where((property) {
          final name = property.name.toLowerCase();
          final address = property.address.toLowerCase();
          final category = property.category?.toLowerCase() ?? '';
          return name.contains(query) ||
              address.contains(query) ||
              category.contains(query);
        }).toList();
      }
    });
  }


void _fetchMyProperties() {
  if (_accessToken != null) {
    final future = PropertyService.fetchPropertiesByUploader(
      token: _accessToken!,
    );

    setState(() {
      _myPropertiesFuture = future;
    });

    future.then((properties) {
      setState(() {
        _properties = properties;
         _filteredProperties = List.from(_properties);
      });
    }).catchError((e) {
      _showSnackBar('Failed to load properties: $e', isError: true);
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

  void _confirmDeleteProperty(int propertyId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Property'),
        content: const Text(
          'Are you sure you want to delete this property? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _deleteProperty(propertyId);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProperty(int propertyId) async {
    setState(() {
     
    });
    try {
      await PropertyService.deleteProperty(
        token: _accessToken!,
        propertyId: propertyId,
      );
      _showSnackBar('Property deleted successfully!');
      _fetchMyProperties();
    } catch (e) {
      _showSnackBar(
          'Failed to delete property: ${e.toString().replaceFirst('Exception: ', '')}',
          isError: true);
    } finally {
      setState(() {
  
      });
    }
  }

Future<void> _toggleSecureProperty(int propertyId) async {
  try {
    await PropertyService.toggleSecureProperty(
      token: _accessToken!,
      propertyId: propertyId,
    );

  
    setState(() {
      final index = _properties.indexWhere((p) => p.id == propertyId);
      if (index != -1) {
        _properties[index] = _properties[index].copyWith(
          secured: !_properties[index].secured,
        );
      }
    });

    _showSnackBar('Property status updated!');
  } catch (e) {
    _showSnackBar('Failed: ${e.toString()}', isError: true);
    print('Error updating property $propertyId: $e');
  }
}




  @override
  Widget build(BuildContext context) {
  return Scaffold(
  backgroundColor: Colors.grey[100],
  appBar: AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    title: const Text(
      'My Posted Properties',
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
  body: FutureBuilder<List<PropertyModel>>(
    future: _myPropertiesFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 50),
                const SizedBox(height: 10),
                Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _fetchMyProperties, // Retry button
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        );
      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.textSecondary, size: 50),
              const SizedBox(height: 10),
              const Text(
                'You have not posted any properties yet.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const UploadScreen()),
                  );
                },
                child: const Text('Post New Property'),
              ),
            ],
          ),
        );
      } else {
        // Use _filteredProperties for search results
        final properties = _filteredProperties;

        return Column(
          children: [
            // --- Search Bar ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search here...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: Colors.grey[200],
                  filled: true,
                ),
              ),
            ),

            
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: properties.length,
                itemBuilder: (context, index) {
                  final property = properties[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            // Property image
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              child: property.imageUrl != null &&
                                      property.imageUrl!.isNotEmpty
                                  ? Image.network(property.imageUrl!,
                                      fit: BoxFit.cover, width: double.infinity)
                                  : property.images.isNotEmpty
                                      ? Image.network(property.images.first,
                                          fit: BoxFit.cover,
                                          width: double.infinity)
                                      : Container(
                                          color: Colors.grey[200],
                                          child: const Center(
                                              child: Icon(
                                                  Icons.image_not_supported,
                                                  size: 40)),
                                        ),
                            ),

                            // Secure / Release badge (Top-left)
                            Positioned(
                              top: 12,
                              left: 12,
                              child: GestureDetector(
                                onTap: () =>
                                    _toggleSecureProperty(property.id!),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: property.secured
                                        ? Colors.green
                                        : Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        property.secured
                                            ? Icons.lock_open
                                            : Icons.lock,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        property.secured ? 'Release' : 'Secure',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Category badge (Top-right)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: property.category == "Rent"
                                      ? AppColors.primary
                                      : property.category == "Sale"
                                          ? Colors.orange
                                          : Colors.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  property.category == "Short Stay"
                                      ? "Airbnb"
                                      : "For ${property.category}",
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ),

                    
                            if (property.secured)
                              Positioned(
                                bottom: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'BOOKED',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      property.name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    'Tsh ${property.price}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E4B6C),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      property.address,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EditPropertyScreen(
                                                    property: property),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Edit Property'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFF1E4B6C),
                                        side: const BorderSide(
                                          color: Color(0xFF1E4B6C),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    onPressed: () =>
                                        _confirmDeleteProperty(property.id!),
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }
    },
  ),
);
  }
}
