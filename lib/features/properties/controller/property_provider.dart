import 'dart:async';
import 'package:flutter/material.dart';
import 'package:faramas/services/search_service.dart';
import '../../../models/property_model.dart';

class PropertyProvider extends ChangeNotifier {
  List<PropertyModel> properties = [];

  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;

  int currentPage = 1;

  String? _search;

  Timer? _debounce;

 
  void onSearchChanged(String search) {
    _search = search;

    // cancel previous timer
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    // start new timer (debounce 500ms)
    _debounce = Timer(const Duration(milliseconds: 500), () {
      searchProperties(search: search);
    });
  }


  Future<void> searchProperties({
    String? search,
  }) async {
    _search = search;

    properties.clear();
    currentPage = 1;
    hasMore = true;

    await loadProperties(reset: true);
  }

 
  Future<void> loadProperties({bool reset = false}) async {
    if (isLoading || isLoadingMore || !hasMore) return;

    if (reset) {
      isLoading = true;
    } else {
      isLoadingMore = true;
    }

    notifyListeners();

    try {
      final fetched = await SearchService().searchProperties(
        page: currentPage,
        search: _search,
      );

      if (reset) {
        properties = fetched;
      } else {
        properties.addAll(fetched);
      }

      hasMore = fetched.isNotEmpty;

      if (hasMore) {
        currentPage++;
      }
    } catch (e) {
      debugPrint("Load error: $e");
    }

    isLoading = false;
    isLoadingMore = false;
    notifyListeners();
  }


  Future<void> refreshProperties() async {
    _search = null;

    properties.clear();
    currentPage = 1;
    hasMore = true;

    await loadProperties(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}