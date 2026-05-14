import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../constants/api_constants.dart';

class PropertyService {
  static Future<Map<String, dynamic>> fetchProperties({
    int page = 1,
  }) async {
    final url = '${ApiConstants.getProperties}?page=$page';
    final response = await http.get(
      Uri.parse(url),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    }
    throw Exception('Failed to load properties');
  }
}
