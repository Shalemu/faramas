import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../config/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/property_model.dart';
import '../../../screens/property_detail_screen.dart';
import '../controller/property_provider.dart';

class PropertiesScreen extends StatefulWidget {
  final String? filter;

  const PropertiesScreen({
    super.key,
    this.filter,
  });

  @override
  State<PropertiesScreen> createState() =>
      _PropertiesScreenState();
}

class _PropertiesScreenState
    extends State<PropertiesScreen> {

  final ScrollController _scrollController =
  ScrollController();

  final TextEditingController _searchController =
  TextEditingController();

  Timer? _debounce;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {

      final provider =
      context.read<PropertyProvider>();

      provider.refreshProperties();
    });

    _scrollController.addListener(_onScroll);

    _searchController.addListener(_onSearchChanged);
  }

  void _onScroll() {

    final provider =
    context.read<PropertyProvider>();

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {

      provider.loadProperties();
    }
  }

  void _onSearchChanged() {

    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
    }

    _debounce = Timer(
      const Duration(milliseconds: 400),
          () {
        setState(() {
          _searchQuery =
              _searchController.text
                  .trim()
                  .toLowerCase();
        });
      },
    );
  }

  @override
  void dispose() {

    _debounce?.cancel();

    _scrollController.dispose();

    _searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final localizations =
    AppLocalizations.of(context);

    return Scaffold(

      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: Text(
          localizations?.allProperties ??
              "All Properties",
        ),
      ),

      body: Consumer<PropertyProvider>(
        builder: (context, provider, child) {

          final filteredProperties =
          provider.properties.where((property) {

            final matchesSearch =
                property.name
                    .toLowerCase()
                    .contains(_searchQuery) ||
                    property.description
                        .toLowerCase()
                        .contains(_searchQuery);

            final matchesFilter =
                widget.filter == null ||
                    widget.filter == 'Home' ||
                    property.type.toLowerCase() ==
                        widget.filter!
                            .toLowerCase();

            return matchesSearch &&
                matchesFilter;

          }).toList();

          /// FIRST LOADING
          if (provider.isLoading &&
              provider.properties.isEmpty) {

            return const Center(
              child:
              CircularProgressIndicator(),
            );
          }

          return RefreshIndicator(

            onRefresh:
            provider.refreshProperties,

            child: CustomScrollView(

              controller: _scrollController,

              physics:
              const AlwaysScrollableScrollPhysics(),

              slivers: [

                /// SEARCH
                SliverToBoxAdapter(
                  child: Padding(

                    padding:
                    const EdgeInsets.all(12),

                    child: TextField(

                      controller:
                      _searchController,

                      decoration:
                      InputDecoration(

                        hintText:
                        "Search properties...",

                        prefixIcon:
                        const Icon(
                          Icons.search,
                        ),

                        filled: true,

                        fillColor:
                        Colors.grey.shade100,

                        contentPadding:
                        const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),

                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(
                            14,
                          ),
                          borderSide:
                          BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),

                /// TITLE
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),

                    child: Text(
                      localizations
                          ?.availableProperties ??
                          'Available Properties',

                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 12),
                ),

                /// EMPTY STATE
                if (filteredProperties.isEmpty)

                  SliverFillRemaining(
                    hasScrollBody: false,

                    child: Center(
                      child: Text(
                        localizations
                            ?.noPropertiesAvailable ??
                            'No properties found',
                      ),
                    ),
                  )

                else

                /// GRID
                  SliverPadding(

                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),

                    sliver: SliverGrid(

                      delegate:
                      SliverChildBuilderDelegate(

                            (context, index) {

                          /// PAGINATION LOADER
                          if (index >=
                              filteredProperties
                                  .length) {

                            return const Center(
                              child:
                              CircularProgressIndicator(),
                            );
                          }

                          final property =
                          filteredProperties[
                          index];

                          return _PropertyCard(
                            property: property,

                            onTap: () {

                              Navigator.push(
                                context,

                                MaterialPageRoute(
                                  builder: (_) =>
                                      PropertyDetailScreen(
                                        property:
                                        property,
                                      ),
                                ),
                              );
                            },
                          );
                        },

                        childCount:
                        filteredProperties
                            .length +
                            (provider.hasMore
                                ? 1
                                : 0),
                      ),

                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(

                        crossAxisCount: 2,

                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,

                        childAspectRatio: 0.72,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 24),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// PROPERTY CARD

class _PropertyCard
    extends StatelessWidget {

  final PropertyModel property;

  final VoidCallback onTap;

  const _PropertyCard({
    required this.property,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return GestureDetector(

      onTap: onTap,

      child: Card(

        elevation: 3,

        shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(18),
        ),

        clipBehavior: Clip.antiAlias,

        child: Column(

          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            /// IMAGE
            Expanded(
              child: Stack(

                children: [

                  Positioned.fill(

                    child:
                    property.imageUrl !=
                        null &&
                        property.imageUrl!
                            .isNotEmpty

                        ? Image.network(
                      property.imageUrl!,
                      fit: BoxFit.cover,
                    )

                        : property
                        .images
                        .isNotEmpty

                        ? Image.network(
                      property
                          .images
                          .first,
                      fit:
                      BoxFit.cover,
                    )

                        : Container(
                      color:
                      Colors.grey[200],

                      child:
                      const Icon(
                        Icons
                            .image_not_supported,
                      ),
                    ),
                  ),

                  Positioned(
                    top: 10,
                    right: 10,

                    child: Container(

                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),

                      decoration:
                      BoxDecoration(

                        color:
                        property.category ==
                            "Rent"

                            ? AppColors.primary

                            : property.category ==
                            "Sale"

                            ? Colors.orange

                            : Colors.green,

                        borderRadius:
                        BorderRadius.circular(
                          20,
                        ),
                      ),

                      child: Text(

                        property.category ??
                            'Unknown',

                        style:
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// CONTENT
            Padding(

              padding:
              const EdgeInsets.all(10),

              child: Column(

                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  Text(

                    property.name,

                    maxLines: 1,

                    overflow:
                    TextOverflow.ellipsis,

                    style:
                    const TextStyle(
                      fontWeight:
                      FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(

                    'Tsh ${NumberFormat("#,##0", "en_US").format(property.price)}',

                    style: TextStyle(
                      color:
                      Colors.green.shade700,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(

                    property.description,

                    maxLines: 2,

                    overflow:
                    TextOverflow.ellipsis,

                    style:
                    const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}