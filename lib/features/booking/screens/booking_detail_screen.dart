import 'package:faramas/providers/booking.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart' show Provider, Consumer;
import 'package:url_launcher/url_launcher.dart';
import '../../../config/app_colors.dart';
import '../../../models/booking_model.dart';
import '../../../models/property_model.dart';
import '../../../models/user_model.dart';
// ignore: unused_import
import 'package:faramas/constants/api_constants.dart';

class BookingDetailScreen extends StatefulWidget {
  final BookingModel booking;
  const BookingDetailScreen({super.key, required this.booking});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  Future<void> _updateStatus(BookingModel booking, String newStatus) async {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    final success = await provider.updateBookingStatus(booking.id, newStatus);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking status updated to $newStatus')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update booking')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(builder: (context, provider, child) {
      final booking = provider.bookings.firstWhere(
          (b) => b.id == widget.booking.id,
          orElse: () => widget.booking);
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: const Text(
            'Booking Details',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Property Details'),
              _buildPropertyCard(context, booking.property, booking),
              const SizedBox(height: 20),

              _buildSectionTitle('Booking Information'),
              // _buildDetailRow(Icons.confirmation_num_outlined, 'Booking ID:',
              //     booking.id.toString()),
              _buildDetailRow(Icons.calendar_today, 'Booked Date:',
                  booking.createdAt.toLocal().toString().split(' ')[0]),
              if (booking.notes != null && booking.notes!.isNotEmpty)
                _buildDetailRow(Icons.note_alt, 'Notes:', booking.notes!),
              _buildDetailRow(Icons.date_range, 'Check-In Date:',
                  booking.checkInDate != null
                      ? booking.checkInDate!.toLocal().toString().split(' ')[0]
                      : 'N/A'),
              _buildDetailRow(Icons.date_range, 'Check-Out Date:',
                  booking.checkOutDate != null
                      ? booking.checkOutDate!
                          .toLocal()
                          .toString()
                          .split(' ')[0]
                      : 'N/A'),
                      


              // _buildDetailRow(Icons.check_circle_outline, 'Status:',
              //     booking.status.toUpperCase()),
              const SizedBox(height: 20),

              _buildSectionTitle('Customer Detail'),
              _buildUserContactCard(
                context,
                user: booking.user,
                isUploader: false, // This is the user who booked
              ),
              const SizedBox(height: 20),

              // Center(
              //   child: ElevatedButton.icon(
              //     onPressed: () {
              //       Navigator.push(
              //         context,
              //         MaterialPageRoute(
              //           builder: (context) =>
              //               PropertyDetailScreen(property: booking.property),
              //         ),
              //       );
              //     },
              //     icon: const Icon(Icons.info_outline),
              //     label: const Text('View Full Property Details'),
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: AppColors.primary,
              //       foregroundColor: Colors.white,
              //       padding: const EdgeInsets.symmetric(
              //           horizontal: 24, vertical: 12),
              //       shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(10)),
              //     ),
              //   ),
              // ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(
      BuildContext context, PropertyModel property, BookingModel booking) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full-width image gallery or fallback
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: property.images.isNotEmpty
                ? SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: property.images.length,
                      itemBuilder: (context, index) {
                        final imageUrl = property.images[index];
                        return Padding(
                          padding: EdgeInsets.only(
                              right: index == property.images.length - 1
                                  ? 0
                                  : 8.0),
                          child: Image.network(
                            imageUrl,
                            width: MediaQuery.of(context).size.width * 0.85,
                            height: 220,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset('assets/images/placeholder.png',
                                    width: MediaQuery.of(context).size.width *
                                        0.85,
                                    height: 220,
                                    fit: BoxFit.cover),
                          ),
                        );
                      },
                    ),
                  )
                : Image.network(
                    property.imageUrl ?? 'https://via.placeholder.com/300x200',
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/images/placeholder.png',
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover),
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        property.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (booking.status == "pending") ...[
                      TextButton(
                        onPressed: () => _updateStatus(booking, "confirmed"),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'pending',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: () => _updateStatus(booking, "cancelled"),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'cancel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ] else if (booking.status == "confirmed")
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'confirmed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (booking.status == "cancelled")
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'cancelled',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  property.address,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Type: ${property.type} (${property.category})',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Divider(height: 24),
                _buildDetailRow(
                    Icons.attach_money, 'Price:', 'Tzs ${property.price}'),
                _buildDetailRow(Icons.money_off, 'Maintenance:',
                    'Tzs ${property.maintenance}'),
                _buildDetailRow(Icons.swap_horiz, 'Status:',
                    property.isRent ? 'For Rent' : 'For Sale'),
                _buildDetailRow(
                    Icons.description, 'Description:', property.description),
                if (property.facilities.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSectionTitle('Facilities'),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: property.facilities
                        .map((f) => Chip(
                              label: Text(f.name),
                              backgroundColor: AppColors.primaryLight,
                              labelStyle:
                                  const TextStyle(color: AppColors.textLight),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserContactCard(BuildContext context,
      {required UserModel user, required bool isUploader}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: user.userImage != null
                      ? NetworkImage(user.userImage!)
                      : null,
                  child: user.userImage == null
                      ? const Icon(Icons.person,
                          size: 32, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user.firstName} ${user.lastName}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        user.role!.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

const SizedBox(height: 6),

Row(
  children: [
    const Text(
      'Phone: ',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
    ),
    GestureDetector(
      onTap: () {
        final phone = user.phone ?? '';
        if (phone.isEmpty) return;

        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (BuildContext context) {
            return SafeArea(
              child: Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.phone, color: AppColors.primary),
                    title: const Text('Call now'),
                    onTap: () async {
                      final Uri callUri = Uri(scheme: 'tel', path: phone);
                      Navigator.pop(context);
                      await launchUrl(callUri);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.copy, color: Colors.blue),
                    title: const Text('Copy number'),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: phone));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Number copied to clipboard'),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_add_alt_1,
                        color: Colors.green),
                    title: const Text('Save to contacts'),
                    onTap: () async {
                      Navigator.pop(context);
                      final Uri saveUri = Uri.parse('tel:$phone');
                      await launchUrl(saveUri);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      child: Text(
        user.phone ?? 'No phone available',
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.none, 
        ),
      ),
    ),
  ],
),


            _buildDetailRow(Icons.email, 'Email:', user.email),
            // if (user.location != null && user.location!.isNotEmpty)
              // _buildDetailRow(Icons.location_on, 'Location:', user.location!),
            const SizedBox(height: 16),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceAround,
            //   children: [
            //     ElevatedButton.icon(
            //       onPressed: () => _makePhoneCall(user.phone!),
            //       icon: const Icon(Icons.phone, size: 20),
            //       label: const Text('Call'),
            //       style: ElevatedButton.styleFrom(
            //         backgroundColor: AppColors.success,
            //         foregroundColor: Colors.white,
            //         padding: const EdgeInsets.symmetric(
            //             horizontal: 16, vertical: 12),
            //         shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(10)),
            //       ),
            //     ),
            //     ElevatedButton.icon(
            //       onPressed: () => _sendEmail(user.email),
            //       icon: const Icon(Icons.email, size: 20),
            //       label: const Text('Email'),
            //       style: ElevatedButton.styleFrom(
            //         backgroundColor: AppColors.secondary,
            //         foregroundColor: Colors.white,
            //         padding: const EdgeInsets.symmetric(
            //             horizontal: 16, vertical: 12),
            //         shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(10)),
            //       ),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // Handle error: could not launch phone dialer
      print('Could not launch $phoneNumber');
    }
  }

  // ignore: unused_element
  void _sendEmail(String emailAddress) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // Handle error: could not launch email client
      print('Could not launch $emailAddress');
    }
  }
}
