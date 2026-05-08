import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Consistent background color
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // An icon to visually represent the inbox/messages
              Icon(
                Icons.mark_chat_unread_rounded,
                size: 80, // A larger, more prominent icon
                color: AppColors.primary.withOpacity(0.6), // A softer primary color
              ),
              const SizedBox(height: 24), // Spacing
              // A clear and welcoming message
              const Text(
                'Your Inbox Awaits!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12), // Spacing
              // An explanatory message about the current state
              const Text(
                'Messages from properties you\'ve inquired about, or users who contact you, will appear here.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24), // Spacing
              // Optional: A button to navigate to properties or initiate a search
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement navigation to Home/Properties or Search
                  // For now, you might just pop to the main screen or do nothing.
                  // Navigator.of(context).pop(); // Example to go back
                },
                icon: const Icon(Icons.search_rounded),
                label: const Text('Explore Properties'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}