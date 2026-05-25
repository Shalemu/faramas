import 'dart:math';
import 'package:animate_do/animate_do.dart';
import 'package:faramas/config/app_colors.dart';
import 'package:faramas/providers/favorites_provider.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import '../models/property_model.dart';
import '../l10n/app_localizations.dart';
import 'property_detail_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String initialQuery;
  final String categoryFilter;
  final String locationLabel;
  final List<PropertyModel> allProperties;
  final double? currentLat;
  final double? currentLng;
  final String propertyType;

  const SearchResultsScreen({
    Key? key,
    required this.initialQuery,
    required this.categoryFilter,
    required this.locationLabel,
    required this.allProperties,
    required this.currentLat,
    required this.currentLng,
    required this.propertyType,
  }) : super(key: key);

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  List<PropertyModel> _searchResults = [];
  List<PropertyModel> _filteredResults = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _performSearch(widget.categoryFilter, widget.locationLabel);
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  void _performSearch(String category, String locationLabel) async {
    setState(() => _isLoading = true);

    final normalizedCategory = category.toLowerCase().trim();
    final normalizedLocation = locationLabel.toLowerCase().trim();
    final normalizedType = widget.propertyType.toLowerCase().trim();

    // Clean listing category
    String cleanedCategory = '';
    if (normalizedCategory.contains('sale'))
      cleanedCategory = 'sale';
    else if (normalizedCategory.contains('rent'))
      cleanedCategory = 'rent';
    else if (normalizedCategory.contains('sold')) cleanedCategory = 'sold';

    final position = await _getCurrentLocation();

    final filtered = widget.allProperties.where((p) {
      final propCategory = p.category?.toLowerCase().trim() ?? '';
      final propType = p.type.toLowerCase().trim();
      final region = p.region?.toLowerCase().trim() ?? '';
      final district = p.district?.toLowerCase().trim() ?? '';
      final address = p.address.toLowerCase().trim();

      // Match type
      bool matchesType =
          normalizedType.isEmpty || propType.contains(normalizedType);

      // Match category
      bool matchesCategory =
          cleanedCategory.isEmpty || propCategory.contains(cleanedCategory);

      // Match location
      bool matchesLocation = true;

      if (normalizedLocation == 'nearby' && position != null) {
        if (p.latitude != null && p.longitude != null) {
          double distance = calculateDistance(
            position.latitude,
            position.longitude,
            p.latitude!,
            p.longitude!,
          );
          if (distance > 20) return false;
        } else {
          return false;
        }
      } else if (normalizedLocation.isNotEmpty &&
          normalizedLocation != 'nearby') {
        final keywords = normalizedLocation
            .replaceAll(RegExp(r'[^\w\s]'), '')
            .split(' ')
            .where((word) => word != 'tanzania' && word.trim().isNotEmpty)
            .toList();

        matchesLocation = keywords.any((word) =>
            region.contains(word) ||
            district.contains(word) ||
            address.contains(word));
      }

      return matchesType && matchesCategory && matchesLocation;
    }).toList();

    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _searchResults = filtered;
      _filteredResults = filtered; // initially the same
      _isLoading = false;
    });
  }

  void _filterLocalResults(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      _filteredResults = _searchResults.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q) ||
            p.address.toLowerCase().contains(q);
      }).toList();
    });
  }

  String getTimeAgo(DateTime? dateTime, AppLocalizations localizations) {
    if (dateTime == null) return localizations.error;
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) return localizations.justNow;
    if (difference.inMinutes < 60)
      return '${difference.inMinutes} ${localizations.minutesAgo}';
    if (difference.inHours < 24)
      return '${difference.inHours} ${localizations.hoursAgo}';
    if (difference.inDays == 1) return localizations.yesterday;
    if (difference.inDays < 7)
      return '${difference.inDays} ${localizations.daysAgo}';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  void _openPropertyDetail(BuildContext context, PropertyModel property) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PropertyDetailScreen(property: property),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final hasResults = _searchResults.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.searchResults),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: localizations.searchHere,
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filterLocalResults, // <- update local results
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              Expanded(
                child: Center(
                  child: LoadingAnimationWidget.fourRotatingDots(
                    color: Colors.blue,
                    size: 50,
                  ),
                ),
              )
            else if (!hasResults)
              Expanded(
                child: Center(
                  child: Text(localizations.noPropertiesFound),
                ),
              )
            else
              Expanded(
                child: FadeInLeft(
                  // <- wrap the GridView here
                  duration: const Duration(milliseconds: 800),
                  child: GridView.builder(
                    itemCount: _filteredResults.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      final property = _searchResults[index];
                      return GestureDetector(
                        onTap: () => _openPropertyDetail(context, property),
                        child: Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    property.imageUrl != null &&
                                            property.imageUrl!.isNotEmpty
                                        ? Image.network(
                                            property.imageUrl!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                          )
                                        : property.images.isNotEmpty
                                            ? Image.network(
                                                property.images.first,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                              )
                                            : Container(
                                                color: Colors.grey[200],
                                                child: const Center(
                                                  child: Icon(
                                                      Icons.image_not_supported,
                                                      size: 40),
                                                ),
                                              ),
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${property.uploaderRole}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: property.category == "Rent"
                                              ? AppColors.primary
                                              : property.category == "Sale"
                                                  ? Colors.orange
                                                  : Colors.green,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          property.category == "Short Stay"
                                              ? localizations.airbnb
                                              : property.category == "Rent"
                                                  ? localizations.forRent
                                                  : property.category == "Sale"
                                                      ? localizations.forSale
                                                      : (property.category ??
                                                          ''),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Consumer<FavoritesProvider>(
                                        builder: (context, favoritesProvider,
                                            child) {
                                          final isFav = favoritesProvider
                                              .isFavorite(property);
                                          return IconButton(
                                            icon: Icon(
                                              isFav
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: isFav
                                                  ? Colors.red
                                                  : Colors.redAccent,
                                            ),
                                            onPressed: () {
                                              favoritesProvider
                                                  .toggleFavorite(property);
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      property.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Tsh. ${NumberFormat("#,##0", "en_US").format(property.price)}',
                                      style:
                                          const TextStyle(color: Colors.green),
                                    ),
                                    Text(
                                      getTimeAgo(
                                          property.createdAt, localizations),
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Calculate distance in km between two coordinates using Haversine formula
double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const p = 0.017453292519943295; // Pi / 180
  final a = 0.5 -
      cos((lat2 - lat1) * p) / 2 +
      cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a));
}
