import 'package:faramas/services/booking_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../models/booking_model.dart';
import '../../../services/property_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../screens/property_detail_screen.dart'; // To navigate to property details

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  late Future<List<BookingModel>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  void _fetchBookings() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final accessToken = authProvider.accessToken;
    final user = authProvider.user;

    if (accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please log in to view your bookings.'),
            backgroundColor: Colors.red),
      );

      setState(() {
        _bookingsFuture = Future.error('Not logged in');
      });
    } else {
      setState(() {
        _bookingsFuture = BookingServices.fetchMyBookings(
            token: accessToken, userId: user!.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          localizations?.myBookings ?? 'My Bookings',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _fetchBookings();
          await _bookingsFuture;
        },
        child: FutureBuilder<List<BookingModel>>(
          future: _bookingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 50),
                      const SizedBox(height: 10),
                      Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _fetchBookings, // Retry button
                        child: Text(localizations?.tryAgain ?? 'Try Again'),
                      ),
                    ],
                  ),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.textSecondary, size: 50),
                    const SizedBox(height: 10),
                    Text(
                      localizations?.noBookingsFound ?? 'No bookings found yet!',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to properties list to encourage booking
                        Navigator.of(context)
                            .pop(); // Go back to previous screen (e.g., home)
                      },
                      child: Text(localizations?.browseProperties ?? 'Browse Properties'),
                    ),
                  ],
                ),
              );
            } else {
              final bookings = snapshot.data!;
              return ListView.builder(
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PropertyDetailScreen(
                                property: booking.property),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Property Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                booking.property.imageUrl ??
                                    'https://via.placeholder.com/150',
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Image.asset('assets/images/placeholder.png',
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    booking.property.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    booking.property.address,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          size: 16, color: AppColors.secondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${localizations?.bookedOn ?? 'Booked on'}: ${booking.createdAt.toLocal().toString().split(' ')[0]}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Price: Tzs ${booking.property.price}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  booking.property.isRent
                                      ? (localizations?.rented ?? 'RENTED')
                                      : (localizations?.sold ?? 'SOLD'), // Or a 'BOOKED' status
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
