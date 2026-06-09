import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:faramas/constants/api_constants.dart';
import '../models/property_model.dart';

class SearchService {
  Future<List<PropertyModel>> searchProperties({
    String? search,
    int? page,
  }) async {
    final Map<String, String> queryParams = {};

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    if (page != null) {
      queryParams['page'] = page.toString();
    }

    final uri = Uri.parse(ApiConstants.getProperties)
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
      },
    );




    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      final List<dynamic> results =
          json['results'] ?? json['data'] ?? json['properties'] ?? [];

      return results.map((item) => PropertyModel.fromJson(item)).toList();
    }

    throw Exception(
      'Search failed (${response.statusCode}): ${response.body}',
    );
  }
}
