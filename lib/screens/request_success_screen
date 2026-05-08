import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class TourRequestSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> tourData;

  const TourRequestSuccessScreen({super.key, required this.tourData});

  Color get statusColor => tourData["is_complete"] ? Colors.teal : Colors.deepOrange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Tour Requested'),
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_rounded, color: Colors.indigo, size: 60),
                  const SizedBox(height: 10),
                  const Text(
                    'Your Tour Has Been Requested!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: Colors.grey[300]),
                  const SizedBox(height: 10),

                  _buildInfoRow(Icons.home_rounded, 'Property', tourData["property_name"]),
                  _buildInfoRow(Icons.calendar_today_rounded, 'Date', tourData["date"]),
                  _buildInfoRow(Icons.access_time_rounded, 'Time', tourData["time"]),
                  // _buildInfoRow(Icons.phone_rounded, 'Phone', tourData["phone"]),
                  _buildInfoRow(Icons.directions_walk_rounded, 'Type', tourData["type"].toString().toUpperCase()),
                  _buildInfoRow(Icons.info_outline_rounded, 'Status',
                      tourData["is_complete"] ? "Completed" : "Pending",
                      valueColor: statusColor),
                  
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,),
                    label: const Text('Back to Home',
                     style: TextStyle(color: Colors.white),),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[700], size: 20),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: valueColor ?? Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
