import 'dart:convert';
import 'package:faramas/constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_colors.dart';
import '../models/booking_model.dart';
import '../providers/booking.dart';
import 'booking_detail_screen.dart';

class MyBookingScreen extends StatefulWidget {
  const MyBookingScreen({super.key});

  @override
  State<MyBookingScreen> createState() => _MyBookingScreenState();
}

class _MyBookingScreenState extends State<MyBookingScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<BookingProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('auth_token');
    final userId = prefs.getInt('customer_id');

    if (token == null || userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Fetch normal property bookings
      final resNormal = await http.get(
        Uri.parse(
          "${ApiConstants.booking}?user_id=$userId",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json"
        },
      );

      final resAirbnb = await http.get(
        Uri.parse(
          "${ApiConstants.airbnbBooking}?user_id=$userId",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json"
        },
      );

      List<BookingModel> bookings = [];

      int normalCount = 0;
      int airbnbCount = 0;

      if (resNormal.statusCode == 200) {
        final body = jsonDecode(resNormal.body);
        final list = body is List ? body : body['results'] ?? [];
        normalCount = list.length; // Count normal bookings
        bookings
            .addAll(list.map<BookingModel>((b) => BookingModel.fromJson(b)));
      }

      if (resAirbnb.statusCode == 200) {
        final body = jsonDecode(resAirbnb.body);
        final list = body['data'] ?? [];
        airbnbCount = list.length; // Count Airbnb bookings
        bookings
            .addAll(list.map<BookingModel>((b) => BookingModel.fromJson(b)));
      }

      // Debug prints
      debugPrint("Normal bookings fetched: $normalCount");
      debugPrint("Airbnb bookings fetched: $airbnbCount");
      debugPrint("Total bookings: ${bookings.length}");

      provider.setBookings(bookings);
    } catch (e) {
      debugPrint("Error fetching bookings: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case "confirmed":
        return Colors.green;
      case "pending":
        return Colors.orange;
      case "cancelled":
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Bookings",
          style: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      backgroundColor: AppColors.backgroundLight,
      body: Consumer<BookingProvider>(
        builder: (context, provider, _) {
          final bookings = provider.bookings;

          if (_isLoading)
            return const Center(child: CircularProgressIndicator());
          if (bookings.isEmpty)
            return const Center(child: Text("No bookings found."));

          return RefreshIndicator(
            onRefresh: _fetchBookings,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                final property = booking.property;

                final imageUrl = property.images.isNotEmpty
                    ? property.images.first
                    : property.imageUrl ??
                        'https://via.placeholder.com/150x100';

                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => BookingDetailScreen(booking: booking)),
                  ),
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Property Image
                        Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(property.name,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(property.address,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Tzs ${property.price}",
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _statusColor(booking.status),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      booking.status.capitalizeFirst,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

extension StringCasingExtension on String {
  String get capitalizeFirst =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
