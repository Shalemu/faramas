import 'dart:convert';
import 'package:faramas/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import '../models/tour_request_model.dart';

class TourRequestService {
  static Future<List<TourRequestModel>> fetchTourRequests(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse(ApiConstants.tourRequests),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      List<dynamic> results = data['results'];

      return results
          .map((e) => TourRequestModel.fromJson(e))
          .toList();
    } else {
      throw Exception('Failed to fetch tour requests');
    }
  }

  static Future<void> updateTourStatus({
    required String token,
    required int id,
    required bool complete,
  }) async {
    final response = await http.patch(
      Uri.parse('${ApiConstants.tourRequests}$id/'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: json.encode({
        'is_complete': complete,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update tour status');
    }
  }
}