import 'dart:convert';

import 'package:faramas/config/app_routes.dart';
import 'package:faramas/constants/api_constants.dart';
import 'package:faramas/models/booking_model.dart';
import 'package:faramas/screens/change_password_screen.dart';
import 'package:faramas/screens/my_booking.dart';
import 'package:faramas/screens/view_order.dart';
import 'package:faramas/services/booking_services.dart';
import 'package:faramas/widgets/app_popup_dialog.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: unused_import
import '../config/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../l10n/app_localizations.dart';
import 'edit_profile_screen.dart';
import 'my_posted_properties_screen.dart';
import 'help_support_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _handleMenuItemTap(BuildContext context, String action) async {
    switch (action) {
      case 'my_profile':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EditProfileScreen(),
          ),
        );
        break;
      case 'my_properties':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MyPostedPropertiesScreen(),
          ),
        );
        break;
      case 'customer_booking':
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final accessToken = authProvider.accessToken;
        final user = authProvider.user;

        if (accessToken != null && user != null) {
          final uploaderId = user.id ?? 0;

          print("Logged-in Uploader ID: $uploaderId"); // Print uploader ID

          final bookings = await BookingServices.fetchAllBookingsForOwner(
            token: accessToken,
            uploaderId: uploaderId, // Fetch only bookings for this uploader
          );

          print("Total bookings fetched: ${bookings.length}"); // Debug

          // Group bookings by customer
          final Map<String, List<BookingModel>> grouped = {};
          for (var b in bookings) {
            String key =
                "${b.user.firstName ?? ''} ${b.user.lastName ?? ''}".trim();
            if (key.isEmpty) key = "Unknown Guest";
            grouped.putIfAbsent(key, () => []).add(b);
          }

          // Print each customer and their bookings
          grouped.forEach((customer, customerBookings) {
            print("Customer: $customer");
            for (var b in customerBookings) {
              print(
                  "  Booked property: ${b.property.name} (${b.property.id}) uploaded by uploaderId $uploaderId");
            }
          });

          // Navigate after printing
          Navigator.of(context).pushNamed(AppRoutes.ownerBookings);
        } else {
          print("No access token or user found.");
        }

        break;

      case 'change_password':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangePasswordScreen(),
          ),
        );
        break;

      case 'terms':
        // TODO: Navigate to terms page
        break;
      case 'privacy':
        // TODO: Navigate to privacy policy page
        break;
      case 'about':
        Navigator.pushNamed(context, '/aboutApp');
        break;
      case 'help_support':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HelpSupportScreen(),
          ),
        );
        break;
      case 'language':
        _showLanguageDialog(context);
        break;
      case 'my_booking':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MyBookingScreen(),
          ),
        );
        break;

      case 'logout':
        _showLogoutDialog(context);
        break;
      case 'delete':
        _showDeleteAccountDialog(context);
        break;
    }
  }

  void _showLanguageDialog(BuildContext context) {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations?.selectLanguage ?? 'Select Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(
                context,
                languageCode: 'en',
                languageName: 'English',
                flagAsset: 'assets/images/flags/en.png',
                isSelected: languageProvider.isEnglish,
              ),
              const SizedBox(height: 12),
              _buildLanguageOption(
                context,
                languageCode: 'sw',
                languageName: 'Kiswahili',
                flagAsset: 'assets/images/flags/sw.png',
                isSelected: languageProvider.isKiswahili,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations?.cancel ?? 'Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context, {
    required String languageCode,
    required String languageName,
    required String flagAsset,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        Provider.of<LanguageProvider>(context, listen: false)
            .setLanguage(languageCode);
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Image.asset(
              flagAsset,
              width: 32,
              height: 32,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.flag, size: 20),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                languageName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.blue,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context);

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
                  color: Colors.red.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 34,
                  color: Colors.red,
                ),
              ),

              const SizedBox(height: 18),

              // TITLE
              Text(
                localizations?.logoutTitle ?? 'Logout',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 10),

              // MESSAGE
              Text(
                localizations?.logoutMessage ??
                    'Are you sure you want to logout?',
                textAlign: TextAlign.center,
                style: const TextStyle(
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
                      child: Text(
                        localizations?.cancel ?? 'Cancel',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _logoutUser(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.red,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        localizations?.logout ?? 'Logout',
                        style: const TextStyle(
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

  Future<void> _logoutUser(BuildContext context) async {
    debugPrint("Starting logout...");

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    debugPrint(
        "AuthProvider cleared: user=${authProvider.user}, token=${authProvider.accessToken}");

    final prefs = await SharedPreferences.getInstance();

    // Keys used in your AuthService and elsewhere
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    await prefs.remove('customer_id');
    await prefs.remove('user');

    // Also clear keys inside AuthProvider
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('userData');

    debugPrint(
        "SharedPreferences cleared: auth_token, refresh_token, customer_id, user, accessToken, refreshToken, userData");

    // ignore: use_build_context_synchronously
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (Route<dynamic> route) => false,
    );

    debugPrint("Logout complete. User successfully logged out.");
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    AppPopupDialog.show(
      context,
      type: PopupType.warning,
      title: localizations?.deleteAccountTitle ?? 'Delete Account',
      message: localizations?.deleteAccountMessage ??
          'Are you sure you want to delete your account? This action cannot be undone.',
      okText: localizations?.delete ?? 'Delete',
      cancelText: localizations?.cancel ?? 'Cancel',
      onOk: () {
        // TODO: call delete API here
        debugPrint("Account deleted");
      },
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String action,
    required BuildContext context,
    Color? iconColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor ?? const Color(0xFF1E4B6C),
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[800],
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: () => _handleMenuItemTap(context, action),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Row(
                children: [
                  Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 2,
                        ),
                      ),
                      child: user?.userImage != null
                          ? CircleAvatar(
                              radius: 36,
                              backgroundImage: NetworkImage(user!.userImage!),
                            )
                          : CircleAvatar(
                              radius: 36,
                              backgroundColor: Colors.grey[200],
                              child: const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.grey,
                              ),
                            )),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${user?.firstName ?? 'no name'} ${user?.lastName ?? ''}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'no.email@gmail.com',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildProfileOption(
                    icon: Icons.person_outline,
                    title: localizations?.myProfile ?? 'My Profile',
                    action: 'my_profile',
                    context: context,
                  ),
                  user?.role == "property owner" || user?.role == "broker"
                      ? _buildProfileOption(
                          icon: Icons.history,
                          title: localizations?.customerBooking ??
                              'Customer booking',
                          action: 'customer_booking',
                          context: context,
                        )
                      : _buildProfileOption(
                          icon: Icons.history,
                          title: localizations?.myBooking ?? 'My booking',
                          action: 'my_booking',
                          context: context,
                        ),
                  _buildProfileOption(
                    icon: Icons.lock_outline,
                    title: localizations?.changePassword ?? 'Change Password',
                    action: 'change_password',
                    context: context,
                  ),
                  _buildProfileOption(
                    icon: Icons.language,
                    title: localizations?.language ?? 'Language',
                    action: 'language',
                    context: context,
                  ),
                  _buildProfileOption(
                    icon: Icons.description_outlined,
                    title: localizations?.termsAndUse ?? 'Terms & Use',
                    action: 'terms',
                    context: context,
                  ),
                  _buildProfileOption(
                    icon: Icons.privacy_tip_outlined,
                    title: localizations?.privacyPolicy ?? 'Privacy & Policy',
                    action: 'privacy',
                    context: context,
                  ),
                  _buildProfileOption(
                    icon: Icons.info_outline,
                    title: localizations?.aboutApp ?? 'About app',
                    action: 'about',
                    context: context,
                  ),
                  _buildProfileOption(
                    icon: Icons.help_outline,
                    title: localizations?.helpSupport ?? 'Help & Support',
                    action: 'help_support',
                    context: context,
                  ),
                  _buildProfileOption(
                    icon: Icons.logout,
                    title: localizations?.logout ?? 'Logout',
                    action: 'logout',
                    context: context,
                    iconColor: Colors.red[700],
                  ),
                  _buildProfileOption(
                    icon: Icons.delete_outline,
                    title: localizations?.deleteAccount ?? 'Delete account',
                    action: 'delete',
                    context: context,
                    iconColor: Colors.red[700],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/generatePayment');
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payment,
                        size: 28, color: Color(0xFF1E4B6C)),
                    const SizedBox(width: 12),
                    Text(
                      localizations?.subscriptionPayments ??
                          'Subscription Payments',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E4B6C),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                if (user == null) return;

                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('auth_token');

                if (token == null || token.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Access token missing. Please login again.'),
                    ),
                  );
                  return;
                }

                final url = Uri.parse(
                  '${ApiConstants.customerOrders}?customer_id=${user.id}',
                );

                try {
                  final response = await http.get(
                    url,
                    headers: {'Authorization': 'Bearer $token'},
                  );

                  if (response.statusCode == 200) {
                    final orders = json.decode(response.body);

                    if (orders is List && orders.isNotEmpty) {
                      final order = orders.first;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(order: order),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("No orders found.")),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Failed: ${response.statusCode}"),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payment,
                        size: 28, color: Color(0xFF1E4B6C)),
                    const SizedBox(width: 12),
                    Text(
                      localizations?.paymentHistory ?? 'Payment History',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E4B6C),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            if (user?.role == 'broker' || user?.role == 'property owner') ...[
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyPostedPropertiesScreen(),
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.home_outlined,
                          size: 28, color: Color(0xFF1E4B6C)),
                      const SizedBox(width: 12),
                      Text(
                        localizations?.myPostedProperties ??
                            'My Posted Properties',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E4B6C),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
