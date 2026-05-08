import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/airbnb_booking_model.dart';

class AirbnbBookingService {
  static const String _baseUrl = ApiConstants.baseUrl;

  // Create a new Airbnb booking (following same pattern as PropertyService.bookProperty)
  static Future<Map<String, dynamic>> createBooking({
    required String token,
    required AirbnbBookingModel booking,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/airbnb-bookings/');
      
      // Create a clean JSON payload matching the API spec
      final requestBody = {
        'property_id': booking.propertyId,
        'user_id': booking.userId,
        'check_in_date': booking.checkInDate.toIso8601String(),
        'check_out_date': booking.checkOutDate.toIso8601String(),
        'adults': booking.adults,
        'children': booking.children,
        'guest_name': booking.guestName,
        'guest_phone': booking.guestPhone,
        'guest_email': booking.guestEmail,
        'notes': booking.notes,
        'total_nights': booking.totalNights,
        'total_cost': booking.totalCost,
        'status': booking.status,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('Airbnb booking request URL: $url');
      print('Airbnb booking request body: ${jsonEncode(requestBody)}');
      print('Airbnb booking response status: ${response.statusCode}');
      print('Airbnb booking response body: ${response.body}');

      final data = jsonDecode(response.body);

      // Return values following the same pattern as PropertyService.bookProperty
      bool success = false;
      bool paymentRequired = false;
      bool redirectToPayment = false;
      String message = 'Failed to create Airbnb booking.';

      // Handle HTTP status codes (same pattern as normal booking)
      if (response.statusCode == 200 || response.statusCode == 201) {
        success = data['success'] ?? true;
        paymentRequired = data['payment_required'] ?? false;
        redirectToPayment = data['redirect_to_payment'] ?? false;
        message = data['msg'] ?? data['message'] ?? 'Airbnb booking created successfully!';
      } else if (response.statusCode == 402) {
        // Payment required (subscription needed)
        success = false;
        paymentRequired = true;
        redirectToPayment = data['redirect_to_payment'] ?? true;
        message = data['error'] ?? 'Airbnb subscription required to complete booking.';
      } else if (response.statusCode == 401) {
        // Unauthorized / token invalid
        success = false;
        paymentRequired = false;
        redirectToPayment = false;
        message = data['detail'] ?? 'Authentication failed. Please log in again.';
      } else {
        // Other errors
        success = false;
        paymentRequired = false;
        redirectToPayment = false;
        message = data['error'] ?? data['msg'] ?? data['detail'] ?? 'Failed to create Airbnb booking.';
      }

      return {
        'success': success,
        'payment_required': paymentRequired,
        'redirect_to_payment': redirectToPayment,
        'message': message,
        'booking_id': data['data']?['id'] ?? data['id'],
      };
    } catch (e) {
      print('Exception in Airbnb createBooking: $e');
      return {
        'success': false,
        'payment_required': false,
        'redirect_to_payment': false,
        'message': 'Error creating Airbnb booking: ${e.toString()}',
      };
    }
  }

  // Get user's Airbnb bookings using query parameter
  static Future<List<AirbnbBookingModel>> getUserBookings({
    required String token,
    required String userId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/airbnb-bookings/user/$userId');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> bookingsJson = responseData['data'] ?? [];
        return bookingsJson
            .map((json) => AirbnbBookingModel.fromJson(json))
            .toList();
      } else {
        throw Exception(responseData['message'] ?? 'Failed to fetch user bookings');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Get booking by ID
  static Future<AirbnbBookingModel> getBookingById({
    required String token,
    required String bookingId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/airbnb-bookings/$bookingId');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AirbnbBookingModel.fromJson(responseData['data']);
      } else {
        throw Exception(responseData['message'] ?? 'Failed to fetch booking');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Update booking status
  static Future<Map<String, dynamic>> updateBookingStatus({
    required String token,
    required String bookingId,
    required String status, // pending, confirmed, cancelled
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/airbnb-bookings/$bookingId/status');
      
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': status,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Booking status updated successfully',
          'data': responseData['data'],
        };
      } else {
        throw Exception(responseData['message'] ?? 'Failed to update booking status');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Cancel booking
  static Future<Map<String, dynamic>> cancelBooking({
    required String token,
    required String bookingId,
    String? cancellationReason,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/airbnb-bookings/$bookingId/cancel');
      
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'cancellation_reason': cancellationReason,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Booking cancelled successfully',
          'data': responseData['data'],
        };
      } else {
        throw Exception(responseData['message'] ?? 'Failed to cancel booking');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Get property bookings using query parameter (for property owners)
  static Future<List<AirbnbBookingModel>> getPropertyBookings({
    required String token,
    required String propertyId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/airbnb-bookings/property/$propertyId');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> bookingsJson = responseData['data'] ?? [];
        return bookingsJson
            .map((json) => AirbnbBookingModel.fromJson(json))
            .toList();
      } else {
        throw Exception(responseData['message'] ?? 'Failed to fetch property bookings');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Get owner's all bookings using query parameter
  static Future<List<AirbnbBookingModel>> getOwnerBookings({
    required String token,
    required String ownerId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/airbnb-bookings/owner/$ownerId');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> bookingsJson = responseData['data'] ?? [];
        return bookingsJson
            .map((json) => AirbnbBookingModel.fromJson(json))
            .toList();
      } else {
        throw Exception(responseData['message'] ?? 'Failed to fetch owner bookings');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Check availability for dates
  static Future<Map<String, dynamic>> checkAvailability({
    required String token,
    required String propertyId,
    required DateTime checkInDate,
    required DateTime checkOutDate,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/airbnb-bookings/check-availability');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'property_id': propertyId,
          'check_in_date': checkInDate.toIso8601String(),
          'check_out_date': checkOutDate.toIso8601String(),
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'available': responseData['available'] ?? false,
          'message': responseData['message'] ?? '',
          'conflicting_bookings': responseData['conflicting_bookings'] ?? [],
        };
      } else {
        throw Exception(responseData['message'] ?? 'Failed to check availability');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }


  /// Uses existing customer orders endpoint to check for Airbnb subscriptions
  static Future<Map<String, dynamic>> checkAirbnbSubscription({
    required String token,
    required String userId,
  }) async {
    try {
      // Use existing customer orders endpoint to check for Airbnb subscription payments
      final url = Uri.parse('$_baseUrl/api/customer-orders?user_id=$userId');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Check Airbnb Subscription via Orders Response Status: ${response.statusCode}');
      print('Check Airbnb Subscription via Orders Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> orders = data['orders'] ?? data['results'] ?? [];
        
        // Look for recent Airbnb subscription payments (5000 TSH)
        final now = DateTime.now();
        bool hasActiveSubscription = false;
        DateTime? latestSubscriptionDate;
        
        for (var order in orders) {
          final amount = order['amount'] ?? 0;
          final description = (order['description'] ?? '').toString().toLowerCase();
          final createdAt = order['created_at'] ?? order['date'];
          
          // Check if this is an Airbnb subscription payment (5000 TSH)
          if (amount == 5000 && 
              (description.contains('airbnb') || description.contains('subscription'))) {
            
            if (createdAt != null) {
              try {
                final paymentDate = DateTime.parse(createdAt);
                final daysSincePayment = now.difference(paymentDate).inDays;
                
                // Subscription is valid for 30 days
                if (daysSincePayment <= 30) {
                  hasActiveSubscription = true;
                  if (latestSubscriptionDate == null || paymentDate.isAfter(latestSubscriptionDate)) {
                    latestSubscriptionDate = paymentDate;
                  }
                }
              } catch (e) {
                print('Error parsing payment date: $e');
              }
            }
          }
        }
        
        int daysRemaining = 0;
        DateTime? subscriptionExpiry;
        
        if (hasActiveSubscription && latestSubscriptionDate != null) {
          subscriptionExpiry = latestSubscriptionDate.add(const Duration(days: 30));
          daysRemaining = subscriptionExpiry.difference(now).inDays;
          if (daysRemaining < 0) {
            hasActiveSubscription = false;
            daysRemaining = 0;
          }
        }
        
        return {
          'hasActiveSubscription': hasActiveSubscription,
          'subscriptionExpiry': subscriptionExpiry?.toIso8601String(),
          'daysRemaining': daysRemaining,
          'message': hasActiveSubscription 
              ? 'Active Airbnb subscription found'
              : 'No active Airbnb subscription',
          'subscriptionStartDate': latestSubscriptionDate?.toIso8601String(),
          'lastPaymentDate': latestSubscriptionDate?.toIso8601String(),
        };
      } else if (response.statusCode == 404) {
        // Endpoint doesn't exist or no orders found
        print('Customer orders endpoint not found or no orders');
        return {
          'hasActiveSubscription': false,
          'subscriptionExpiry': null,
          'daysRemaining': 0,
          'message': 'No subscription history found',
          'subscriptionStartDate': null,
          'lastPaymentDate': null,
        };
      } else {
        // Other error
        print('Error checking subscription via orders: ${response.statusCode}');
        return {
          'hasActiveSubscription': false,
          'subscriptionExpiry': null,
          'daysRemaining': 0,
          'message': 'Unable to verify subscription status',
          'subscriptionStartDate': null,
          'lastPaymentDate': null,
        };
      }
    } catch (e) {
      print('Exception checking Airbnb subscription: $e');
      // On error, assume no subscription for safety
      return {
        'hasActiveSubscription': false,
        'subscriptionExpiry': null,
        'daysRemaining': 0,
        'message': 'Unable to verify subscription status',
        'subscriptionStartDate': null,
        'lastPaymentDate': null,
      };
    }
  }

  /// Get user's Airbnb subscription history
  static Future<List<Map<String, dynamic>>> getSubscriptionHistory({
    required String token,
    required String userId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/airbnb-subscription-history?user_id=$userId');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Subscription History Response Status: ${response.statusCode}');
      print('Subscription History Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['subscriptions'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      print('Error getting subscription history: $e');
      return [];
    }
  }

  /// Activate Airbnb subscription after payment
  static Future<Map<String, dynamic>> activateAirbnbSubscription({
    required String token,
    required String userId,
    required String paymentId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/activate-airbnb-subscription');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': userId,
          'payment_id': paymentId,
          'subscription_type': 'airbnb_monthly',
          'amount': 5000,
        }),
      );

      print('Activate Subscription Response Status: ${response.statusCode}');
      print('Activate Subscription Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Subscription activated successfully',
          'subscriptionExpiry': responseData['subscription_expiry'],
          'subscriptionStartDate': responseData['subscription_start_date'],
        };
      } else {
        throw Exception(responseData['message'] ?? 'Failed to activate subscription');
      }
    } catch (e) {
      print('Error activating subscription: $e');
      throw Exception('Network error: ${e.toString()}');
    }
  }
}
