// import 'package:flutter/material.dart';

// class NotificationScreen extends StatelessWidget {
//   const NotificationScreen({super.key});

//   final List<Map<String, String>> notifications = const [
//     {
//       'title': 'Test the Notification',
//       'subtitle': 'Notification is in the process',
//       'image': 'assets/images/profile_placeholder.png', // Placeholder for user image
//     },
//     {
//       'title': 'Test the Notification',
//       'subtitle': 'Notification is in the process',
//       'image': 'assets/images/profile_placeholder.png',
//     },
//     {
//       'title': 'Test the Notification',
//       'subtitle': 'Notification is in the process',
//       'image': 'assets/images/profile_placeholder.png',
//     },
//     {
//       'title': 'Test the Notification',
//       'subtitle': 'Notification is in the process',
//       'image': 'assets/images/profile_placeholder.png',
//     },
//     {
//       'title': 'Test the Notification',
//       'subtitle': 'Notification is in the process',
//       'image': 'assets/images/profile_placeholder.png',
//     },
//     {
//       'title': 'Test the Notification',
//       'subtitle': 'Notification is in the process',
//       'image': 'assets/images/profile_placeholder.png',
//     },
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Notification'),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: BackButton(color: Colors.black),
//         foregroundColor: Colors.black,
//       ),
//       body: ListView.builder(
//         padding: const EdgeInsets.all(12),
//         itemCount: notifications.length,
//         itemBuilder: (context, index) {
//           final notification = notifications[index];
//           return Container(
//             margin: const EdgeInsets.symmetric(vertical: 6),
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.lightBlue.shade50,
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: ListTile(
//               leading: CircleAvatar(
//                 radius: 24,
//                 backgroundColor: Colors.grey.shade300,
//                 // User will replace this with actual image manually
//                 child: const Icon(Icons.person, color: Colors.grey),
//               ),
//               title: Text(
//                 notification['title'] ?? '',
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//               subtitle: Text(notification['subtitle'] ?? ''),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
