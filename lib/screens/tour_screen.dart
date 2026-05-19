import 'package:faramas/constants/api_constants.dart';
import 'package:faramas/screens/request_success_screen';
import 'package:faramas/features/booking/screens/tour_request_list.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TourScreen extends StatefulWidget {
  const TourScreen({super.key});

  @override
  State<TourScreen> createState() => _TourScreenState();
}

class _TourScreenState extends State<TourScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  DateTime? _selectedDatePhysical;
  TimeOfDay? _selectedTimePhysical;
  final TextEditingController _phoneControllerPhysical =
      TextEditingController();

  DateTime? _selectedDateVideo;
  TimeOfDay? _selectedTimeVideo;
  final TextEditingController _phoneControllerVideo = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _phoneControllerPhysical.dispose();
    _phoneControllerVideo.dispose();
    super.dispose();
  }

  Future<bool> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      showDialog(
        context: context,
        builder: (_) => AnimatedMessageDialog(
          message: "You need to log in first to continue.",
          type: DialogType.loginRequired,
          onAction: () {
            Navigator.pop(context); // Close dialog
            Navigator.pushNamed(context, '/login'); // Navigate to login
          },
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _pickDatePhysical() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDatePhysical ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() => _selectedDatePhysical = picked);
    }
  }

  Future<void> _pickTimePhysical() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTimePhysical ?? now,
    );
    if (picked != null) {
      setState(() => _selectedTimePhysical = picked);
    }
  }

  Future<void> _pickDateVideo() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateVideo ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() => _selectedDateVideo = picked);
    }
  }

  Future<void> _pickTimeVideo() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTimeVideo ?? now,
    );
    if (picked != null) {
      setState(() => _selectedTimeVideo = picked);
    }
  }

  Future<void> _proceed() async {
    final isAuthenticated = await _checkAuth();
    if (!isAuthenticated) return;

    final isPhysical = _tabController.index == 0;
    final selectedDate =
        isPhysical ? _selectedDatePhysical : _selectedDateVideo;
    final selectedTime =
        isPhysical ? _selectedTimePhysical : _selectedTimeVideo;
    final phone =
        isPhysical ? _phoneControllerPhysical.text : _phoneControllerVideo.text;
    final propertyId = ModalRoute.of(context)?.settings.arguments as int?;

    if (selectedDate == null ||
        selectedTime == null ||
        phone.isEmpty ||
        propertyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final formattedDate =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    final formattedTime =
        "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}";

    final requestBody = {
      "property": propertyId,
      "date": formattedDate,
      "time": formattedTime,
      "phone": phone,
      "type": isPhysical ? 'Physical' : 'Video',
    };

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.tourRequests),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(requestBody),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        showDialog(
          context: context,
          builder: (_) => AnimatedMessageDialog(
            message: "Your tour request was submitted successfully!",
            type: DialogType.success,
            onAction: () {
              Navigator.pop(context); // close dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TourRequestSuccessScreen(tourData: responseData),
                ),
              );
            },
          ),
        );
      } else {
        final errorMessage = responseData['error'] ?? 'Something went wrong';

        if (errorMessage.toLowerCase().contains("unpaid orders")) {
          // Payment required
          showDialog(
            context: context,
            builder: (_) => AnimatedMessageDialog(
              message: errorMessage,
              type: DialogType.payment,
              onAction: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/generatePayment',
                    arguments: propertyId);
              },
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (_) => AnimatedMessageDialog(
              message: errorMessage,
              type: DialogType.error,
              onAction: () => Navigator.pop(context),
            ),
          );
        }
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AnimatedMessageDialog(
          message: "An error occurred: $e",
          type: DialogType.error,
          onAction: () => Navigator.pop(context),
        ),
      );
    }
  }

  void _viewTourRequests() async {
    final isAuthenticated = await _checkAuth();
    if (!isAuthenticated) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TourRequestListScreen()),
    );
  }

  Widget _buildTourTab({
    required String title,
    required DateTime? selectedDate,
    required TimeOfDay? selectedTime,
    required TextEditingController phoneController,
    required VoidCallback onPickDate,
    required VoidCallback onPickTime,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 6,
            shadowColor: Colors.grey.shade300,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, color: Colors.blue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ListTile(
                          title: Text('Date for $title'),
                          subtitle: Text(selectedDate != null
                              ? selectedDate.toLocal().toString().split(' ')[0]
                              : 'Select a date'),
                          onTap: onPickDate,
                          trailing: const Icon(Icons.edit_calendar),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.deepOrange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ListTile(
                          title: Text('Time for $title'),
                          subtitle: Text(selectedTime != null
                              ? selectedTime.format(context)
                              : 'Select a time'),
                          onTap: onPickTime,
                          trailing: const Icon(Icons.schedule),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Schedule a Tour'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Physical tour'),
                Tab(text: 'Video tour'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildTourTab(
                title: 'Physical',
                selectedDate: _selectedDatePhysical,
                selectedTime: _selectedTimePhysical,
                phoneController: _phoneControllerPhysical,
                onPickDate: _pickDatePhysical,
                onPickTime: _pickTimePhysical,
              ),
              _buildTourTab(
                title: 'Video',
                selectedDate: _selectedDateVideo,
                selectedTime: _selectedTimeVideo,
                phoneController: _phoneControllerVideo,
                onPickDate: _pickDateVideo,
                onPickTime: _pickTimeVideo,
              ),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: _proceed,
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: const Text('Submit Tour Request',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _viewTourRequests,
                  icon: const Icon(Icons.history),
                  label: const Text('View Tour Requests'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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

// ================= DIALOG =================
enum DialogType { loginRequired, payment, success, error }

class AnimatedMessageDialog extends StatefulWidget {
  final String message;
  final DialogType type;
  final VoidCallback? onAction;

  const AnimatedMessageDialog({
    super.key,
    required this.message,
    required this.type,
    this.onAction,
  });

  @override
  _AnimatedMessageDialogState createState() => _AnimatedMessageDialogState();
}

class _AnimatedMessageDialogState extends State<AnimatedMessageDialog>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    String title;
    IconData icon;
    Color color;

    switch (widget.type) {
      case DialogType.loginRequired:
        title = "Login Required";
        icon = Icons.login;
        color = Colors.orange;
        break;
      case DialogType.payment:
        title = "Payment Required";
        icon = Icons.payment;
        color = Colors.orange;
        break;
      case DialogType.success:
        title = "Success";
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case DialogType.error:
        title = "Error";
        icon = Icons.error;
        color = Colors.red;
        break;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                child: Icon(icon, color: color, size: 64),
              ),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 12),
            Text(widget.message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            if (widget.onAction != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: widget.onAction,
                child: Text(
                  widget.type == DialogType.payment
                      ? "Pay Now"
                      : widget.type == DialogType.loginRequired
                          ? "Login"
                          : widget.type == DialogType.success
                              ? "OK"
                              : "Close",
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
