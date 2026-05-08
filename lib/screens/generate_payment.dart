import 'dart:convert';
import 'package:faramas/constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:faramas/screens/payment_webview.dart';

class GeneratePaymentScreen extends StatefulWidget {
  const GeneratePaymentScreen({super.key});

  @override
  State<GeneratePaymentScreen> createState() => _GeneratePaymentScreenState();
}

class _GeneratePaymentScreenState extends State<GeneratePaymentScreen> {
  int? customerId;
  String? paymentUrl;
  bool isLoading = false;
  String message = '';
  bool isPaid = false;

  @override
  void initState() {
    super.initState();
    loadCustomerId();
  }

  Future<void> loadCustomerId() async {
    final prefs = await SharedPreferences.getInstance();
    final storedCustomerId = prefs.getInt('customer_id'); // Store this on login
    if (storedCustomerId != null) {
      setState(() {
        customerId = storedCustomerId;
      });
    } else {
      setState(() {
        message = 'No customer ID found. Please login again.';
      });
    }
  }

  Future<void> generatePaymentUrl() async {
    if (customerId == null) return;

    setState(() {
      isLoading = true;
      message = 'Checking existing orders...';
      paymentUrl = null;
    });

    try {
      final orderRes = await http.get(
        Uri.parse(
          '${ApiConstants.customerOrders}?customer_id=$customerId',
        ),
      );

      if (orderRes.statusCode == 200) {
        final List<dynamic> orders = json.decode(orderRes.body);

        if (orders.isEmpty) {
          await createNewPaymentOrder();
        } else {
          final unpaidOrder = orders.firstWhere(
            (order) =>
                order['is_paid'] == false && order['is_generated'] == true,
            orElse: () => null,
          );

          if (unpaidOrder != null) {
            setState(() {
              paymentUrl = unpaidOrder['payment_gateway_url'];
              message = 'Found unpaid order. Ready to pay.';
              isPaid = false;
            });
            return;
          }

          final paidOrder = orders.firstWhere(
            (order) => order['is_paid'] == true,
            orElse: () => null,
          );

          if (paidOrder != null) {
            setState(() {
              message = 'Your subscription is already active.';
              isPaid = true;
            });
          } else {
            await createNewPaymentOrder();
          }
        }
      } else if (orderRes.statusCode == 404) {
        await createNewPaymentOrder();
      } else {
        setState(() {
          message = 'Error fetching orders. Code ${orderRes.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        message = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> createNewPaymentOrder() async {
    if (customerId == null) {
      debugPrint("createNewPaymentOrder: customerId is NULL");
      return;
    }

    debugPrint("Creating payment order for customerId: $customerId");

    try {
      final url = Uri.parse(
        '${ApiConstants.requestPaymentUrl}?customer_id=$customerId',
      );

      debugPrint("Request URL: $url");

      final createRes = await http.get(url);

      debugPrint("Response status: ${createRes.statusCode}");
      debugPrint("Response body: ${createRes.body}");

      if (createRes.statusCode == 200) {
        final data = json.decode(createRes.body);

        debugPrint("Decoded response: $data");

        if (data['msg'] == 'success') {
          debugPrint("Order created successfully");

          await fetchNewlyGeneratedOrder();
        } else {
          debugPrint("API returned success status but msg != success");
          debugPrint(" Message: ${data['msg']}");

          setState(() {
            message = 'Failed to create new order.';
          });
        }
      } else {
        debugPrint("HTTP Error while creating order");
        debugPrint("Status Code: ${createRes.statusCode}");
        debugPrint("Response: ${createRes.body}");

        setState(() {
          message = 'Error creating order. Code ${createRes.statusCode}';
        });
      }
    } catch (e, stackTrace) {
      debugPrint("Exception in createNewPaymentOrder: $e");
      debugPrint("StackTrace: $stackTrace");

      setState(() {
        message = 'An error occurred: $e';
      });
    }
  }

  Future<void> fetchNewlyGeneratedOrder() async {
    if (customerId == null) return;

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.customerOrders}?customer_id=$customerId',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> orders = json.decode(response.body);

        final newOrder = orders.firstWhere(
          (order) => order['is_paid'] == false && order['is_generated'] == true,
          orElse: () => null,
        );

        if (newOrder != null && newOrder['payment_gateway_url'] != null) {
          setState(() {
            paymentUrl = newOrder['payment_gateway_url'];
            message = 'New order created. Ready to pay.';
            isPaid = false;
          });
        } else {
          setState(() {
            message = 'Order created, but no payment link found.';
          });
        }
      } else {
        setState(() {
          message = 'Failed to re-fetch orders after creation.';
        });
      }
    } catch (e) {
      setState(() {
        message = 'An error occurred: $e';
      });
    }
  }

  void openPaymentUrl() {
    if (paymentUrl != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentWebView(url: paymentUrl!),
        ),
      );
    } else {
      setState(() {
        message = 'Payment URL is not available.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Subscription Payment",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E4B6C),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        color: const Color(0xFFF5F7FA),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.payments,
                      size: 48, color: Color(0xFF1E4B6C)),
                  const SizedBox(height: 16),
                  Text(
                    isPaid
                        ? 'Your subscription is active.'
                        : 'Make your payment to activate your subscription.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.refresh, color: Colors.white),
              label: Text(
                isLoading
                    ? "Loading..."
                    : (isPaid
                        ? "Generate New Payment"
                        : "Generate Payment URL"),
                style: const TextStyle(color: Colors.white),
              ),
              onPressed: isLoading ? null : generatePaymentUrl,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E4B6C),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 20),
            if (paymentUrl != null)
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text("Proceed to Payment"),
                onPressed: openPaymentUrl,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            const SizedBox(height: 20),
            if (message.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    color: message.toLowerCase().contains("error") ||
                            message.toLowerCase().contains("failed")
                        ? Colors.red
                        : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
