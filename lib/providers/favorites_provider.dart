import 'package:flutter/material.dart';
import '../models/property_model.dart';

class FavoritesProvider extends ChangeNotifier {
  final List<PropertyModel> _favoriteProperties = [];

  List<PropertyModel> get favoriteProperties => List.unmodifiable(_favoriteProperties);

  bool isFavorite(PropertyModel property) {
    return _favoriteProperties.any((p) => p.id == property.id);
  }

  void toggleFavorite(PropertyModel property) {
    final index = _favoriteProperties.indexWhere((p) => p.id == property.id);
    if (index >= 0) {
      _favoriteProperties.removeAt(index);
    } else {
      _favoriteProperties.add(property);
    }
    notifyListeners();
  }
}
