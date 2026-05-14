import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  bool _additionalServicesExpanded = false;

  final Uri _playStoreUrl = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.faramas.app');
  final Uri _appStoreUrl = Uri.parse('https://apps.apple.com/app/idXXXXXXXXX');

  void _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About FARAMAS',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E4B6C),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                'assets/logo/faramas_logo.png',
                width: 120,
                height: 60,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'FARAMAS: Your Trusted Platform for Real Estate and Property Services in Tanzania',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E4B6C),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'FARAMAS is a user-friendly mobile application designed to connect property owners, brokers, and users across Tanzania. Whether you\'re looking to list, rent, buy, or manage properties—such as houses, apartments, offices, or land—FARAMAS provides a seamless platform to facilitate all your real estate needs.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('For Property Owners & Brokers:'),
            _buildBulletPoint(
                'Post properties (houses, land, apartments, offices) with ease'),
            _buildBulletPoint(
                'Pay a simple subscription fee of TZS 1,000 per month to post unlimited listings for that period'),
            _buildBulletPoint(
                'Reach a wide audience of potential tenants or buyers'),
            const SizedBox(height: 16),
            _buildSectionTitle('For Users & Tenants:'),
            _buildBulletPoint(
                'Search and browse available properties and land listings'),
            _buildBulletPoint(
                'Make bookings and inquiries directly through the app'),
            _buildBulletPoint(
                'Find your ideal home, office space, or land quickly and effortlessly'),
            const SizedBox(height: 16),
            _buildAdditionalServices(),
            const SizedBox(height: 16),
            Row(
              children: const [
                Icon(Icons.phone_android, color: Color(0xFF1E4B6C)),
                SizedBox(width: 8),
                Text(
                  'Key Features',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E4B6C)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildBulletPoint(
                'Easy Listing & Booking: Property owners and brokers can upload listings effortlessly and manage their posts. Users can browse and make inquiries or bookings conveniently.'),
            _buildBulletPoint(
                'Subscription-Based Listings: Unlimited property posts for just TZS 1,000/month, making it affordable for brokers and property owners to reach potential clients.'),
            _buildBulletPoint(
                'Verified Professionals & Users: All brokers and property owners are verified for quality assurance, ensuring trustworthy transactions.'),
            _buildBulletPoint(
                'Advanced Search & Filters: Find properties by location, price, type, and other criteria to suit your preferences.'),
            _buildBulletPoint(
                'Secure Transactions: Safe and transparent payment options for listings and services.'),
            _buildBulletPoint(
                'Real-Time Notifications: Stay updated on new listings, inquiries, and booking confirmations.'),
            _buildBulletPoint(
                'Customer Support: 24/7 in-app support to assist with any questions or issues.'),
            const SizedBox(height: 16),
            _buildSectionTitle('Benefits of Using FARAMAS'),
            _buildBulletPoint(
                'Convenience: All your property needs in one platform—listing, searching, booking, and managing.'),
            _buildBulletPoint(
                'Accessibility: Reach a broad audience of property seekers and investors across Tanzania.'),
            _buildBulletPoint(
                'Cost-Effective: Affordable subscription model for property owners and brokers with unlimited postings.'),
            _buildBulletPoint(
                'Trust & Security: Verified users and secure transactions ensure peace of mind.'),
            _buildBulletPoint(
                'Comprehensive Services: Beyond property listings, access financial advice, property management, and marketing support.'),
            const SizedBox(height: 16),
            _buildSectionTitle('Serving Tanzania and Beyond'),
            const Text(
              'FARAMAS is dedicated to transforming the real estate market in Tanzania by providing a reliable, efficient, and affordable platform for property owners, brokers, and users. We are continually expanding our services to meet the evolving needs of the community.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Download FARAMAS Today'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Google Play Store Button
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: ElevatedButton.icon(
                      onPressed: () => _launchUrl(_playStoreUrl),
                      icon: const Icon(
                        Icons.android,
                        color: Colors.white,
                        size: 24,
                      ),
                      label: const Text(
                        'Google Play',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF01875F),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                ),
                // App Store Button
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: ElevatedButton.icon(
                      onPressed: () => _launchUrl(_appStoreUrl),
                      icon: const Icon(
                        Icons.apple,
                        color: Colors.white,
                        size: 24,
                      ),
                      label: const Text(
                        'App Store',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF000000),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Alternative download section with more detailed buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E4B6C).withOpacity(0.1),
                    const Color(0xFF2E5B7C).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF1E4B6C).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Get the app on your device',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E4B6C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Detailed Google Play Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _launchUrl(_playStoreUrl),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF01875F),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.android,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'GET IT ON',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'Google Play',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Detailed App Store Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _launchUrl(_appStoreUrl),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF000000),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.apple,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'DOWNLOAD ON THE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'App Store',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Experience the easiest way to list, find, and book properties and related services. Download the app now from the Google Play Store or Apple App Store and take your property journey to the next level.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalServices() {
    return ExpansionPanelList(
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          _additionalServicesExpanded = !isExpanded;
        });
      },
      children: [
        ExpansionPanel(
          headerBuilder: (BuildContext context, bool isExpanded) {
            return ListTile(
              title: const Text(
                'Additional Services Offered:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E4B6C),
                ),
              ),
            );
          },
          body: Column(
            children: const [
              ListTile(title: Text('Financial Consultancy')),
              ListTile(title: Text('Property Management')),
              ListTile(title: Text('Real Estate Investment Advice')),
              ListTile(
                  title: Text(
                      'Marketing & Advertising for Property Owners and Brokers')),
            ],
          ),
          isExpanded: _additionalServicesExpanded,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E4B6C),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 20, color: Color(0xFF1E4B6C)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
