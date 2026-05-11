import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:faramas/models/booking_model.dart';
import 'package:http/http.dart' as http;
import 'package:faramas/models/property_model.dart';
import 'package:faramas/providers/auth_provider.dart';
import 'package:faramas/constants/api_constants.dart';

class PropertyService {
  int maxFileSize = 5 * 1024 * 1024; // 5 MB

  Future<Map<String, dynamic>> createProperty(
    PropertyModel property,
    String token,
    List<String> imagePaths, {
    String? videoPath,
  }) async {
    final url = Uri.parse(ApiConstants.postProperties);

    try {
      if (property.latitude == null || property.longitude == null) {
        throw Exception('Latitude and Longitude must not be null.');
      }

      final request = http.MultipartRequest('POST', url);

      // HEADERS
      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });

      debugPrint("HEADERS:");
      request.headers.forEach((k, v) => debugPrint("$k: $v"));

      // FIELDS
      request.fields.addAll({
        "name": property.name,
        "type": property.type,
        "address": property.address,
        "latitude": property.latitude!.toStringAsFixed(6),
        "longitude": property.longitude!.toStringAsFixed(6),
        "region": property.region ?? '',
        "district": property.district ?? '',
        "category": property.category ?? '',
        "price": property.price.toString(),
        "description": property.description,
        "total_price": property.totalPrice.toString(),
        "maintenance": property.maintenance.toString(),
        "is_booked": property.isBooked.toString(),
        "is_rent": property.isRent.toString(),
        "is_broker": property.isBroker.toString(),
      });

      request.fields.forEach((k, v) => debugPrint("$k: $v"));

      // FACILITIES
      request.fields["facilities"] = jsonEncode(
        property.facilities.map((f) => {"name": f.name}).toList(),
      );

      debugPrint("facilities: ${request.fields["facilities"]}");

