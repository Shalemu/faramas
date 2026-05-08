import 'dart:async';
import 'package:faramas/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/property_model.dart';
import '../services/property_service.dart';
import '../l10n/app_localizations.dart';
import 'property_detail_screen.dart';

class PropertiesScreen extends StatefulWidget {
  final String? filter;

  const PropertiesScreen({super.key, this.filter});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  String? _routeFilter;
  late PageController _adPageController;
  Timer? _adTimer;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<PropertyModel> _allProperties = [];
  List<PropertyModel> _filteredProperties = [];
  bool _isLoading = true;
  String? _error;

  int _pageSize = 10;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isPaginating = false;

  @override
  void initState() {
    super.initState();
    _adPageController = PageController();
    _scrollController.addListener(_onScroll);

    // Add listener to search field
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_allProperties.isEmpty) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        _routeFilter = args['filter'] as String?;
      } else {
        _routeFilter = widget.filter;
      }
      _loadProperties(filter: _routeFilter);
    }
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    _adPageController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Fetch properties from API
  Future<void> _loadProperties({int page = 1, String? filter}) async {
    if (_isPaginating || !_hasMore) return;

    setState(() {
      if (page == 1) _isLoading = true;
      _isPaginating = true;
      _error = null;
    });

    try {
      final newProperties = await PropertyService.fetchProperties(
        page: page,
        pageSize: _pageSize,
      );

      List<PropertyModel> filteredList = newProperties;
      if (filter != null && filter != 'Home') {
        filteredList = newProperties
            .where((p) => p.type.toLowerCase() == filter.toLowerCase())
            .toList();
      }

      setState(() {
        if (page == 1) {
          _allProperties = filteredList;
        } else {
          _allProperties.addAll(filteredList.where(
              (p) => !_allProperties.any((existing) => existing.id == p.id)));
        }

        _filteredProperties = _allProperties;
        _currentPage = page;
        _hasMore = filteredList.length == _pageSize;
        _isLoading = false;
        _isPaginating = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isPaginating = false;
      });
    }
  }

  // Infinite scroll
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _loadProperties(page: _currentPage + 1);
    }
  }

  // Search filter logic
  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProperties = _allProperties;
      } else {
        _filteredProperties = _allProperties.where((property) {
          final nameMatch = property.name.toLowerCase().contains(query);
          final descMatch = property.description.toLowerCase().contains(query);
          return nameMatch || descMatch;
        }).toList();
      }
    });
  }

  // UI for the grid
  Widget _buildPropertyGrid() {
    if (_isLoading) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ));
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    if (_filteredProperties.isEmpty) {
      final localizations = AppLocalizations.of(context);
      return Center(
          child: Text(localizations?.noPropertiesAvailable ??
              "No properties found matching your search."));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredProperties.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        final property = _filteredProperties[index];
        return _PropertyCard(
          property: property,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PropertyDetailScreen(property: property),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.allProperties ?? "All Properties"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔍 Search Field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search properties...", // <-- fixed
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              localizations?.availableProperties ?? 'Available Properties',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildPropertyGrid(),

            if (_isPaginating)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

// ------------------ PROPERTY CARD WIDGET -------------------

class _PropertyCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onTap;

  const _PropertyCard({required this.property, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final localizations = AppLocalizations.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- IMAGE SECTION ---
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    if (property.imageUrl != null &&
                        property.imageUrl!.isNotEmpty)
                      Image.network(
                        property.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    else if (property.images.isNotEmpty)
                      Image.network(
                        property.images.first,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    else
                      _imagePlaceholder(),
                    // Category Label
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
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          property.category ?? 'Unknown', // <-- fixed
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- DETAILS SECTION ---
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat("#,##0", "en_US").format(property.price),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      property.description,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 40),
        ),
      );
}
