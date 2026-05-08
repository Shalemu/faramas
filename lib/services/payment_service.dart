import 'dart:convert';
import 'package:faramas/constants/api_constants.dart';
import 'package:http/http.dart' as http;

class PaymentService {
  Future<List<dynamic>> getCustomerOrders(String customerId) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/api/customer-orders?customer_id=$customerId',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load customer orders');
    }
  }

  Future<String> requestPaymentUrl(String customerId) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/api/request-payment-url?customer_id=$customerId',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final rawBody = response.body;

      print('Raw payment URL response body: $rawBody');

      final data = json.decode(rawBody);

      if (data is List && data.isNotEmpty) {
        final firstItem = data[0];

        if (firstItem['payment_gateway_url'] != null) {
          return firstItem['payment_gateway_url'] as String;
        }
      } else if (data is Map) {
        if (data['payment_gateway_url'] != null) {
          return data['payment_gateway_url'] as String;
        } else if (data['payment_url'] != null) {
          return data['payment_url'] as String;
        } else if (data['url'] != null) {
          return data['url'] as String;
        } else if (data.values.any(
          (v) => v is String && v.contains('http'),
        )) {
          for (var value in data.values) {
            if (value is String && value.contains('http')) {
              return value;
            }
          }
        } else if (data['msg'] != null) {
          throw Exception(data['msg']);
        }
      }

      throw Exception('Payment URL not found in response');
    } else {
      throw Exception('Failed to request payment URL');
    }
  }

  Future<void> triggerPushToPay(String phoneNumber) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/api/push-to-pay',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'phone_number': phoneNumber,
      }),
    );

    if (response.statusCode == 200) {
      return;
    } else {
      String errorMsg =
          'Failed to trigger push-to-pay. '
          'Status code: ${response.statusCode}. '
          'Response body: ${response.body}';

      try {
        final errorData = json.decode(response.body);

        if (errorData is Map && errorData['msg'] != null) {
          errorMsg = errorData['msg'];
        }
      } catch (_) {}

      throw Exception(errorMsg);
    }
  }
}