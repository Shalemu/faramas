import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_colors.dart';
import '../models/property_model.dart';
import 'property_detail_screen.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  void _openPropertyDetail(BuildContext context, PropertyModel property) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => PropertyDetailScreen(property: property)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, child) {
        final favoriteProperties = favoritesProvider.favoriteProperties;

        if (favoriteProperties.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('No favorite properties yet.')),
          );
        }

        return Scaffold(
        
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              itemCount: favoriteProperties.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (context, index) {
                final property = favoriteProperties[index];
                return GestureDetector(
                  onTap: () => _openPropertyDetail(context, property),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Stack(
                                children: [
                                  (property.imageUrl != null &&
                                          property.imageUrl!.isNotEmpty)
                                      ? Image.network(
                                          property.imageUrl!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: Icon(Icons.broken_image,
                                                  size: 40),
                                            ),
                                          ),
                                        )
                                      : property.images.isNotEmpty
                                          ? Image.network(
                                              property.images.first,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  Container(
                                                color: Colors.grey[200],
                                                child: const Center(
                                                  child: Icon(
                                                      Icons.broken_image,
                                                      size: 40),
                                                ),
                                              ),
                                            )
                                          : Container(
                                              color: Colors.grey[200],
                                              child: const Center(
                                                child: Icon(
                                                    Icons.image_not_supported,
                                                    size: 40),
                                              ),
                                            ),
                                ],
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    // ignore: deprecated_member_use
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    property.uploaderRole ?? '',
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
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    property.category == "Short Stay"
                                        ? "Airbnb"
                                        : "For ${property.category}",
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
                                child: IconButton(
                                  icon: Icon(
                                    favoritesProvider.isFavorite(property)
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color:
                                        favoritesProvider.isFavorite(property)
                                            ? Colors.red
                                            : Colors.redAccent,
                                  ),
                                  onPressed: () {
                                    favoritesProvider.toggleFavorite(property);
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
                                  fontWeight: FontWeight.bold,
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
                                  fontWeight: FontWeight.w600,
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
        );
      },
    );
  }
}
