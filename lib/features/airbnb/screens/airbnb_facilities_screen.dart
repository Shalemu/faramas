import 'package:faramas/features/airbnb/screens/airbnb_amenities_screen.dart';
import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../models/airbnb_data.dart';


class AirbnbFacilitiesScreen extends StatefulWidget {
  final AirbnbData airbnbData;
  const AirbnbFacilitiesScreen({super.key, required this.airbnbData});

  @override
  State<AirbnbFacilitiesScreen> createState() => _AirbnbFacilitiesScreenState();
}

class _AirbnbFacilitiesScreenState extends State<AirbnbFacilitiesScreen> {
  late int guests;
  late int bedrooms;
  late int beds;
  late int bathrooms;
  late AirbnbData airbnbData;

  @override
  void initState() {
    super.initState();
    // Initialize counters from passed AirbnbData
    guests = widget.airbnbData.guests ?? 1;
    bedrooms = widget.airbnbData.bedrooms ?? 1;
    beds = widget.airbnbData.beds ?? 1;
    bathrooms = widget.airbnbData.bathrooms ?? 1;

    // Remove this line:
    // airbnbData = AirbnbData();
  }

  void _incrementGuests() => setState(() => guests++);
  void _decrementGuests() {
    if (guests > 1) setState(() => guests--);
  }

  void _incrementBedrooms() => setState(() => bedrooms++);
  void _decrementBedrooms() {
    if (bedrooms > 1) setState(() => bedrooms--);
  }

  void _incrementBeds() => setState(() => beds++);
  void _decrementBeds() {
    if (beds > 1) setState(() => beds--);
  }

  void _incrementBathrooms() => setState(() => bathrooms++);
  void _decrementBathrooms() {
    if (bathrooms > 1) setState(() => bathrooms--);
  }

  Widget _buildCounter(String label, int value, VoidCallback onIncrement,
      VoidCallback onDecrement) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 18)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: onDecrement,
              ),
              Text('$value', style: const TextStyle(fontSize: 18)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: onIncrement,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _goNext() {
    // Update AirbnbData with selected values
    widget.airbnbData.guests = guests;
    widget.airbnbData.bedrooms = bedrooms;
    widget.airbnbData.beds = beds;
    widget.airbnbData.bathrooms = bathrooms;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AirbnbAmenitiesScreen(airbnbData: widget.airbnbData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Facilities for ${widget.airbnbData.placeType ?? ""}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Please choose facilities available in your place',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildCounter('Guests', guests, _incrementGuests, _decrementGuests),
            _buildCounter(
                'Bedrooms', bedrooms, _incrementBedrooms, _decrementBedrooms),
            _buildCounter('Beds', beds, _incrementBeds, _decrementBeds),
            _buildCounter('Bathrooms', bathrooms, _incrementBathrooms,
                _decrementBathrooms),
            const Spacer(),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Back',
                      style: TextStyle(fontSize: 16, color: Colors.black87)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _goNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Next',
                        style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
