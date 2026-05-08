import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_colors.dart';
import '../services/payment_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'payment_details_popup.dart';

class SubscriptionPaymentsScreen extends StatefulWidget {
  const SubscriptionPaymentsScreen({super.key});

  @override
  State<SubscriptionPaymentsScreen> createState() =>
      _SubscriptionPaymentsScreenState();
}

class _SubscriptionPaymentsScreenState extends State<SubscriptionPaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _phoneController = TextEditingController();
  final PaymentService _paymentService = PaymentService();

  List<dynamic> _paymentLogs = [];

  // Define payment method details
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'name': 'M-pesa',
      'icon': Icons.phone_android,
      'color': const Color(0xFFE20613)
    },
    {
      'name': 'Yas',
      'icon': Icons.account_balance_wallet,
      'color': const Color(0xFF007BFF)
    },
    {
      'name': 'Airtel Money',
      'icon': Icons.payments,
      'color': const Color(0xFFF00000)
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _paymentMethods.length, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _phoneController.clear();
        setState(() {
          _paymentLogs = [];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Removed user existence check as per user request

  Future<void> _fetchPaymentLogs(String customerId) async {
    setState(() {
    });
    try {
      final logs = await _paymentService.getCustomerOrders(customerId);
      setState(() {
        _paymentLogs = logs;
      });
    } catch (e) {
      _showSnackBar('Failed to fetch payment logs: $e');
    } finally {
      setState(() {
      });
    }
  }

  Future<void> _payNow() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showSnackBar('Please enter your phone number.');
      return;
    }
    if (phone.length != 10 || !phone.startsWith('0')) {
      _showSnackBar(
          'Please enter a valid Tanzanian phone number (10 digits starting with 0).');
      return;
    }


    // For demo, using phone as customerId
    final customerId = phone;

    // Removed user existence check and push-to-pay call as per user request

    try {
      setState(() {
      });

      // Directly request payment URL without push-to-pay
      final paymentUrl = await _paymentService.requestPaymentUrl(customerId);
      print('Received payment URL: $paymentUrl');

      if (paymentUrl.isEmpty) {
        _showSnackBar('Payment URL is empty.');
        return;
      }

      if (await canLaunch(paymentUrl)) {
        // Open payment URL externally in default browser
        await launchUrl(
          Uri.parse(paymentUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showSnackBar('Could not launch payment URL');
        return;
      }

      // After payment, refresh payment logs automatically
      await _fetchPaymentLogs(customerId);

      // Show payment details popup for the latest payment
      if (_paymentLogs.isNotEmpty) {
        final latestPayment = _paymentLogs.first;
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => PaymentDetailsPopup(payment: {
            'order_id': latestPayment['order_id'] ?? '',
            'last_payment_date': latestPayment['last_payment_date'] ?? '',
            'next_payment_date': latestPayment['next_payment_date'] ?? '',
            'created': latestPayment['created'] ?? '',
            'amount': latestPayment['amount'] ?? '',
            'interval': latestPayment['interval']?.toString() ?? '',
            'is_paid': latestPayment['is_paid']?.toString() ?? '',
            'is_generated': latestPayment['is_generated']?.toString() ?? '',
            'payment_gateway_url': latestPayment['payment_gateway_url'] ?? '',
            'reference': latestPayment['reference'] ?? '',
            'result': latestPayment['result'] ?? '',
          }),
        );
      } else {
        _showSnackBar('No payment orders found for this user.');
      }

      _showSnackBar('Payment URL generated successfully.', isSuccess: true);
    } catch (e) {
      _showSnackBar('Payment failed: $e');
    } finally {
      setState(() {
      });
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (!mounted) return;
    try {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isSuccess ? Colors.green.shade700 : AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Ignore errors from showing snackbar off screen
    }
  }

  // Consistent tab builder with modern styling
  Widget _buildTab(String label, IconData icon) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.textLight,
      appBar: AppBar(
        title: const Text(
          'Subscription Payments',
          style: TextStyle(
            color: AppColors.textLight,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0, // No shadow for a flat, modern look
        centerTitle: true,
        iconTheme: const IconThemeData(color:Colors.white),

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.9),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textLight.withOpacity(0.7),
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.textLight,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              labelPadding: EdgeInsets.zero,
              overlayColor:
                  MaterialStateProperty.all(AppColors.primary.withOpacity(0.1)),
              tabs: _paymentMethods.map((method) {
                return _buildTab(
                    method['name'] as String, method['icon'] as IconData);
              }).toList(),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.textLight, Colors.blueGrey.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(24), // Increased overall padding
        child: TabBarView(
          controller: _tabController,
          children: _paymentMethods.map((method) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 30),

                  // Main form card
                  Container(
                    padding: const EdgeInsets.all(28), // More generous padding
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                          20), // Even more rounded corners
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pay with ${method['name']}', // Direct and clear heading
                          style: const TextStyle(
                            fontSize: 24, // Larger heading
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter the phone number associated with your ${method['name']} account.',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textDark.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 30),

                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(
                                10), // Max length for phone numbers
                          ],
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            hintText: 'e.g., 07XXXXXXXX',
                            prefixIcon:
                                Icon(Icons.phone, color: method['color']),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  12), // Consistent rounded corners
                              borderSide:
                                  BorderSide.none, // No default border line
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: AppColors.grey.withOpacity(0.5),
                                  width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: method['color'],
                                  width:
                                      2.5), // Thicker, accent border on focus
                            ),
                            filled: true,
                            fillColor: Colors.grey
                                .shade100, // Slightly darker fill for input
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 18, horizontal: 16), // Taller input
                          ),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 35),

                        // Consistent Pay Now Button
                        ElevatedButton(
                          onPressed: () => _payNow(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: method['color'],

                            elevation: 8, // Prominent elevation
                            shadowColor: method['color']
                                .withOpacity(0.5), // Stronger shadow
                            foregroundColor:
                                AppColors.textLight, // Text color is white
                          ),
                          child: Text(
                            'PAY WITH ${method['name'].toUpperCase()}', // Uppercase for consistent emphasis
                            style: const TextStyle(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Subscription details section - styled to be clean and informative
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Subscription Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const Divider(
                            height: 25, thickness: 1, color: AppColors.grey),
                        _buildDetailRow('Current Plan:', 'Premium Plan'),
                        _buildDetailRow('Expires On:', '2025-12-31'),
                        _buildDetailRow('Amount Due:', 'TZS 10,000',
                            valueColor: Colors.green.shade700),
                      ],
                    ),
                  ),

                  // Payment logs section
                  if (_paymentLogs.isNotEmpty) ...[
                    const SizedBox(height: 40),
                    const Text(
                      'Payment History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _paymentLogs.length,
                      itemBuilder: (context, index) {
                        final payment = _paymentLogs[index];
                        return ListTile(
                          title: Text(payment['order_id'] ?? ''),
                          subtitle: Text(
                              'Amount: ${payment['amount'] ?? ''} - Status: ${payment['result'] ?? ''}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.info_outline),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (context) =>
                                    PaymentDetailsPopup(payment: {
                                  'order_id': payment['order_id'] ?? '',
                                  'last_payment_date':
                                      payment['last_payment_date'] ?? '',
                                  'next_payment_date':
                                      payment['next_payment_date'] ?? '',
                                  'created': payment['created'] ?? '',
                                  'amount': payment['amount'] ?? '',
                                  'interval':
                                      payment['interval']?.toString() ?? '',
                                  'is_paid':
                                      payment['is_paid']?.toString() ?? '',
                                  'is_generated':
                                      payment['is_generated']?.toString() ?? '',
                                  'payment_gateway_url':
                                      payment['payment_gateway_url'] ?? '',
                                  'reference': payment['reference'] ?? '',
                                  'result': payment['result'] ?? '',
                                }),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textDark.withOpacity(0.8),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}