import 'dart:convert';
import 'package:faramas/constants/api_constants.dart';
import 'package:faramas/models/booking_model.dart';
import 'package:http/http.dart' as http;

class BookingServices {
  static Future<List<BookingModel>> fetchAirbnbBookings({
    required String token,
    required int uploaderId,
  }) async {
    final url = Uri.parse(ApiConstants.airbnbBooking);

    final headers = {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final List<BookingModel> bookings = [];

    final res = await http.get(url, headers: headers);

    if (res.statusCode == 200) {
      final data = json.decode(res.body)["data"];

      for (var b in data) {
        if (b["property"]["uploader"] == uploaderId) {
          bookings.add(
            BookingModel.fromJson(b).copyWith(
              isAirbnb: true,
            ),
          );
        }
      }
    } else {
      print("Failed to fetch Airbnb bookings: ${res.statusCode}");
      print("Response: ${res.body}");
    }

    return bookings;
  }

  static Future<List<BookingModel>> fetchNormalBookings({
    required String token,
    required int uploaderId,
  }) async {
    final url = Uri.parse(
      "${ApiConstants.booking}?owner_id=$uploaderId",
    );

    final headers = {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final List<BookingModel> bookings = [];

    final res = await http.get(url, headers: headers);

    if (res.statusCode == 200) {
      final data = json.decode(res.body);

      if (data is List) {
        for (var b in data) {
          bookings.add(
            BookingModel.fromJson(b),
          );
        }
      } else if (data["results"] != null) {
        for (var b in data["results"]) {
          bookings.add(
            BookingModel.fromJson(b),
          );
        }
      }
    } else {
      print("Failed to fetch Normal bookings: ${res.statusCode}");
      print("Response: ${res.body}");
    }

    return bookings;
  }

  /// Fetch all bookings (Airbnb + Normal)
  static Future<List<BookingModel>> fetchAllBookingsForOwner({
    required String token,
    required int uploaderId,
  }) async {
    final airbnb = await fetchAirbnbBookings(
      token: token,
      uploaderId: uploaderId,
    );

    final normal = await fetchNormalBookings(
      token: token,
      uploaderId: uploaderId,
    );

    final allBookings = [
      ...airbnb,
      ...normal,
    ];

    print("Airbnb bookings count: ${airbnb.length}");
    print("Normal bookings count: ${normal.length}");
    print("Total bookings count: ${allBookings.length}");

    return allBookings;
  }
}