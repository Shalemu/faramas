import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/airbnb_data.dart';
import 'airbnb_description_screen.dart';

class AirbnbAmenitiesScreen extends StatefulWidget {
  final AirbnbData airbnbData;
  const AirbnbAmenitiesScreen({super.key, required this.airbnbData});

  @override
  State<AirbnbAmenitiesScreen> createState() => _AirbnbAmenitiesScreenState();
}

class _AirbnbAmenitiesScreenState extends State<AirbnbAmenitiesScreen> {
  final Map<String, IconData> _amenities = {
    'WiFi': Icons.wifi,
    'TV': Icons.tv,
    'Kitchen': Icons.kitchen,
    'Washing Machine': Icons.local_laundry_service,
    'Free Parking': Icons.local_parking,
    'Paid Parking': Icons.money,
    'Air Conditioning': Icons.ac_unit,
    'Dedicated Workspace': Icons.work,
    'Pool': Icons.pool,
    'Hot Tub': Icons.hot_tub,
    'Outdoor Dining Area': Icons.outdoor_grill,
    'Firepit': Icons.whatshot,
    'Beach Access': Icons.beach_access,
    'Outdoor Shower': Icons.shower,
    'Smoking Areas': Icons.smoking_rooms,
  };

  late Set<String> _selectedAmenities;

  @override
  void initState() {
    super.initState();
    _selectedAmenities = widget.airbnbData.amenities?.toSet() ?? {};
  }

  void _toggleAmenity(String amenity) {
    setState(() {
      if (_selectedAmenities.contains(amenity)) {
        _selectedAmenities.remove(amenity);
      } else {
        _selectedAmenities.add(amenity);
      }
      widget.airbnbData.amenities = _selectedAmenities.toList();
    });
  }

  Widget _buildAmenityBox(String label, IconData icon) {
    final bool isSelected = _selectedAmenities.contains(label);
    return GestureDetector(
      onTap: () => _toggleAmenity(label),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: isSelected ? AppColors.primary : Colors.grey[700]),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? AppColors.primary : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goNext() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AirbnbDescriptionScreen(airbnbData: widget.airbnbData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> amenityWidgets =
        _amenities.entries.map((entry) => _buildAmenityBox(entry.key, entry.value)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tell Guest what your place has to offer'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Grid scrolls if content is taller than available space
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                padding: const EdgeInsets.all(8),
                children: amenityWidgets,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _goNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Next',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
