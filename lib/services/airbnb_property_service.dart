// services/airbnb_property_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants/api_constants.dart';
import '../models/airbnb_property_model.dart';

class AirbnbPropertyService {
 
  Future<bool> createAirbnbProperty(
      AirbnbModel property, String token, List<String> imagePaths) async {
    final url = Uri.parse(ApiConstants.postProperties);
    try {
      if (property.latitude == null || property.longitude == null) {
        throw Exception('Latitude and Longitude must not be null.');
      }

      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      // Required fields
      request.fields['name'] = property.name;
      request.fields['type'] = property.type;
      request.fields['address'] = property.address;
      request.fields['latitude'] = property.latitude!.toStringAsFixed(6);
      request.fields['longitude'] = property.longitude!.toStringAsFixed(6);

      // Optional fields - fallback to empty string if null
      request.fields['region'] = property.region ?? '';
      request.fields['district'] = property.district ?? '';
      request.fields['category'] = 'Airbnb'; // Always set to Airbnb to differentiate

      request.fields['price'] = property.price.toString();
      request.fields['description'] = property.description;
      request.fields['total_price'] = property.totalPrice.toString();
      request.fields['maintenance'] = property.maintenance.toString();

      // Facilities encoded as JSON string
      request.fields['facilities'] = jsonEncode(property.facilities);

      // Airbnb-specific fields
      request.fields['max_guests'] = property.maxGuests.toString();
      request.fields['bedrooms'] = property.bedrooms.toString();
      request.fields['bathrooms'] = property.bathrooms.toString();
      request.fields['cleaning_fee'] = property.cleaningFee.toString();
      request.fields['check_in_time'] = property.checkInTime;
      request.fields['check_out_time'] = property.checkOutTime;
      request.fields['house_rules'] = jsonEncode(property.houseRules);
      request.fields['amenities'] = jsonEncode(property.amenities);
      request.fields['cancellation_policy'] = property.cancellationPolicy;
      request.fields['minimum_stay'] = property.minimumStay.toString();
      request.fields['maximum_stay'] = property.maximumStay.toString();
      request.fields['instant_book'] = property.instantBook.toString();
      request.fields['property_sub_type'] = property.propertySubType;
      request.fields['security_deposit'] = property.securityDeposit.toString();
      request.fields['safety_features'] = jsonEncode(property.safetyFeatures);
      request.fields['wifi_password'] = property.wifiPassword;
      request.fields['access_instructions'] = property.accessInstructions;

      // Add images
      for (int i = 0; i < imagePaths.length; i++) {
        final file = File(imagePaths[i]);
        if (await file.exists()) {
          final stream = http.ByteStream(file.openRead());
          final length = await file.length();
          final multipartFile = http.MultipartFile(
            'images',
            stream,
            length,
            filename: 'airbnb_image_$i.jpg',
            contentType: MediaType('image', 'jpeg'),
          );
          request.files.add(multipartFile);
        }
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      debugPrint('Airbnb Property Upload Response: ${response.statusCode}');
      debugPrint('Response Body: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint('Failed to create Airbnb property: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error creating Airbnb property: $e');
      return false;
    }
  }

  // Fetches all Airbnb properties from the server.
  static Future<List<AirbnbModel>?> fetchAirbnbProperties(String token) async {
    final url = Uri.parse('${ApiConstants.getProperties}?category=Airbnb');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Fetch Airbnb Properties Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AirbnbModel.fromJson(json)).toList();
      } else {
        debugPrint('Failed to fetch Airbnb properties: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching Airbnb properties: $e');
      return null;
    }
  }

