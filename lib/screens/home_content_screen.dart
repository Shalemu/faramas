import 'dart:async';
import 'dart:convert';
import 'package:faramas/widgets/property_search_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../config/app_routes.dart';
import '../config/version_service.dart';
import '../constants/api_constants.dart';
import '../features/properties/controller/property_provider.dart';
import '../models/ad_model.dart';
import '../models/property_model.dart';
import '../providers/favorites_provider.dart';
import '../widgets/category_icon.dart';
import 'property_detail_screen.dart';

class HomeContentScreen extends StatefulWidget {
  const HomeContentScreen({super.key});

  @override
  State<HomeContentScreen> createState() => _HomeContentScreenState();
}

class _HomeContentScreenState extends State<HomeContentScreen>
    with TickerProviderStateMixin {
  /// ADS
  List<AdModel> _ads = [];

  bool _isLoadingAds = true;

  int _currentAdIndex = 0;

  late Timer _adTimer;

  late PageController _pageController;

  late AnimationController _fadeController;

  late Animation<double> _fadeAnimation;

  /// PAGINATION
  final ScrollController _scrollController = ScrollController();

  /// SEARCH
  final TextEditingController _searchController = TextEditingController();

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

  @override
  void initState() {
    super.initState();

    // check update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.check(context);
    });

    /// LOAD ADS
    _loadAds();

    /// LOAD PROPERTIES
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().refreshProperties();
    });

    /// SCROLL PAGINATION
    _scrollController.addListener(() {
      final provider = context.read<PropertyProvider>();

      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        provider.loadProperties();
      }
    });

    /// PAGE CONTROLLER
    _pageController = PageController(initialPage: 0);

    /// FADE ANIMATION
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeController.forward();

    /// AUTO SLIDE ADS
    _adTimer = Timer.periodic(
      const Duration(seconds: 4),
      (timer) {
        if (mounted && _pageController.hasClients && _ads.isNotEmpty) {
          final nextIndex = (_currentAdIndex + 1) % _ads.length;

          _pageController.animateToPage(
            nextIndex,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOutCubic,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _adTimer.cancel();

    _pageController.dispose();

    _fadeController.dispose();

    _scrollController.dispose();

    _searchController.dispose();

    super.dispose();
  }

  /// TIME AGO

  String getTimeAgo(DateTime? dateTime) {
    if (dateTime == null) {
      return "Unknown";
    }

    final now = DateTime.now();

    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute(s) ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} hour(s) ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} day(s) ago';
    }

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  /// FETCH ADS
  Future<List<AdModel>> fetchAds() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.ads),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        final List<dynamic> adsJson = data['result'] ?? [];

        return adsJson
            .map(
              (json) => AdModel.fromJson(json),
            )
            .toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// LOAD ADS

  Future<void> _loadAds() async {
    try {
      final ads = await fetchAds();

      if (!mounted) return;

      setState(() {
        _ads = ads;

        _isLoadingAds = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingAds = false;
      });
    }
  }

  /// FILTERED PROPERTIES

  List<PropertyModel> _filterProperties(List<PropertyModel> properties) {
    List<PropertyModel> filtered = List.from(properties);

    if (_selectedCategory != null && _selectedCategory != 'Home') {
      filtered = filtered.where((property) {
        bool matchesCategory = true;

        if (_selectedCategory!.toLowerCase() == 'short stay') {
          matchesCategory = property.category?.toLowerCase() == 'short stay';
        } else {
          matchesCategory =
              property.type.toLowerCase() == _selectedCategory!.toLowerCase();
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

  /// OPEN DETAIL

  void _openPropertyDetail(PropertyModel property) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyDetailScreen(
          property: property,
        ),
      ),
    );
  }

  /// NAVIGATE ALL

  void _navigateToAllProperties() {
    Navigator.of(context).pushNamed(
      AppRoutes.properties,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PropertyProvider>(
      builder: (context, provider, child) {
        final properties = _filterProperties(
          provider.properties,
        );

        return RefreshIndicator(
          onRefresh: provider.refreshProperties,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              /// SEARCH
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Consumer<PropertyProvider>(
                    builder: (context, provider, _) {
                      return Column(
                        children: [
                          PropertySearchWidget(
                            onSearch: (search) {
                              provider.onSearchChanged(search);
                            },
                          ),
                          const SizedBox(height: 10),
                          if (provider.isLoading)
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              /// ADS
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  child: _buildAdsCarousel(),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 12),
              ),

              /// CATEGORY
              SliverToBoxAdapter(
                child: _buildCategorySection(),
              ),

              /// TITLE
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Text(
                    'Featured',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              /// EMPTY
              if (properties.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No properties found.',
                    ),
                  ),
                )
              else

                /// GRID
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= properties.length) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final property = properties[index];

                        return _buildPropertyCard(
                          property,
                        );
                      },
                      childCount:
                          properties.length + (provider.hasMore ? 1 : 0),
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 30),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ADS CAROUSEL

  Widget _buildAdsCarousel() {
    /// LOADING
    if (_isLoadingAds) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    /// EMPTY
    if (_ads.isEmpty) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('No ads available'),
        ),
      );
    }

    /// CAROUSEL (REAL UI)
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
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
            /// PAGEVIEW
            AnimatedBuilder(
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
                      final imageUrl = '${ApiConstants.baseUrl}${ad.image}';

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return Container(
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.image, size: 40),
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
                                  Colors.black.withOpacity(0.35),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 14,
                            left: 14,
                            child: Text(
                              ad.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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

            /// INDICATORS
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_ads.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentAdIndex == index ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentAdIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// CATEGORY SECTION

  Widget _buildCategorySection() {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = 'Home';
              });
            },
            child: CategoryIcon(
              icon: Icons.villa_rounded,
              label: 'Home',
              color: Colors.blue,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue,
                  Colors.lightBlueAccent,
                ],
              ),
              isSelected: _selectedCategory == 'Home',
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = categoryFilterMap['Apartments'];
              });
            },
            child: CategoryIcon(
              icon: Icons.apartment_rounded,
              label: 'Apartments',
              color: Colors.orange,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.orange,
                  Colors.deepOrange,
                ],
              ),
              isSelected: _selectedCategory == categoryFilterMap['Apartments'],
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
            onTap: _navigateToAllProperties,
            child: const CategoryIcon(
              icon: Icons.grid_view_rounded,
              label: 'More',
              color: Colors.grey,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey,
                  Colors.blueGrey,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// PROPERTY CARD

  Widget _buildPropertyCard(PropertyModel property) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: property.imageUrl != null &&
                              property.imageUrl!.isNotEmpty
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
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                  ),
                                ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(
                            30,
                          ),
                        ),
                        child: Text(
                          property.category ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Consumer<FavoritesProvider>(
                        builder: (context, favoritesProvider, child) {
                          final isFav = favoritesProvider.isFavorite(property);

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.red : Colors.black54,
                                size: 20,
                              ),
                              onPressed: () {
                                favoritesProvider.toggleFavorite(property);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Text(
                        getTimeAgo(
                          property.createdAt,
                        ),
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
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
  }
}
