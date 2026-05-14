import 'dart:async';
import 'dart:convert';
import 'package:faramas/config/app_routes.dart';
import 'package:faramas/models/ad_model';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../constants/api_constants.dart';
import '../models/property_model.dart';
import '../services/property_service.dart';
import '../widgets/category_icon.dart';
import 'property_detail_screen.dart';
import 'search_results_screen.dart';
import '../providers/favorites_provider.dart';
import 'package:intl/intl.dart';
import '../widgets/search_dropdown.dart';

class HomeContentScreen extends StatefulWidget {
  const HomeContentScreen({super.key});

  @override
  State<HomeContentScreen> createState() => _HomeContentScreenState();
}

class _HomeContentScreenState extends State<HomeContentScreen>
    with TickerProviderStateMixin {
  List<AdModel> _ads = [];
  bool _isLoadingAds = true;

  String? _selectedCategory;
  String? _selectedListingType;

  final Map<String, String> categoryFilterMap = {
    'Home': 'House',
    'Apartments': 'Apartment',
    'Rooms': 'Room',
    'Land': 'Land',
    'Office': 'Office',
    'Construction': 'Construction',
    'Short Stay': 'Short Stay',
  };

  List<PropertyModel> _featuredProperties = [];
  List<PropertyModel> _allProperties = [];
  bool _isLoading = true;
  String? _error;
  String? token;
  int _currentAdIndex = 0;
  late Timer _adTimer;
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  late final String propertyId;

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

    // Show full date for older posts
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  void initState() {
    super.initState();

    // Load ads
    _isLoadingAds = true;
    _loadAds();

    // Load properties
    _loadProperties();

    // Initialize PageController for smooth sliding
    _pageController = PageController(initialPage: 0);

    // Initialize fade animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Start fade animation
    _fadeController.forward();

    // Auto-slide timer with smooth animation
    _adTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && _pageController.hasClients && _ads.isNotEmpty) {
        final nextIndex = (_currentAdIndex + 1) % _ads.length;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  String normalizeCategory(String cat) {
    cat = cat.toLowerCase();
    if (cat.contains('sale')) return 'sale';
    if (cat.contains('rent')) return 'rent';
    if (cat.contains('sold')) return 'sold';
    return cat;
  }

// Fetch ads from API
  Future<List<AdModel>> fetchAds() async {
    try {
      final Uri url = Uri.parse(ApiConstants.ads);
      debugPrint("Fetching ads from: $url");

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List adsJson = (data['data'] is List && data['data'].isNotEmpty)
            ? data['data']
            : (data['total_item'] is List ? data['total_item'] : []);

        if (adsJson.isEmpty) {
          debugPrint("No ads found in response. Full response: $data");
          return [];
        }

        final ads = adsJson.map((json) => AdModel.fromJson(json)).toList();
        debugPrint("Successfully loaded ${ads.length} ads.");
        return ads;
      } else {
        debugPrint(
            "Ads API failed: ${response.statusCode} ${response.reasonPhrase}");
        debugPrint("Body: ${response.body}");
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint("Error fetching ads: $e");
      debugPrint("Stack trace: $stackTrace");
      return [];
    }
  }

// Load ads in your stateful widget
  Future<void> _loadAds() async {
    try {
      debugPrint("Loading ads...");
      final ads = await fetchAds();
      setState(() {
        _ads = ads;
        _isLoadingAds = false;
      });
      debugPrint("Loaded ${ads.length} ads successfully.");
    } catch (e, stackTrace) {
      debugPrint("Error in _loadAds(): $e");
      debugPrint("Stack trace: $stackTrace");
      setState(() {
        _isLoadingAds = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //_loadProperties(); // You already call this in initState, no need to call again.
  }

  Future<void> _loadProperties() async {
    final fetched = await PropertyService.fetchProperties(
      page: 1,
      pageSize: 1000, // Fetch a large number to have all properties
    );
    fetched.sort((a, b) {
      final aDate = a.createdAt ?? DateTime(2000);
      final bDate = b.createdAt ?? DateTime(2000);
      return bDate.compareTo(aDate); // newest → oldest
    });

    setState(() {
      _allProperties = fetched;
      _featuredProperties = List.from(fetched); // keep sorted copy
      _isLoading = false;
    });

    debugPrint("Property types available:");
    for (var p in _featuredProperties) {
      debugPrint("- ${p.type}");
    }
  }

  List<PropertyModel> get _filteredProperties {
    List<PropertyModel> filtered;

    if (_selectedCategory == null || _selectedCategory == 'Home') {
      filtered = List.from(_featuredProperties);
    } else {
      filtered = _featuredProperties.where((property) {
        bool matchesCategory = true;

        if (_selectedCategory != null) {
          if (_selectedCategory!.toLowerCase() == 'short stay') {
            // Filter by category
            matchesCategory = property.category?.toLowerCase() == 'short stay';
          } else {
            // Filter by type
            matchesCategory =
                property.type.toLowerCase() == _selectedCategory!.toLowerCase();
          }
        }

        final matchesListingType = _selectedListingType == null ||
            property.category?.toLowerCase() ==
                _selectedListingType!.toLowerCase();

        return matchesCategory && matchesListingType;
      }).toList();
    }

    filtered.sort((a, b) {
      final aDate = a.createdAt ?? DateTime(2000);
      final bDate = b.createdAt ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    return filtered;
  }

  void _openPropertyDetail(PropertyModel property) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PropertyDetailScreen(
          property: property, 
        ),
      ),
    );
  }

  void _showLocationErrorSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // drag indicator
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 20),

              // icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_off_rounded,
                  size: 32,
                  color: Colors.redAccent,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                "We couldn’t access your location",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Please enable location services so we can show nearby properties for you.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              // primary button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);

                    // try open location settings
                    await Geolocator.openLocationSettings();
                  },
                  child: const Text(
                    "Enable Location",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // secondary button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Not now",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onSearchSubmitted(String selectedListingType, String selectedLocation,
      String propertyType) async {
    final locationInput = selectedLocation.toLowerCase().trim();
    final typeInput = propertyType.toLowerCase().trim();
    final categoryInput = selectedListingType.toLowerCase().trim();

    // Normalize category
    String normalizedCategory = '';
    if (categoryInput.contains('sale')) {
      normalizedCategory = 'sale';
    } else if (categoryInput.contains('rent'))
      // ignore: curly_braces_in_flow_control_structures
      normalizedCategory = 'rent';
    // ignore: curly_braces_in_flow_control_structures
    else if (categoryInput.contains('sold')) normalizedCategory = 'sold';

    // Handle 'nearby' separately
    if (locationInput.contains('nearby')) {
      Position? currentPosition;
      try {
        currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
      } catch (e) {
        _showLocationErrorSheet();
        return;
      }

      final nearbyMatches = _allProperties.where((p) {
        if (p.latitude != null && p.longitude != null) {
          double distance = calculateDistance(
            currentPosition!.latitude,
            currentPosition.longitude,
            p.latitude!,
            p.longitude!,
          );
          return distance <= 20 &&
              (typeInput.isEmpty || p.type.toLowerCase().contains(typeInput)) &&
              (normalizedCategory.isEmpty ||
                  (p.category ?? '')
                      .toLowerCase()
                      .contains(normalizedCategory));
        }
        return false;
      }).toList();

      if (nearbyMatches.isNotEmpty) {
        _navigateToResults(selectedListingType, selectedLocation, propertyType,
            lat: currentPosition.latitude, lng: currentPosition.longitude);
      } else {
        _showMessage(
            "No nearby ${propertyType.toLowerCase()} properties for $normalizedCategory.");
      }
      return;
    }

    // Split input for search
    final normalizedInputWords = locationInput
        .replaceAll(',', '')
        .replaceAll('tanzania', '')
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .toList();

// New extended match that checks region, district, address, name/title, and description
    final locationMatches = _allProperties.where((p) {
      final region = (p.region ?? '').toLowerCase();
      final district = (p.district ?? '').toLowerCase();
      final address = p.address.toLowerCase();
      final name = p.name.toLowerCase();
      final description = p.description.toLowerCase();

      return normalizedInputWords.any((word) =>
          region.contains(word) ||
          district.contains(word) ||
          address.contains(word) ||
          name.contains(word) ||
          description.contains(word));
    }).toList();

    // Match with both type & category
    final fullMatches = locationMatches.where((p) {
      final propType = p.type.toLowerCase();
      final propCategory = (p.category ?? '').toLowerCase();
      return propType.contains(typeInput) &&
          propCategory.contains(normalizedCategory);
    }).toList();

    if (fullMatches.isNotEmpty) {
      _navigateToResults(selectedListingType, selectedLocation, propertyType);
      return;
    }

    print("User selected location: $selectedLocation");
    print("Normalized keywords: $normalizedInputWords");
    print("Properties matched by location: ${locationMatches.length}");
    print("User selected location: $selectedLocation");
    print("Normalized keywords: $normalizedInputWords");
    print("Properties matched by location: ${locationMatches.length}");
    for (var p in locationMatches) {
      print("- ${p.name} (${p.region}, ${p.district})");
    }

    // Partial Matches
    final categoryOnlyMatches = locationMatches.where((p) {
      final propCategory = (p.category ?? '').toLowerCase();
      return propCategory.contains(normalizedCategory);
    }).toList();

    final typeOnlyMatches = locationMatches.where((p) {
      final propType = p.type.toLowerCase();
      return propType.contains(typeInput);
    }).toList();

    if (categoryOnlyMatches.isNotEmpty && typeInput.isNotEmpty) {
      _showMessage(
          "${_capitalizeWords(selectedLocation)} has no ${propertyType.toLowerCase()} for $normalizedCategory.");
      return;
    }

    if (typeOnlyMatches.isNotEmpty && normalizedCategory.isNotEmpty) {
      _showMessage(
          "${_capitalizeWords(selectedLocation)} has no ${propertyType.toLowerCase()} for $normalizedCategory.");
      return;
    }

    if (locationMatches.isNotEmpty) {
      _showMessage(
          "${_capitalizeWords(selectedLocation)} has no matching ${propertyType.isNotEmpty ? '$propertyType ' : ''}${normalizedCategory.isNotEmpty ? 'for $normalizedCategory' : ''} properties.");
      return;
    }

    _showMessage(
        "No properties found in ${_capitalizeWords(selectedLocation)}.");
  }

  void _navigateToResults(String category, String location, String type,
      {double? lat, double? lng}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultsScreen(
          initialQuery: "$category in $location",
          categoryFilter: category,
          locationLabel: location,
          propertyType: type,
          allProperties: _allProperties,
          currentLat: lat,
          currentLng: lng,
        ),
      ),
    ).then((_) {
      setState(() {
        _selectedCategory = null;
        _selectedListingType = null;
        _searchController.clear();
        _loadProperties();
      });
    });
  }

  void _showMessage(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('No Results Found'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _capitalizeWords(String input) {
    return input
        .split(' ')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : '')
        .join(' ');
  }

  // Navigate to All Properties Screen - shows all properties like home screen
  void _navigateToAllProperties() {
    Navigator.of(context).pushNamed(
      AppRoutes.properties,
      arguments: null, // No filter, show all properties
    );
  }

  @override
  void dispose() {
    _adTimer.cancel();
    _pageController.dispose();
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchDropdown(
            controller: _searchController,
            onSearchSubmitted: (category, location, type) {
              _onSearchSubmitted(category, location, type);
            },
            onCategorySelected: (listingType) {
              setState(() {
                _selectedListingType =
                    listingType.toLowerCase().replaceAll('for ', '');
              });
            },
            allProperties: _allProperties,
            currentLat: null,
            currentLng: null,
            selectedCategory: '',
          ),
          const SizedBox(height: 12),

         
          // Enhanced Animated Ads Carousel
          Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Animated PageView
                  _isLoadingAds
                      ? const Center(child: CircularProgressIndicator())
                      : AnimatedBuilder(
                          animation: _fadeAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _fadeAnimation.value,
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: _ads.length,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentAdIndex = index;
                                  });
                                },
                                itemBuilder: (context, index) {
                                  final ad = _ads[index];
                                  final imageUrl =
                                      '${ApiConstants.baseUrl}${ad.image}';
                                  // e.g. http://161.97.65.175:9098/media/ads/4.jpg

                                  return Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            color: AppColors.primary
                                                // ignore: deprecated_member_use
                                                .withOpacity(0.1),
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.image,
                                                    size: 40,
                                                    color: AppColors.primary,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    ad.title,
                                                    style: const TextStyle(
                                                      color: AppColors.primary,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              // ignore: deprecated_member_use
                                              Colors.black.withOpacity(0.3),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            );
                          },
                        ),

                  // Page Indicators
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _ads.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentAdIndex == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentAdIndex == index
                                ? Colors.white
                                // ignore: deprecated_member_use
                                : Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                // ignore: deprecated_member_use
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Ad Label
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Ad',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = 'Home'; // Show all
                      _searchController.clear();
                    });
                  },
                  child: CategoryIcon(
                    icon: Icons.villa_rounded,
                    label: 'Home',
                    color: Colors.blue,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue, Colors.lightBlueAccent],
                    ),
                    isSelected: _selectedCategory == 'Home',
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = categoryFilterMap['Apartments'];
                      print('Filtered by: $_selectedCategory');
                    });
                  },
                  child: CategoryIcon(
                    icon: Icons.apartment_rounded,
                    label: 'Apartments',
                    color: Colors.orange,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.orange, Colors.deepOrange],
                    ),
                    isSelected:
                        _selectedCategory == categoryFilterMap['Apartments'],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = 'Short Stay';
                      print('Filtered by: $_selectedCategory');
                    });
                  },
                  child: const CategoryIcon(
                    icon: Icons.home_work_rounded,
                    label: 'Short Stay',
                    color: Colors.pink,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.pink, Colors.pinkAccent],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = categoryFilterMap['Land'];
                      print('Filtered by: $_selectedCategory');
                    });
                  },
                  child: CategoryIcon(
                    icon: Icons.landscape_rounded,
                    label: 'Land',
                    color: Colors.purple,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.purple, Colors.purpleAccent],
                    ),
                    isSelected: _selectedCategory == categoryFilterMap['Land'],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = 'Office';
                      print('Filtered by: $_selectedCategory');
                    });
                  },
                  child: CategoryIcon(
                    icon: Icons.work_rounded,
                    label: 'Office',
                    color: Colors.red,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.red, Colors.redAccent],
                    ),
                    isSelected: _selectedCategory == 'Office',
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = categoryFilterMap['Rooms'];
                      print('Filtered by: $_selectedCategory');
                    });
                  },
                  child: CategoryIcon(
                    icon: Icons.meeting_room_rounded,
                    label: 'Rooms',
                    color: Colors.green,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.green, Colors.lightGreen],
                    ),
                    isSelected: _selectedCategory == categoryFilterMap['Rooms'],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = 'Construction';
                      print('Filtered by: $_selectedCategory');
                    });
                  },
                  child: CategoryIcon(
                    icon: Icons.construction_rounded,
                    label: 'Construction',
                    color: Colors.red,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.red, Colors.redAccent],
                    ),
                    isSelected: _selectedCategory == 'Construction',
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _navigateToAllProperties();
                  },
                  child: const CategoryIcon(
                    icon: Icons.grid_view_rounded,
                    label: 'More',
                    color: Colors.grey,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.grey, Colors.blueGrey],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (_selectedCategory != null && _selectedCategory != 'Home')
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text('$_selectedCategory' 's'),
                ],
              ),
            ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!))
                  : _featuredProperties.isEmpty
                      ? const Center(child: Text("No properties found."))
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          // itemCount: _filteredProperties.length > 4
                          //     ? 4
                          //     : _filteredProperties.length,

                          itemCount: _filteredProperties.length,

                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemBuilder: (context, index) {
                            final property = _filteredProperties[index];
                            return GestureDetector(
                              onTap: () => _openPropertyDetail(property),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 18,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      /// ================= IMAGE =================
                                      Expanded(
                                        child: Stack(
                                          children: [
                                            Positioned.fill(
                                              child: property.imageUrl !=
                                                          null &&
                                                      property
                                                          .imageUrl!.isNotEmpty
                                                  ? Image.network(
                                                      property.imageUrl!,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : property.images.isNotEmpty
                                                      ? Image.network(
                                                          property.images.first,
                                                          fit: BoxFit.cover,
                                                        )
                                                      : Container(
                                                          color:
                                                              Colors.grey[200],
                                                          child: const Icon(
                                                            Icons
                                                                .image_not_supported,
                                                            size: 40,
                                                          ),
                                                        ),
                                            ),

                                            /// DARK GRADIENT OVERLAY (Airbnb style)
                                            Positioned.fill(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin:
                                                        Alignment.bottomCenter,
                                                    end: Alignment.center,
                                                    colors: [
                                                      Colors.black
                                                          .withOpacity(0.35),
                                                      Colors.transparent,
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),

                                            /// CATEGORY BADGE (clean + floating)
                                            Positioned(
                                              top: 10,
                                              left: 10,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: property.category ==
                                                          "Rent"
                                                      ? Colors.blue
                                                          .withOpacity(0.9)
                                                      : property.category ==
                                                              "Sale"
                                                          ? Colors.orange
                                                              .withOpacity(0.9)
                                                          : Colors.green
                                                              .withOpacity(0.9),
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                ),
                                                child: Text(
                                                  (property.category ?? '')
                                                          .isEmpty
                                                      ? 'Unknown'
                                                      : property.category ==
                                                              "Short Stay"
                                                          ? property.category!
                                                          : "For ${property.category!}",
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors
                                                        .white, // important for contrast
                                                  ),
                                                ),
                                              ),
                                            ),

                                            /// FAVORITE BUTTON (floating modern style)
                                            Positioned(
                                              top: 6,
                                              right: 6,
                                              child:
                                                  Consumer<FavoritesProvider>(
                                                builder: (context,
                                                    favoritesProvider, child) {
                                                  final isFav =
                                                      favoritesProvider
                                                          .isFavorite(property);

                                                  return Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.9),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: IconButton(
                                                      icon: Icon(
                                                        isFav
                                                            ? Icons.favorite
                                                            : Icons
                                                                .favorite_border,
                                                        color: isFav
                                                            ? Colors.red
                                                            : Colors.black54,
                                                        size: 20,
                                                      ),
                                                      onPressed: () {
                                                        favoritesProvider
                                                            .toggleFavorite(
                                                                property);
                                                      },
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),

                                            /// TIME (bottom overlay)
                                            Positioned(
                                              bottom: 10,
                                              left: 10,
                                              child: Text(
                                                getTimeAgo(property.createdAt),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      /// ================= CONTENT =================
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              property.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Tsh. ${NumberFormat("#,##0", "en_US").format(property.price)}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green.shade700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              property.description,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.black54,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
        ],
      ),
    );
  }

  // ignore: unused_element
  void _showDevelopmentDialog(BuildContext context, String label) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: const Text(
            'This is on development when it finish will be available'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