  /// Fetches a specific Airbnb property by ID.
  static Future<AirbnbModel?> fetchAirbnbPropertyById(String token, int propertyId) async {
    final url = Uri.parse('${ApiConstants.propertyDetail}?property_id=$propertyId');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Fetch Airbnb Property Detail Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        // Only return if it's an Airbnb property
        if (data['category'] == 'Airbnb') {
          return AirbnbModel.fromJson(data);
        } else {
          debugPrint('Property is not an Airbnb property');
          return null;
        }
      } else {
        debugPrint('Failed to fetch Airbnb property: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching Airbnb property: $e');
      return null;
    }
  }

 
  static Future<bool> updateAirbnbProperty(
      String token, int propertyId, AirbnbModel property, List<String>? newImagePaths) async {
    final url = Uri.parse('${ApiConstants.propertyDetail}?property_id=$propertyId');
    try {
      var request = http.MultipartRequest('PUT', url);
      request.headers['Authorization'] = 'Bearer $token';

      // Add all the fields similar to create
      request.fields['name'] = property.name;
      request.fields['type'] = property.type;
      request.fields['address'] = property.address;
      request.fields['latitude'] = property.latitude!.toStringAsFixed(6);
      request.fields['longitude'] = property.longitude!.toStringAsFixed(6);
      request.fields['region'] = property.region ?? '';
      request.fields['district'] = property.district ?? '';
      request.fields['category'] = 'Airbnb';
      request.fields['price'] = property.price.toString();
      request.fields['description'] = property.description;
      request.fields['total_price'] = property.totalPrice.toString();
      request.fields['maintenance'] = property.maintenance.toString();
      request.fields['facilities'] = jsonEncode(property.facilities);

      // Airbnb-specific fields
      request.fields['max_guests'] = property.maxGuests.toString();
      request.fields['bedrooms'] = property.bedrooms.toString();
      request.fields['bathrooms'] = property.bathrooms.toString();
      request.fields['cleaning_fee'] = property.cleaningFee.toString();
      request.fields['check_in_time'] = property.checkInTime;
      request.fields['check_out_time'] = property.checkOutTime;
      request.fields['house_rules'] = jsonEncode(property.houseRules);
      request.fields['amenities'] = jsonEncode(property.amenities);
      request.fields['cancellation_policy'] = property.cancellationPolicy;
      request.fields['minimum_stay'] = property.minimumStay.toString();
      request.fields['maximum_stay'] = property.maximumStay.toString();
      request.fields['instant_book'] = property.instantBook.toString();
      request.fields['property_sub_type'] = property.propertySubType;
      request.fields['security_deposit'] = property.securityDeposit.toString();
      request.fields['safety_features'] = jsonEncode(property.safetyFeatures);
      request.fields['wifi_password'] = property.wifiPassword;
      request.fields['access_instructions'] = property.accessInstructions;

      // Add new images if provided
      if (newImagePaths != null) {
        for (int i = 0; i < newImagePaths.length; i++) {
          final file = File(newImagePaths[i]);
          if (await file.exists()) {
            final stream = http.ByteStream(file.openRead());
            final length = await file.length();
            final multipartFile = http.MultipartFile(
              'images',
              stream,
              length,
              filename: 'airbnb_image_$i.jpg',
              contentType: MediaType('image', 'jpeg'),
            );
            request.files.add(multipartFile);
          }
        }
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      debugPrint('Update Airbnb Property Response: ${response.statusCode}');
      debugPrint('Response Body: $responseBody');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating Airbnb property: $e');
      return false;
    }
  }

  /// Deletes an Airbnb property by ID.
  static Future<void> deleteAirbnbProperty({
    required String token,
    required int propertyId,
  }) async {
    final url = Uri.parse('${ApiConstants.propertyDetail}?property_id=$propertyId');
    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('Airbnb property deleted successfully');
      } else if (response.statusCode == 403) {
        throw Exception('Permission denied. You are not the owner of this Airbnb property.');
      } else if (response.statusCode == 404) {
        throw Exception('Airbnb property not found.');
      } else {
        throw Exception('Failed to delete Airbnb property: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Error deleting Airbnb property: $e');
      rethrow;
    }
  }

  /// Books an Airbnb property for a user with specific dates.
  static Future<Map<String, dynamic>> bookAirbnbProperty({
    required String token,
    required int propertyId,
    required int userId,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int guests,
  }) async {
    final url = Uri.parse('${ApiConstants.booking}?property_id=$propertyId&user_id=$userId');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'check_in_date': checkInDate.toIso8601String(),
          'check_out_date': checkOutDate.toIso8601String(),
          'guests': guests,
          'property_type': 'Airbnb',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['detail'] ?? errorData['msg'] ?? 'Failed to book Airbnb property.';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error booking Airbnb property: ${e.toString()}');
    }
  }

  /// Searches for Airbnb properties based on criteria.
  static Future<List<AirbnbModel>?> searchAirbnbProperties({
    required String token,
    String? location,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guests,
    double? minPrice,
    double? maxPrice,
    List<String>? amenities,
  }) async {
    var queryParams = <String, String>{
      'category': 'Airbnb',
    };

    if (location != null) queryParams['location'] = location;
    if (checkIn != null) queryParams['check_in'] = checkIn.toIso8601String();
    if (checkOut != null) queryParams['check_out'] = checkOut.toIso8601String();
    if (guests != null) queryParams['guests'] = guests.toString();
    if (minPrice != null) queryParams['min_price'] = minPrice.toString();
    if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
    if (amenities != null && amenities.isNotEmpty) {
      queryParams['amenities'] = amenities.join(',');
    }

    final uri = Uri.parse(ApiConstants.getProperties).replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Search Airbnb Properties Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AirbnbModel.fromJson(json)).toList();
      } else {
        debugPrint('Failed to search Airbnb properties: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error searching Airbnb properties: $e');
      return null;
    }
  }
}
