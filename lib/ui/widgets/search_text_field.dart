import 'package:flutter/material.dart';

class SearchTextField extends StatelessWidget {
  final TextEditingController controller;
  final String search;
  final String language;
  final ValueChanged<String> onChanged;
  final VoidCallback onCleared;

  const SearchTextField({
    super.key,
    required this.controller,
    required this.search,
    required this.language,
    required this.onChanged,
    required this.onCleared,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
        hintText: language == 'fr' ? 'Rechercher...' : 'Search...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: search.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: onCleared,
              )
            : null,
        filled: true,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
        onChanged: onChanged,
      ),
    );
  }
}
