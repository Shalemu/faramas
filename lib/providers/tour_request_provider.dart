import 'dart:convert';
import 'package:faramas/constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class TourRequestProvider extends ChangeNotifier {
  final List<dynamic> _tourRequests = [];

  List<dynamic> get tourRequests => _tourRequests;

  /// Number of pending requests
  int get pendingCount =>
      _tourRequests.where((r) => r['status'] == 'pending').length;

  /// Set tour requests locally
  void setTourRequests(List<dynamic> requests) {
    _tourRequests
      ..clear()
      ..addAll(requests);
    notifyListeners();
  }

  /// Fetch all tour requests
  Future<void> fetchTourRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.tourRequests),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> requests = data['results'] ?? [];

        // Sort by date+time
        requests.sort((a, b) {
          final dateTimeA = DateTime.tryParse("${a['date']} ${a['time']}:00");
          final dateTimeB = DateTime.tryParse("${b['date']} ${b['time']}:00");
          if (dateTimeA == null && dateTimeB == null) return 0;
          if (dateTimeA == null) return 1;
          if (dateTimeB == null) return -1;
          return dateTimeA.compareTo(dateTimeB);
        });

        setTourRequests(requests);
      } else {
        debugPrint("Failed to fetch tour requests: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching tour requests: $e");
    }
  }

  /// Update tour request status: 'accepted' or 'rejected'
  Future<void> updateTourStatus(int id, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    try {
      final url = Uri.parse(
        '${ApiConstants.confirmTourRequest}?request_id=$id&status=$status',
      );

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final index = _tourRequests.indexWhere((r) => r['id'] == id);
        if (index != -1) {
          _tourRequests[index]['status'] = status;
          _tourRequests[index]['is_complete'] = (status == 'accepted');
        }
        notifyListeners();
        debugPrint("Tour request $id updated to $status successfully.");
      } else {
        debugPrint("Failed to update tour request $id to $status.");
      }
    } catch (e) {
      debugPrint("Error updating tour request $id: $e");
    }
  }
}
