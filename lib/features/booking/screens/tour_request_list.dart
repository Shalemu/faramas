import 'package:faramas/constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';


class TourRequestListScreen extends StatefulWidget {
  const TourRequestListScreen({super.key});

  @override
  State<TourRequestListScreen> createState() => _TourRequestListScreenState();
}

class _TourRequestListScreenState extends State<TourRequestListScreen> {
  List<dynamic> _tourRequests = [];
  bool _isLoading = true;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchTourRequests();
  }

  Future<void> _fetchTourRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token not found. Please login again.')),
      );
      return;
    }

    try {
        final response = await http.get(
          Uri.parse(ApiConstants.tourRequests),
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          },
        );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> requests = data['results'] ?? [];

        requests.sort((a, b) {
          final dateTimeA = DateTime.tryParse("${a['date']} ${a['time']}:00");
          final dateTimeB = DateTime.tryParse("${b['date']} ${b['time']}:00");
          if (dateTimeA == null && dateTimeB == null) return 0;
          if (dateTimeA == null) return 1;
          if (dateTimeB == null) return -1;
          return dateTimeA.compareTo(dateTimeB);
        });

        setState(() {
          _tourRequests = requests;
          _isLoading = false;
        });
        debugPrint("Loaded ${_tourRequests.length} tour requests.");
      } else {
        debugPrint("Failed: ${response.statusCode} ${response.body}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching: $e");
      setState(() => _isLoading = false);
    }
  }
Future<void> _updateTourStatus(int requestId, String status) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  if (token == null) {
    _redirectToLogin(); // If no token found, redirect
    return;
  }

final Uri url = Uri.parse(
  '${ApiConstants.confirmTourRequest}?request_id=$requestId&status=$status',
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


  Widget _buildTourCard(Map<String, dynamic> request) {
    final int requestId = request['id'];
    final String status = (request['status'] ?? 'pending').toString();
    final bool isAccepted = status == 'accepted';
    final bool isRejected = status == 'rejected';

    // UI display correction for admin (accepted → confirmed)
    final displayStatus = isAccepted ? 'CONFIRMED' : status.toUpperCase();

    Color statusColor;
    IconData statusIcon;
    if (isAccepted) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (isRejected) {
      statusColor = Colors.redAccent;
      statusIcon = Icons.cancel;
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.pending_actions;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request['property_name'] ?? 'Property',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text('Customer: ${request['customer_name'] ?? '-'}'),
 Row(
  children: [
    const Text('Phone: '),
    GestureDetector(
      onTap: () {
        final phone = request['customer_phone'] ?? '';
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
                        const SnackBar(content: Text('Number copied to clipboard')),
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
        request['customer_phone'] ?? '-',
        style: const TextStyle(
          color: Colors.blue, // clickable color
          decoration: TextDecoration.none, // no underline
        ),
      ),
    ),
  ],
),


            Text('Date: ${request['date']}'),
            Text('Time: ${request['time']}'),
            Text('Type: ${request['type']}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  '$displayStatus',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!isAccepted && !isRejected)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    tooltip: 'Confirm Request',
                    onPressed: () => _updateTourStatus(requestId, 'accepted'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.redAccent),
                    tooltip: 'Reject Request',
                    onPressed: () => _updateTourStatus(requestId, 'rejected'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  List<dynamic> get _filteredRequests {
    if (_selectedDate == null) return _tourRequests;
    final formatted = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    return _tourRequests.where((r) => r['date'] == formatted).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tour Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickDate,
          ),
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => _selectedDate = null),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredRequests.isEmpty
              ? const Center(child: Text('No tour requests found.'))
              : ListView.builder(
                  itemCount: _filteredRequests.length,
                  itemBuilder: (context, index) =>
                      _buildTourCard(_filteredRequests[index]),
                ),
    );
  }
}
