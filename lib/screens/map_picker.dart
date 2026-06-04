import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/app_colors.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _pickedLocation;
  bool _loading = false;

  late final MapController _mapController;
  final TextEditingController _searchController = TextEditingController();

  final String mapTilerApiKey = 'TeXYsuIuJeX1NepPjksu';

  final Map<String, String> _mapStyles = {
    'Streets': 'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=',
    'Satellite + Labels':
        'https://api.maptiler.com/maps/hybrid/{z}/{x}/{y}.jpg?key=',
    'Satellite (No Labels)':
        'https://api.maptiler.com/maps/satellite/{z}/{x}/{y}.jpg?key=',
    'Basic': 'https://api.maptiler.com/maps/basic/{z}/{x}/{y}.png?key=',
    'Topographic': 'https://api.maptiler.com/maps/topo/{z}/{x}/{y}.png?key=',
    'Bright': 'https://api.maptiler.com/maps/bright/{z}/{x}/{y}.png?key=',
  };

  String _selectedMapStyle = 'Streets';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  void _onTap(LatLng latlng) {
    setState(() {
      _pickedLocation = latlng;
    });
  }

  /// ---------------- ADDRESS API ----------------
  Future<Map<String, String>> _getAddress(double lat, double lng) async {
    final url = Uri.parse(
      'https://api.maptiler.com/geocoding/$lng,$lat.json?key=$mapTilerApiKey',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      return {
        'address': 'Unknown location',
        'district': '',
        'region': '',
        'country': '',
      };
    }

    final data = json.decode(response.body);

    if (data['features'] == null || data['features'].isEmpty) {
      return {
        'address': 'Unknown location',
        'district': '',
        'region': '',
        'country': '',
      };
    }

    final feature = data['features'][0];
    final context = feature['context'] ?? [];

    String? district;
    String? region;
    String? country;

    for (var item in context) {
      final id = item['id'] ?? '';
      final text = item['text'] ?? '';

      if (id.contains('country')) country = text;
      if (id.contains('region')) region = text;
      if (id.contains('district') || id.contains('county')) {
        district = text;
      }
    }

    final address = feature['place_name'] ?? feature['text'] ?? '';

    return {
      'address': address,
      'district': district ?? '',
      'region': region ?? '',
      'country': country ?? '',
    };
  }

  /// ---------------- CONFIRM ----------------
  Future<void> _onConfirm() async {
    if (_pickedLocation == null) return;

    setState(() => _loading = true);

    try {
      final lat = _pickedLocation!.latitude;
      final lng = _pickedLocation!.longitude;

      final result = await _getAddress(lat, lng);

      debugPrint("CONFIRMED LOCATION:");
      debugPrint("Lat: $lat");
      debugPrint("Lng: $lng");
      debugPrint("Address: ${result['address']}");

      if (!mounted) return;

      Navigator.pop(context, {
        'latitude': lat,
        'longitude': lng,
        'address': result['address'],
        'district': result['district'],
        'region': result['region'],
        'country': result['country'],
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Failed to get location: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// ---------------- SEARCH ----------------
  Future<void> _searchPlace() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final url = Uri.parse(
      'https://api.maptiler.com/geocoding/$query.json?key=$mapTilerApiKey',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) return;

    final data = json.decode(response.body);
    final features = data['features'] as List;

    if (features.isEmpty) return;

    final first = features[0];
    final coords = first['geometry']['coordinates'];

    final lat = coords[1];
    final lng = coords[0];

    setState(() {
      _pickedLocation = LatLng(lat, lng);
      _mapController.move(_pickedLocation!, 15);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tileUrl = _mapStyles[_selectedMapStyle]! + mapTilerApiKey;

    final hasLocation = _pickedLocation != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color:Colors.white),
        title: const Text("Pick Location",
        style: TextStyle(color:Colors.white),
        ),
      ),

      /// ---------------- MAP ----------------
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _pickedLocation ?? LatLng(-6.7924, 39.2083),
              zoom: 13,
              onTap: (tapPosition, latlng) => _onTap(latlng),
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                userAgentPackageName: 'com.app.app',
              ),
              if (hasLocation)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _pickedLocation!,
                      width: 50,
                      height: 50,
                      builder: (context) {
                        return const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        );
                      },
                    ),
                  ],
                ),
            ],
          ),

          /// ---------------- SEARCH ----------------
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search location...",
                  prefixIcon: const Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _searchPlace,
                  ),
                ),
              ),
            ),
          ),

          /// ---------------- CONFIRM BUTTON ----------------
          if (hasLocation)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: _loading ? null : _onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Confirm Location",
                        style: TextStyle(fontSize: 16, color:Colors.white),
                      ),
              ),
            ),

          /// ---------------- LAYERS ----------------
          Positioned(
            bottom: 100,
            right: 16,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.layers, color: AppColors.primary),
              onSelected: (val) {
                setState(() => _selectedMapStyle = val);
              },
              itemBuilder: (_) {
                return _mapStyles.keys.map((key) {
                  return PopupMenuItem(
                    value: key,
                    child: Text(key),
                  );
                }).toList();
              },
            ),
          ),
        ],
      ),
    );
  }
}
