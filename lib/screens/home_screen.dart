import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Providers
import '../providers/booking.dart';
import '../providers/auth_provider.dart';
import '../providers/tour_request_provider.dart';

// Screens
import '../screens/home_content_screen.dart';
import '../screens/owner_booking_screen.dart';
import '../screens/favoritie_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/upload_screen.dart';
import '../screens/airbnb_upload_screen.dart';

// Widgets & Config
import '../widgets/welcome_popup.dart';
import '../config/app_colors.dart';
import '../l10n/app_localizations.dart';

// Packages

import 'package:motion_toast/motion_toast.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _showUploadOptions = false;
  bool _showWelcomePopup = false;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pages = const [
      HomeContentScreen(),
      OwnerBookingsScreen(),
      FavoritesScreen(),
      ProfileScreen(),
    ];

    _checkWelcomePopupOnStart();
    _fetchBookingsOnStart();
    _fetchTourRequestsOnStart();
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ICON
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 34,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 18),

              // TITLE
              const Text(
                "Login required",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 10),

              // MESSAGE
              const Text(
                "Please log in to continue using this feature.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF6B7280),
                ),
              ),

              const SizedBox(height: 24),

              // BUTTONS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/login');
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchBookingsOnStart() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    final uploaderId = authProvider.user?.id ?? 0;

    if (uploaderId != 0) {
      await bookingProvider.fetchAll(uploaderId);
    }
  }

  Future<void> _fetchTourRequestsOnStart() async {
    final tourRequestProvider =
        Provider.of<TourRequestProvider>(context, listen: false);
    await tourRequestProvider.fetchTourRequests();
  }

  Future<void> _checkWelcomePopupOnStart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_shown_welcome_this_session', false);
    _checkWelcomePopup();
  }

  Future<void> _checkWelcomePopup() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool('has_shown_welcome_this_session') ?? false;

    if (!hasShown && mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _showWelcomePopup = true);
      });
    }
  }

  Future<void> _closeWelcomePopup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_shown_welcome_this_session', true);
    if (mounted) setState(() => _showWelcomePopup = false);
  }

  List<AppBar> _getAppBars(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return [
      AppBar(backgroundColor: AppColors.background, elevation: 0, title: null),
      AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          localizations?.bookings ?? 'Bookings',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          localizations?.favorites ?? 'Favorites',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          localizations?.profile ?? 'Profile',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ];
  }

  void _onItemTapped(int index) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    // If user tries to access Profile (index 3) but is not logged in
    if (index == 3 && user == null) {
      showDialog(
        context: context,
        barrierDismissible: false, // Force user to choose
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          backgroundColor: AppColors.background,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top icon with gradient
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 40,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                const Text(
                  'Login Required',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                // Message
                const Text(
                  'Please log in to access your profile and enjoy all premium features.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.grey),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.pushNamed(context, '/login');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          backgroundColor: AppColors.primary,
                          elevation: 5,
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      return; // Prevent changing selected index
    }

    // Update bottom navigation index
    setState(() => _selectedIndex = index);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _checkWelcomePopup();
      _fetchBookingsOnStart();
      _fetchTourRequestsOnStart();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final localizations = AppLocalizations.of(context);
    final appBars = _getAppBars(context);

    return Scaffold(
      appBar: appBars[_selectedIndex],
      body: Stack(
        children: [
          _pages[_selectedIndex],
          if (_showWelcomePopup && _selectedIndex == 0)
            WelcomePopup(onClose: _closeWelcomePopup),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1E4B6C),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded, size: 28),
            activeIcon: const Icon(Icons.home_rounded, size: 32),
            label: localizations?.home ?? 'Home',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined, size: 28),
                Consumer<BookingProvider>(
                  builder: (_, provider, __) {
                    final pendingCount = provider.pendingCount;
                    if (pendingCount == 0) return const SizedBox();
                    return Positioned(
                      right: -6,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 20, minHeight: 20),
                        child: Text(
                          '$pendingCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            activeIcon: const Icon(Icons.notifications, size: 32),
            label: localizations?.notifications ?? 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite_border, size: 28),
            activeIcon: const Icon(Icons.favorite, size: 32),
            label: localizations?.favorites ?? 'Favorite',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline_rounded, size: 28),
            activeIcon: const Icon(Icons.person_rounded, size: 32),
            label: localizations?.profile ?? 'Profile',
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_showUploadOptions) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ElevatedButton(
                onPressed: () async {
                  if (!context.mounted) return;

                  try {
                    if (user == null) {
                      _showLoginRequiredDialog();
                      return;
                    }

                    if (user.role == 'customer') {
                      if (!context.mounted) return;

                      MotionToast.warning(
                        title: const Text('Access Denied'),
                        description: const Text(
                          'Only brokers or owners can upload properties.',
                        ),
                      ).show(context);

                      return;
                    }

                    if (!context.mounted) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AirbnbUploadScreen()),
                    );
                  } catch (e) {
                    debugPrint("ShortStay Button Error: $e");
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  localizations?.shortStay ?? 'Short Stay',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),

            // 🔹 Normal Upload Button
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: FloatingActionButton(
                heroTag: 'normalUpload',
                onPressed: () async {
                  if (!context.mounted) return;

                  try {
                    if (user == null) {
                      _showLoginRequiredDialog();
                      return;
                    }

                    if (user.role == 'customer') {
                      MotionToast.warning(
                        title: const Text('Access Denied'),
                        description: const Text(
                          'Only brokers or owners can upload properties.',
                        ),
                      ).show(context);

                      return;
                    }

                    if (!context.mounted) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UploadScreen()),
                    );
                  } catch (e) {
                    debugPrint("NormalUpload Button Error: $e");
                  }
                },
                backgroundColor: AppColors.primary,
                child: const Icon(
                  Icons.cloud_upload_rounded,
                  size: 34,
                  color: Colors.white,
                ),
              ),
            ),
          ],

          // Toggle Floating Button
          FloatingActionButton(
            heroTag: 'toggleButton',
            onPressed: () =>
                setState(() => _showUploadOptions = !_showUploadOptions),
            backgroundColor: AppColors.primary,
            child: Icon(
              _showUploadOptions ? Icons.close_rounded : Icons.add_rounded,
              size: 36,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
