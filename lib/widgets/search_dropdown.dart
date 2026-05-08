import 'package:flutter/material.dart';
import 'package:faramas/models/property_model.dart';

class SearchDropdown extends StatefulWidget {
  final TextEditingController controller;
  final List<PropertyModel> allProperties;
  final double? currentLat;
  final double? currentLng;
  final String selectedCategory;
 final Function(String category, String location, String type)? onSearchSubmitted;
  final Function(String)? onCategorySelected;

  const SearchDropdown(
      {Key? key,
      required this.controller,
      required this.allProperties,
      required this.currentLat,
      required this.currentLng,
      required this.selectedCategory,
      this.onSearchSubmitted,
      this.onCategorySelected})
      : super(key: key);

  @override
  _SearchDropdownState createState() => _SearchDropdownState();
}

class _SearchDropdownState extends State<SearchDropdown> {
  bool _isDropdownVisible = false;
  String? _selectedFilter;

  final List<String> _filters = ['For Sale', 'For Rent', 'Sold'];

  final List<Map<String, dynamic>> _suggestedDestinations = [
    {
      'label': 'Nearby',
      'description': 'Find properties near your current location',
      'icon': Icons.near_me
    },
    {
      'label': 'Dar es Salaam, Tanzania',
      'description': 'Search properties in the city center and suburbs',
      'icon': Icons.location_city
    },
    {
      'label': 'Zanzibar Island, Tanzania',
      'description': 'Discover properties on this beautiful island',
      'icon': Icons.beach_access
    },
    {
      'label': 'Zanzibar, Tanzania',
      'description': 'Explore seaside homes and resorts',
      'icon': Icons.waves
    },
    {
      'label': 'Kendwa, Tanzania',
      'description': 'Explore homes in this peaceful coastal town',
      'icon': Icons.landscape
    },
  ];

  void _toggleDropdown() {
    setState(() => _isDropdownVisible = !_isDropdownVisible);
  }

 void _handleSearchSubmission(String locationLabel) {
  final selectedFilter = _selectedFilter ?? widget.selectedCategory;
  
  widget.controller.text = '$selectedFilter in $locationLabel';

  widget.onSearchSubmitted?.call(
    selectedFilter.toLowerCase(),
    locationLabel.toLowerCase(),
    '', 
  );

  setState(() {
    _selectedFilter = null;
    _isDropdownVisible = false;
    widget.controller.clear();
  });
}


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.controller,
          onSubmitted: (query) {
            if (query.trim().isNotEmpty) {
              final parts = query.toLowerCase().split(',');
              String location = '';
              String type = '';

              for (var part in parts) {
                final trimmed = part.trim();
                if (trimmed.contains('apartment') ||
                    trimmed.contains('room') ||
                    trimmed.contains('house') ||
                    trimmed.contains('land') ||
                    trimmed.contains('office')) {
                  type = trimmed;
                } else {
                  location = trimmed;
                }
              }

              final selectedCategory =
                  _selectedFilter ?? widget.selectedCategory;

              widget.onSearchSubmitted?.call(
                selectedCategory.toLowerCase(),
                location,
                type,
              );

              setState(() {
                _selectedFilter = null;
                _isDropdownVisible = false;
                widget.controller.clear();
              });
            }
          },
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Search Property',
            filled: true,
            fillColor: Colors.grey.shade200,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
            suffixIcon: IconButton(
              icon: Icon(_isDropdownVisible
                  ? Icons.arrow_drop_up
                  : Icons.arrow_drop_down),
              onPressed: _toggleDropdown,
            ),
          ),
        ),
        if (_isDropdownVisible)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 8,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _filters.map((filter) {
                    final isSelected = filter == _selectedFilter;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedFilter = filter);
                        widget.onCategorySelected?.call(filter);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? Colors.blue : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text('Suggested destinations',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                ..._suggestedDestinations.map((destination) {
                  return ListTile(
                    leading: Icon(destination['icon'], color: Colors.blue),
                    title: Text(destination['label']),
                    subtitle: Text(destination['description']),
                    onTap: () {
                      _handleSearchSubmission(destination['label']);
                      _toggleDropdown();
                    },
                  );
                }).toList(),
              ],
            ),
          ),
      ],
    );
  }
}
