import 'dart:convert';
import 'package:faramas/constants/api_constants.dart';
import 'package:faramas/models/booking_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BookingServices {

 static Future<Map<String, dynamic>> bookProperty({
    required String token,
    required int propertyId,
    required int userId,
  }) async {
    final url = Uri.parse(
        '${ApiConstants.booking}?property_id=$propertyId&user_id=$userId');

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Booking response code: ${response.statusCode}');

      final data = jsonDecode(response.body);

      // Return values
      bool success = false;
      bool paymentRequired = false;
      bool redirectToPayment = false;
      String message = 'Failed to book property.';

      // Handle HTTP status codes
      if (response.statusCode == 200 || response.statusCode == 201) {
        success = data['success'] ?? true;
        paymentRequired = data['payment_required'] ?? false;
        redirectToPayment = data['redirect_to_payment'] ?? false;
        message =
            data['msg'] ?? data['message'] ?? 'Property booked successfully!';
      } else if (response.statusCode == 402) {
        // Payment required
        success = false;
        paymentRequired = true;
        redirectToPayment = data['redirect_to_payment'] ?? true;
        message = data['error'] ?? 'Payment required to book this property.';
      } else if (response.statusCode == 401) {
        // Unauthorized / if  token is invalid
        success = false;
        paymentRequired = false;
        redirectToPayment = false;
        message =
            data['detail'] ?? 'Authentication failed. Please log in again.';
      } else {
        success = false;
        paymentRequired = false;
        redirectToPayment = false;
        message = data['error'] ?? data['msg'] ?? 'Failed to book property.';
      }

      return {
        'success': success,
        'payment_required': paymentRequired,
        'redirect_to_payment': redirectToPayment,
        'message': message,
      };
    } catch (e) {
      debugPrint('Exception in bookProperty: $e');
      return {
        'success': false,
        'payment_required': false,
        'redirect_to_payment': false,
        'message': 'Error booking property: ${e.toString()}',
      };
    }
  }

  // Book Airbnb property
  static Future<Map<String, dynamic>> bookAirbnbProperty({
    required String token,
    required int propertyId,
    required int userId,
    required String checkInDate,
    required String checkOutDate,
    required int adults,
    required int children,
    required String guestName,
    required String guestPhone,
    required String guestEmail,
    String notes = '',
    required int totalNights,
    required double totalCost,
  }) async {
    final url = Uri.parse(ApiConstants.airbnbBooking);

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "property_id": propertyId,
          "user_id": userId,
          "check_in_date": checkInDate,
          "check_out_date": checkOutDate,
          "adults": adults,
          "children": children,
          "guest_name": guestName,
          "guest_phone": guestPhone,
          "guest_email": guestEmail,
          "notes": notes,
          "total_nights": totalNights,
          "total_cost": totalCost,
          "status": "pending"
        }),
      );

      debugPrint("===== AIRBNB BOOKING RESPONSE =====");
      debugPrint("URL: $url");
      debugPrint("Status Code: ${response.statusCode}");

      final data = jsonDecode(response.body);

      bool success = false;
      bool paymentRequired = false;
      bool alreadyBooked = false;
      String message = 'Failed to book Airbnb property.';

      if (response.statusCode == 201 || response.statusCode == 200) {
        //Treat 200/201 as successful booking
        success = true;
        message = data['message'] ?? 'Airbnb property booked successfully!';
        paymentRequired = data['payment_required'] ?? false;
        alreadyBooked = data['already_booked'] ?? false;
      } else if (response.statusCode == 402) {
        paymentRequired = true;
        message = data['error'] ?? 'Payment required to book this property.';
      } else if (response.statusCode == 409) {
        alreadyBooked = true;
        message = data['error'] ?? 'This property is already booked.';
      } else if (response.statusCode == 401) {
        message =
            data['detail'] ?? 'Authentication failed. Please log in again.';
      } else {
        message =
            data['error'] ?? data['msg'] ?? 'Failed to book Airbnb property.';
      }

      return {
        'success': success,
        'payment_required': paymentRequired,
        'already_booked': alreadyBooked,
        'message': message,
        'data': data,
      };
    } catch (e) {
      debugPrint(e.toString());

      return {
        'success': false,
        'payment_required': false,
        'already_booked': false,
        'message': 'Error booking Airbnb property: ${e.toString()}',
      };
    }
  }

  //Fetch bookings for a user
  static Future<List<BookingModel>> fetchMyBookings({
    required String token,
    int? userId,
  }) async {
    final url = Uri.parse('${ApiConstants.booking}?user_id=$userId');
    try {
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final List<dynamic> bookingsJson = jsonDecode(response.body);
        return bookingsJson.map((json) => BookingModel.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load bookings: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
      rethrow;
    }
  }

  static Future<void> toggleSecureProperty({
    required String token,
    required int propertyId,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.secureProperties}?property_id=$propertyId',
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200 || response.statusCode != 201) {
      debugPrint('Failed secure toggle: ${response.statusCode}');
      debugPrint(response.body);
      throw Exception('Failed to toggle secure status');
    }
  }


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