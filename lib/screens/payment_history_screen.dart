import 'package:faramas/constants/api_constants.dart';
import 'package:faramas/screens/view_order.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final String? orderId;
  final int customerId;

  const PaymentHistoryScreen({
    super.key,
    this.orderId,
    required this.customerId,
  });

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<dynamic> payments = [];
  bool isLoading = true;
  String message = '';

  @override
  void initState() {
    super.initState();
    fetchPaymentHistory();
  }

  Future<void> fetchPaymentHistory() async {
    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        setState(() {
          message = "Access token not found. Please login again.";
          isLoading = false;
        });
        return;
      }

      // If orderId is passed, extract numeric part; else use general log
      Uri url;
      if (widget.orderId != null && widget.orderId!.isNotEmpty) {
        final numericOrderId = widget.orderId!.split('-').last;

        url = Uri.parse(
          '${ApiConstants.myPayments}?order_id=$numericOrderId',
        );
      } else {
        url = Uri.parse(ApiConstants.myPayments);
      }

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          payments = data;
        } else if (data is Map && data.containsKey('payments')) {
          payments = data['payments'];
        } else {
          payments = [];
        }

        setState(() {
          isLoading = false;
          message = payments.isEmpty ? "No payments found." : '';
        });
      } else {
        setState(() {
          message =
              'Failed to load payment history. Status code: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        message = 'Error loading payment history: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment History"),
        backgroundColor: const Color(0xFF1E4B6C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : payments.isNotEmpty
                ? ListView.separated(
                    itemCount: payments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              // ignore: deprecated_member_use
                              color: Colors.black12.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(Icons.payments_outlined,
                                    color: Color(0xFF1E4B6C)),
                                Text(
                                  payment['status'].toString().toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: payment['status']
                                                .toString()
                                                .toLowerCase() ==
                                            'success'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text("Amount: ${payment['amount']}"),
                            Text("Date: ${payment['date']}"),
                            Text("Reference: ${payment['reference']}"),
                          ],
                        ),
                      );
                    },
                  )
                : Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.receipt_long,
                            size: 100,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "No payments found.",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final url = Uri.parse(
                                'http://161.97.65.175:9098/api/customer-orders?customer_id=${widget.customerId}',
                              );
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final token = prefs.getString('auth_token');

                              if (token == null || token.isEmpty) {
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Access token missing. Please login again.')),
                                );
                                return;
                              }

                              final response = await http.get(
                                url,
                                headers: {'Authorization': 'Bearer $token'},
                              );

                              if (response.statusCode == 200) {
                                final orders = json.decode(response.body);
                                if (orders is List && orders.isNotEmpty) {
                                  final order = orders.first;
                                  if (!mounted) return;
                                  Navigator.push(
                                    // ignore: use_build_context_synchronously
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          OrderDetailScreen(order: order),
                                    ),
                                  );
                                } else {
                                  // ignore: use_build_context_synchronously
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("No orders found.")),
                                  );
                                }
                              } else {
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          "Failed to fetch order. Status: ${response.statusCode}")),
                                );
                              }
                            },
                            icon: const Icon(Icons.assignment),
                            label: const Text("View Order Status"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E4B6C),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              textStyle: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