      // IMAGES
      for (final path in imagePaths) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'images',
            path,
          ),
        );
      }

      if (videoPath != null && videoPath.isNotEmpty) {
        debugPrint("VIDEO UPLOAD: $videoPath");

        request.files.add(
          await http.MultipartFile.fromPath(
            'video',
            videoPath,
          ),
        );
      }

      debugPrint("Total Files: ${request.files.length}");
      debugPrint("REQUEST URL: $url");

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("STATUS CODE: ${response.statusCode}");
      debugPrint("RAW RESPONSE: ${response.body}");

      Map<String, dynamic> responseData = {};

      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        debugPrint("JSON PARSE ERROR: $e");
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint("PROPERTY CREATED SUCCESSFULLY");

        debugPrint("SENT FILES:");
        for (final file in request.files) {
          debugPrint("Field: ${file.field}, File: ${file.filename}");
        }
      } else {
        debugPrint("REQUEST FAILED");
      }

      return {
        "statusCode": response.statusCode,
        "data": responseData,
      };
    } catch (e, st) {
      debugPrint("ERROR: $e");
      debugPrint(st.toString());

      return {
        "statusCode": 500,
        "data": {"error": e.toString()},
      };
    }
  }

  Future<Map<String, dynamic>> postAirbnbProperty({
    required PropertyModel property,
    required AuthProvider authProvider,
    required List<String> imagePaths,
    String? videoPath,
  }) async {
    final url = Uri.parse(ApiConstants.postProperties);

    try {
      final request = http.MultipartRequest("POST", url);

      String? token = authProvider.accessToken;

      if (token == null || authProvider.isAccessTokenExpired()) {
        final refreshed = await authProvider.refreshToken();
        if (!refreshed) {
          return {
            "success": false,
            "status": 401,
            "message": "Session expired.",
          };
        }
        token = authProvider.accessToken;
      }

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });

      final airbnbBody = property.airbnb != null
          ? {
              "max_guests": property.airbnb!.maxGuests,
              "bedrooms": property.airbnb!.bedrooms,
              "bathrooms": property.airbnb!.bathrooms,
              "cleaning_fee": property.airbnb!.cleaningFee.toStringAsFixed(2),
              "check_in_time": "${property.airbnb!.checkInTime}:00",
              "check_out_time": "${property.airbnb!.checkOutTime}:00",
              "house_rules": property.airbnb!.houseRules,
              "amenities": property.airbnb!.amenities,
              "cancellation_policy": property.airbnb!.cancellationPolicy,
              "minimum_stay": property.airbnb!.minimumStay,
              "maximum_stay": property.airbnb!.maximumStay,
              "instant_book": property.airbnb!.instantBook,
              "property_sub_type": property.airbnb!.propertySubType,
              "security_deposit":
                  property.airbnb!.securityDeposit.toStringAsFixed(2),
              "safety_features": property.airbnb!.safetyFeatures,
              "wifi_password": property.airbnb!.wifiPassword,
              "access_instructions": property.airbnb!.accessInstructions,
            }
          : {};

      request.fields.addAll({
        "name": property.name,
        "type": property.type,
        "property_type": "Airbnb",
        "address": property.address,
        "price": property.price.toStringAsFixed(2),
        "category": property.category ?? "Short Stay",
        "description": property.description,
        "total_price": property.totalPrice.toStringAsFixed(2),
        "maintenance": property.maintenance.toStringAsFixed(2),
        "latitude": property.latitude?.toStringAsFixed(7) ?? "0.0000000",
        "longitude": property.longitude?.toStringAsFixed(7) ?? "0.0000000",
        "region": property.region ?? '',
        "district": property.district ?? '',
        "is_rent": property.isRent.toString(),
        "is_broker": property.isBroker.toString(),
        "is_booked": property.isBooked.toString(),
        "airbnb": jsonEncode(airbnbBody),
      });

      request.fields["facilities"] = jsonEncode(
        property.facilities.map((f) => {"name": f.name}).toList(),
      );

      debugPrint("facilities: ${request.fields["facilities"]}");

      for (final path in imagePaths) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'images',
            path,
          ),
        );
      }

      if (videoPath != null && videoPath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'video',
            videoPath,
          ),
        );
      }

      //  SEND
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("Status: ${response.statusCode}");
      debugPrint("Response: ${response.body}");

      final resJson = jsonDecode(response.body);

      return {
        "success": response.statusCode == 200 || response.statusCode == 201,
        "status": response.statusCode,
        ...resJson,
      };
    } catch (e, st) {
      debugPrint("Error posting Airbnb property: $e");
      debugPrint(st.toString());

      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }
  // Fetch all properties

  static Future<List<PropertyModel>> fetchProperties({
    int? page,
    int? pageSize,
  }) async {
    final url = Uri.parse(ApiConstants.getProperties);

    try {
      // --- No authentication required ---
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> results = data['results'] ?? data;

        return results
            .map<PropertyModel?>((item) {
              try {
                return PropertyModel.fromJson(item as Map<String, dynamic>);
              } catch (e) {
                debugPrint('Error parsing property JSON: $e');
                return null;
              }
            })
            .whereType<PropertyModel>()
            .toList();
      } else {
        debugPrint('Failed to fetch properties: HTTP ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Exception in fetchProperties: $e');
      return [];
    }
  }

  // Fetch properties by uploader
  static Future<List<PropertyModel>> fetchPropertiesByUploader({
    required String token,
  }) async {
    final url = Uri.parse(ApiConstants.uploader);
    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if API returns a list directly or wrapped in {"results": [...]}
        final List<dynamic> results = data is Map<String, dynamic>
            ? (data['results'] ?? [])
            : (data as List<dynamic>);

        final properties =
            results.map((json) => PropertyModel.fromJson(json)).toList();

        debugPrint("Uploader has ${properties.length} properties.");

        return properties;
      } else {
        debugPrint(
            'Failed to fetch uploader properties: HTTP ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching uploader properties: $e');
      return [];
    }
  }

  // Delete a property
  static Future<void> deleteProperty({
    required String token,
    required int propertyId,
  }) async {
    final url =
        Uri.parse('${ApiConstants.propertyDetail}?property_id=$propertyId');
    try {
      final response = await http.delete(url, headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200 || response.statusCode == 204) return;
      throw Exception(
          'Failed to delete property: ${response.statusCode} ${response.body}');
    } catch (e) {
      debugPrint('Error deleting property: $e');
      rethrow;
    }
  }

  // Book a property
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
      debugPrint('Booking response body: ${response.body}');

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
      debugPrint("Body: ${response.body}");

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
      debugPrint("===== AIRBNB BOOKING EXCEPTION =====");
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

    if (response.statusCode == 200) {
      debugPrint('Secure toggle success: $propertyId');
      debugPrint('Response: ${response.body}');
    } else {
      debugPrint('Failed secure toggle: ${response.statusCode}');
      debugPrint(response.body);
      throw Exception('Failed to toggle secure status');
    }
  }

  Future<Map<String, dynamic>> updateProperty(
    String token,
    String propertyId,
    PropertyModel property,
    List<Map<String, dynamic>> imageList, // Accept Map for filename & data
  ) async {
    final url = Uri.parse(
      '${ApiConstants.uploader}?property_id=$propertyId',
    );

    final body = {
      'name': property.name,
      'type': property.type,
      'category': property.category ?? "",
      'address': property.address,
      'price': property.price.toString(),
      'description': property.description,
      'is_rent': property.isRent,
      'facilities': property.facilities.map((f) => f.name).toList(),
      'images': imageList, // Already in correct format
    };

    debugPrint("Updating Property ID: $propertyId");
    debugPrint("Request body: $body");

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    debugPrint("Update Response Code: ${response.statusCode}");
    debugPrint("Update Response Body: ${response.body}");

    return {
      'statusCode': response.statusCode,
      'data': response.body.isNotEmpty ? jsonDecode(response.body) : {}
    };
  }
}
