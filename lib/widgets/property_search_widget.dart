import 'package:flutter/material.dart';

class PropertySearchWidget extends StatefulWidget {
  final Function(String search) onSearch;

  const PropertySearchWidget({
    super.key,
    required this.onSearch,
 
  });

  @override
  State<PropertySearchWidget> createState() => _PropertySearchWidgetState();
}

class _PropertySearchWidgetState extends State<PropertySearchWidget> {
  final TextEditingController _controller = TextEditingController();

  void _search() {
    final query = _controller.text.trim();

    if (query.isNotEmpty) {
      widget.onSearch(query);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _search(),
        decoration: InputDecoration(
          hintText: 'Search properties, locations, categories...',
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 15,
          ),

          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(
              Icons.search,
              size: 24,
            ),
          ),

          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _controller.clear();
                    setState(() {});
                  },
                )
              : null,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: BorderSide.none,
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: BorderSide.none,
          ),

          filled: true,
          fillColor: Colors.white,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}