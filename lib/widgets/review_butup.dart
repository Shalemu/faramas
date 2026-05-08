// const SizedBox(height: 20),
// const Text(
// 'Locality Reviews',
// style: TextStyle(
// fontSize: 18,
// fontWeight: FontWeight.bold,
// color: AppColors.textPrimary,
// ),
// ),
// const SizedBox(height: 8),
// Container(
// padding: const EdgeInsets.all(16),
// decoration: BoxDecoration(
// color: Colors.grey[100],
// borderRadius: BorderRadius.circular(12),
// ),
// child: Column(
// children: [
// Row(
// children: [
// Text(
// '4.3',
// style: TextStyle(
// fontSize: 48,
// fontWeight: FontWeight.bold,
// color: Colors.amber[700],
// ),
// ),
// const SizedBox(width: 16),
// Expanded(
// child: Column(
// children: [
// _buildRatingBar(5, 0.8),
// _buildRatingBar(4, 0.6),
// _buildRatingBar(3, 0.4),
// _buildRatingBar(2, 0.2),
// _buildRatingBar(1, 0.1),
// ],
// ),
// ),
// ],
// ),
// const SizedBox(height: 16),
// SizedBox(
// width: double.infinity,
// child: ElevatedButton(
// onPressed: () {},
// style: ElevatedButton.styleFrom(
// backgroundColor: AppColors.primary,
// padding: const EdgeInsets.symmetric(vertical: 12),
// ),
// child: const Text('Add Rating'),
// ),
// ),
// ],
// ),
// ),


// Widget _buildRatingBar(int rating, double percentage) {
//   return Padding(
//     padding: const EdgeInsets.symmetric(vertical: 2),
//     child: Row(
//       children: [
//         Text(
//           '$rating★',
//           style: TextStyle(
//             color: Colors.amber[700],
//             fontSize: 14,
//           ),
//         ),
//         const SizedBox(width: 8),
//         Expanded(
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(4),
//             child: LinearProgressIndicator(
//               value: percentage,
//               backgroundColor: Colors.grey[300],
//               valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[700]!),
//               minHeight: 8,
//             ),
//           ),
//         ),
//       ],
//     ),
//   );
// }
