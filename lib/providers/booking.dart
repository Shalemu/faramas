import 'dart:convert';
import 'package:faramas/constants/api_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/booking_model.dart';
import '../services/booking_services.dart';

class BookingProvider extends ChangeNotifier {
  final List<BookingModel> _bookings = [];
  final List<dynamic> _tourRequests = [];

  /// Unified getter for screens expecting 'bookings'
  List<BookingModel> get bookings => _bookings;

  /// Get tour requests separately
  List<dynamic> get tourRequests => _tourRequests;

  /// Set Short Stay bookings
  void setBookings(List<BookingModel> bookings) {
    _bookings
      ..clear()
      ..addAll(bookings);
    notifyListeners();
  }

  /// Set Tour Requests
  void setTourRequests(List<dynamic> requests) {
    _tourRequests
      ..clear()
      ..addAll(requests);
    notifyListeners();
  }

  /// Fetch all Short Stay bookings
  Future<void> fetchBookings(int uploaderId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) return;

    try {
      final fetched = await BookingServices.fetchAllBookingsForOwner(
        token: token,
        uploaderId: uploaderId,
      );
      setBookings(fetched);
      debugPrint("Short Stay bookings count: ${_bookings.length}");
    } catch (e) {
      debugPrint("Failed to fetch bookings: $e");
    }
  }

  /// Fetch Tour Requests
  Future<void> fetchTourRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.tourRequests),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> requests = data['results'] ?? [];

        // Sort by date + time
        requests.sort((a, b) {
          final dateTimeA = DateTime.tryParse("${a['date']} ${a['time']}:00");
          final dateTimeB = DateTime.tryParse("${b['date']} ${b['time']}:00");
          if (dateTimeA == null && dateTimeB == null) return 0;
          if (dateTimeA == null) return 1;
          if (dateTimeB == null) return -1;
          return dateTimeA.compareTo(dateTimeB);
        });

        setTourRequests(requests);
        debugPrint("Tour requests count: ${_tourRequests.length}");
      } else {
        debugPrint(
            "Failed to fetch Tour Requests: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("Error fetching tour requests: $e");
    }
  }

  /// Update booking status (for screens using short stay)
  Future<bool> updateBookingStatus(int bookingId, String newStatus) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return false;

    final oldStatus = _bookings[index].status;
    _bookings[index] = _bookings[index].copyWith(status: newStatus);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) return false;

      final url = Uri.parse(
        '${ApiConstants.bookingConfirmation}?booking_id=$bookingId&status=$newStatus',
      );
      final res = await http.get(url, headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });

      if (res.statusCode == 200) {
        debugPrint("Booking $bookingId updated to $newStatus successfully");
        return true;
      } else {
        _bookings[index] = _bookings[index].copyWith(status: oldStatus);
        notifyListeners();
        debugPrint(
            "Failed to update booking $bookingId: ${res.statusCode} - ${res.body}");
        return false;
      }
    } catch (e) {
      _bookings[index] = _bookings[index].copyWith(status: oldStatus);
      notifyListeners();
      debugPrint("Error updating booking $bookingId: $e");
      return false;
    }
  }

  /// Compute pending count including tour requests
  int get pendingCount {
    final shortStayPending =
        _bookings.where((b) => b.status.toLowerCase() == 'pending').length;
    final tourPending = _tourRequests
        .where((t) => (t['status'] ?? '').toLowerCase() == 'pending')
        .length;
    return shortStayPending + tourPending;
  }

  /// Fetch both bookings and tour requests
  Future<void> fetchAll(int uploaderId) async {
    await fetchBookings(uploaderId);
    await fetchTourRequests();
    debugPrint("Total pending count: $pendingCount");
  }
}
