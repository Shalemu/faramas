import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();

  late final AnimationController _animationController;
  late final List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimations = List.generate(5, (index) {
      final start = index * 0.1;
      final end = start + 0.5;
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrlString(url)) {
      throw Exception('Could not launch $url');
    }
  }

  Widget _buildContactOption({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    required Animation<Offset> animation,
  }) {
    return SlideTransition(
      position: animation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/support.jpg',
                    height: 180,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Welcome to Faramas App Help Center',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'re here to assist you. If you have questions or need help, explore our services  and FAQs and support. Your satisfaction is our priority.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactOption(
              title: 'Call Us',
              value: '+255 792 204 664',
              color: Colors.black87,
              icon: Icons.phone,
              onTap: () {
                _launchUrl('tel:+255792204664');
              },
              animation: _slideAnimations[0],
            ),
            _buildContactOption(
              title: 'WhatsApp',
              value: '+255 792 204 664',
              color: Colors.green,
              icon: Icons.message,
              onTap: () {
                _launchUrl('https://wa.me/255792204664');
              },
              animation: _slideAnimations[1],
            ),
            _buildContactOption(
              title: 'Instagram',
              value: '@app.co.tz',
              color: Colors.pink,
              icon: Icons.camera,
              onTap: () {
                _launchUrl('https://instagram.com/app.co.tz');
              },
              animation: _slideAnimations[2],
            ),
            _buildContactOption(
              title: 'Website',
              value: 'app.co.tz',
              color: Colors.blue,
              icon: Icons.language,
              onTap: () {
                _launchUrl('https://app.co.tz');
              },
              animation: _slideAnimations[3],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
