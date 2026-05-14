import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class TourRequestDetailScreen extends StatefulWidget {
  final String customerName;
  final List<dynamic> userRequests;

  const TourRequestDetailScreen({
    super.key,
    required this.customerName,
    required this.userRequests,
  });

  @override
  State<TourRequestDetailScreen> createState() =>
      _TourRequestDetailScreenState();
}

class _TourRequestDetailScreenState extends State<TourRequestDetailScreen> {
  late List<dynamic> _tourRequests;

  @override
  void initState() {
    super.initState();
    _tourRequests = List.from(widget.userRequests);
  }
Future<void> _updateTourStatus(int requestId, String status) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  if (token == null) {
    _redirectToLogin(); // If no token found, redirect
    return;
  }

  final Uri url = Uri.parse(
    "http://161.97.65.175:9098/api/confirm-tour-request/?request_id=$requestId&status=$status",
  );

  try {
    final response = await http.patch(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    debugPrint("Updating $requestId → $status");
    debugPrint("Response ${response.statusCode}: ${response.body}");

    // If token expired or unauthorized
    if (response.statusCode == 401) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please log in again.')),
      );
      await prefs.remove('auth_token'); // Clear invalid token
      _redirectToLogin();
      return;
    }

    final body = response.body.isNotEmpty ? json.decode(response.body) : {};

    if (response.statusCode == 200) {
      final index = _tourRequests.indexWhere((r) => r['id'] == requestId);
      if (index != -1) {
        setState(() {
          _tourRequests[index]['status'] = status;
          _tourRequests[index]['is_complete'] = (status == 'accepted');
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${body['detail'] ?? 'Status updated'}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${response.statusCode}')),
      );
    }
  } catch (e) {
    debugPrint("Error updating request $requestId: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error updating request: $e')),
    );
  }
}

/// Redirect user to Login Screen
void _redirectToLogin() {
  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          widget.customerName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tourRequests.length,
        itemBuilder: (context, i) {
          final req = _tourRequests[i];
          final String status = req['status'] ?? 'pending';
          final int id = req['id'];
          final bool isAccepted = status == 'accepted';
          final bool isRejected = status == 'rejected';

          // Status text for admin (accepted → confirmed)
          final displayStatus =
              isAccepted ? 'CONFIRMED' : status.toUpperCase();

          Color cardColor = Colors.white;
          if (isAccepted) cardColor = Colors.green.shade50;
          if (isRejected) cardColor = Colors.red.shade50;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    req['property_name'] ?? 'Property',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Date', req['date']),
                  _buildInfoRow('Time', req['time']),
                  _buildInfoRow('Type', req['type']),
Row(
  children: [
    const Text('Phone: '),
    GestureDetector(
      onTap: () {
        final phone = req['customer_phone'] ?? '';
        // ignore: unused_local_variable
        final name = widget.customerName;
        if (phone.isEmpty) return;

        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return SafeArea(
              child: Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('Call now'),
                    onTap: () async {
                      final Uri callUri = Uri(scheme: 'tel', path: phone);
                      Navigator.pop(context);
                      await launchUrl(callUri);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.copy),
                    title: const Text('Copy number'),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: phone));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Number copied to clipboard')),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_add_alt_1),
                    title: const Text('Save to contacts'),
                    onTap: () async {
                      Navigator.pop(context);
                      final Uri saveUri = Uri(
                        scheme: 'tel',
                        path: phone,
                      );
                      await launchUrl(saveUri);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      child: Text(
        req['customer_phone'] ?? '-',
        style: const TextStyle(
          color: Colors.blue, // clickable color
          decoration: TextDecoration.none, // no underline
        ),
      ),
    ),
  ],
),



                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isAccepted
                          ? Colors.green.shade100
                          : isRejected
                              ? Colors.red.shade100
                              : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      displayStatus,
                      style: TextStyle(
                        color: isAccepted
                            ? Colors.green.shade700
                            : isRejected
                                ? Colors.red.shade700
                                : Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!isAccepted && !isRejected)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle,
                              color: Colors.green),
                          tooltip: 'Confirm Request',
                          onPressed: () => _updateTourStatus(id, 'accepted'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel,
                              color: Colors.redAccent),
                          tooltip: 'Reject Request',
                          onPressed: () => _updateTourStatus(id, 'rejected'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          Expanded(
            child: Text(
              value?.isNotEmpty == true ? value! : '-',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
