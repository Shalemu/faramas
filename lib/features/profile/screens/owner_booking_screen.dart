import 'dart:convert';
import 'package:faramas/constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/app_colors.dart';
import '../../../models/booking_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/booking.dart';
import '../../../services/booking_services.dart';
import '../../booking/screens/CustomerBookingsDetailScreen.dart';
import '../../booking/screens/TourRequestDetailScreen.dart';

class OwnerBookingsScreen extends StatefulWidget {
  const OwnerBookingsScreen({super.key});

  @override
  State<OwnerBookingsScreen> createState() => _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends State<OwnerBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<BookingModel>> _shortStayBookingsFuture;

  List<dynamic> _tourRequests = [];
  bool _isLoadingTour = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchShortStayBookings();
    _fetchTourRequests();
  }

  // Fetch Short Stay Bookings
  void _fetchShortStayBookings() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken;
    final user = authProvider.user;

    if (token == null || user == null) {
      _shortStayBookingsFuture = Future.error('Not logged in');
      return;
    }

    _shortStayBookingsFuture = BookingServices.fetchAirbnbBookings(
      token: token,
      uploaderId: user.id!,
    );
  }

  // Fetch Tour Requests
  Future<void> _fetchTourRequests() async {
    setState(() => _isLoadingTour = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    try {
      final response = await http.get(
       Uri.parse(ApiConstants.tourRequests),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> requests = data['results'];

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
          _isLoadingTour = false;
        });
      } else {
        setState(() => _isLoadingTour = false);
      }
    } catch (e) {
      setState(() => _isLoadingTour = false);
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.backgroundLight,

    body: SafeArea(
      child: Column(
        children: [
          // ✔️ Keep the TabBar exactly as it was, but now place it manually
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: 'Short Stay'),
                Tab(text: 'Tour Request'),
              ],
            ),
          ),

          // ✔️ TabBarView remains EXACTLY the same
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildShortStayList(_shortStayBookingsFuture),
                _buildTourRequestsList(),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  // --- SHORT STAY BOOKINGS LIST WITH NEW UI ---
  Widget _buildShortStayList(Future<List<BookingModel>> bookingsFuture) {
    return RefreshIndicator(
      onRefresh: () async {
        _fetchShortStayBookings();
        await bookingsFuture;
      },
      child: FutureBuilder<List<BookingModel>>(
        future: bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No Short Stay bookings found.'));
          }

          final bookings = snapshot.data!;
          bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final latestBooking = bookings.first;

          final Map<String, List<BookingModel>> grouped = {};
          for (var b in bookings) {
            String key =
                "${b.user.firstName ?? ''} ${b.user.lastName ?? ''}".trim();
            if (key.isEmpty) key = "Unknown Guest";
            grouped.putIfAbsent(key, () => []).add(b);
          }

          final customers = grouped.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customerName = customers[index];
              final customerBookings = grouped[customerName]!;
              final points = customerBookings.length;
              final isCurrentBooking =
              customerBookings.contains(latestBooking);

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: isCurrentBooking
                      ? LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.9),
                            AppColors.primary.withOpacity(0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isCurrentBooking ? null : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: isCurrentBooking
                        ? Colors.white.withOpacity(0.85)
                        : AppColors.primary.withOpacity(0.1),
                    child: Text(
                      "${index + 1}",
                      style: TextStyle(
                        color: isCurrentBooking
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    customerName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isCurrentBooking ? FontWeight.bold : FontWeight.w600,
                      color: isCurrentBooking
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Text(
                          "${customerBookings.length} booking(s) • ",
                          style: TextStyle(
                            fontSize: 13,
                            color: isCurrentBooking
                                ? Colors.white70
                                : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          customerBookings
                              .map((b) => b.createdAt)
                              .reduce((a, b) => a.isAfter(b) ? a : b)
                              .toLocal()
                              .toString()
                              .split(' ')[0],
                          style: TextStyle(
                            fontSize: 12,
                            color: isCurrentBooking
                                ? Colors.white70
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Text(
                    "$points",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isCurrentBooking
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider(
                          create: (_) {
                            final provider = BookingProvider();
                            provider.setBookings(customerBookings);
                            return provider;
                          },
                          child: CustomerBookingsDetailScreen(
                            customerName: customerName,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }


  Widget _buildTourRequestsList() {
    if (_isLoadingTour) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_tourRequests.isEmpty) {
      return const Center(child: Text('No tour requests found.'));
    }

    // Group by customer name
    final Map<String, List<dynamic>> grouped = {};
    for (var req in _tourRequests) {
      String key = req['customer_name'] ?? 'Unknown';
      grouped.putIfAbsent(key, () => []).add(req);
    }

    final customers = grouped.keys.toList();

    return RefreshIndicator(
      onRefresh: _fetchTourRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: customers.length,
        itemBuilder: (context, index) {
          final name = customers[index];
          final userRequests = grouped[name]!;

          final latestRequest = userRequests.last;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.8),
                  AppColors.primary.withOpacity(0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.85),
                child: Text(
                  "${index + 1}",
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Text(
                      "${userRequests.length} tour request(s) • ",
                      style:
                          const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                    Text(
                      latestRequest['date'] ?? '',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              trailing: Text(
                "${userRequests.length}",
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TourRequestDetailScreen(
                      customerName: name,
                      userRequests: userRequests,
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
