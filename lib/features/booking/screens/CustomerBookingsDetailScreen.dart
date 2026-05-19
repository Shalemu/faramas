import 'dart:convert';
import 'package:faramas/constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/app_colors.dart';
import '../../../models/booking_model.dart';
import '../../../providers/booking.dart';
import 'booking_detail_screen.dart';

class CustomerBookingsDetailScreen extends StatefulWidget {
  final String customerName;

  const CustomerBookingsDetailScreen({super.key, required this.customerName});

  @override
  State<CustomerBookingsDetailScreen> createState() =>
      _CustomerBookingsDetailScreenState();
}

class _CustomerBookingsDetailScreenState
    extends State<CustomerBookingsDetailScreen> {
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
    final ownerId = prefs.getInt('user_id');

    if (token == null || ownerId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse(
          "${ApiConstants.booking}?owner_id=$ownerId",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json"
        },
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = body is List ? body : body["results"] ?? [];
        final bookings =
            list.map<BookingModel>((b) => BookingModel.fromJson(b)).toList();
        provider.setBookings(bookings);
      }
    } catch (e) {
      debugPrint("Error fetching bookings: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.customerName}'s Bookings",
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      backgroundColor: AppColors.backgroundLight,
      body: Consumer<BookingProvider>(
        builder: (context, provider, _) {
          final displayBookings = provider.bookings;

          if (_isLoading)
            return const Center(child: CircularProgressIndicator());
          if (displayBookings.isEmpty)
            return const Center(child: Text("No bookings found."));

          return RefreshIndicator(
            onRefresh: _fetchBookings,
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: displayBookings.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.72),
              itemBuilder: (context, index) {
                final booking = displayBookings[index];
                final property = booking.property;

                String imageUrl = property.images.isNotEmpty
                    ? property.images.first
                    : property.imageUrl ??
                        'https://via.placeholder.com/150x100';

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingDetailScreen(booking: booking),
                        ));
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 6,
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                      image: NetworkImage(imageUrl),
                                      fit: BoxFit.cover),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.25),
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.4),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(property.name,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(property.address,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Tzs ${property.price}",
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      booking.createdAt
                                          .toLocal()
                                          .toString()
                                          .split(' ')[0],
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary),
                                      textAlign: TextAlign.end,
                                      overflow: TextOverflow.ellipsis,
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
