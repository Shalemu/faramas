import 'package:faramas/features/properties/services/property_service.dart';
import 'package:flutter/cupertino.dart';

import '../../../models/property_model.dart';

class PropertyProvider extends ChangeNotifier {
  List<PropertyModel> properties = [];

  bool isLoading = false;
  bool hasMore = true;

  int currentPage = 1;

  Future<void> refreshProperties() async {

    properties.clear();

    currentPage = 1;

    hasMore = true;

    isLoading = false;

    notifyListeners();

    await loadProperties();
  }

  Future<void> loadProperties() async {
    if (isLoading || !hasMore) return;

    isLoading = true;
    notifyListeners();

    try {
      final response = await PropertyService.fetchProperties(
        page: currentPage,
      );

      final List<dynamic> results = response['results'] as List<dynamic>;
      final fetched = results
          .map(
            (e) => PropertyModel.fromJson(e),
          )
          .toList();

      properties.addAll(fetched);

      hasMore = response['next'] != null;

      currentPage++;
    } catch (e) {
      debugPrint(e.toString());
    }

    isLoading = false;
    notifyListeners();
  }
}
