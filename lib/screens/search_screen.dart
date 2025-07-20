import 'package:flutter/material.dart';
import '../models/place_category.dart';

class SearchScreen extends StatefulWidget {
  final List<PlaceCategory> allCategories;
  final Future<void> Function(BuildContext context, String apiType) onPlaceTap;

  const SearchScreen({
    Key? key,
    required this.allCategories,
    required this.onPlaceTap,
  }) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<PlaceCategory> filteredCategories = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredCategories = widget.allCategories;
    _searchController.addListener(_filter);
  }

  void _filter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredCategories = widget.allCategories
          .where((cat) => cat.name.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Search places...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              if (_searchController.text.isEmpty) {
                Navigator.of(context).pop();
              } else {
                _searchController.clear();
              }
            },
          ),
        ],
      ),
      body: filteredCategories.isEmpty
          ? const Center(child: Text("No results found"))
          : ListView.builder(
              itemCount: filteredCategories.length,
              itemBuilder: (context, index) {
                final category = filteredCategories[index];
                return ListTile(
                  leading: Icon(category.icon, color: theme.colorScheme.primary),
                  title: Text(category.name),
                  onTap: () async {
                    await widget.onPlaceTap(context, category.apiType);
                  },
                );
              },
            ),
    );
  }
}