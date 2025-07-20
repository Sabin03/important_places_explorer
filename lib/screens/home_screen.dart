import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/place_category.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<PlaceCategory> categories = [
    const PlaceCategory(name: "Health", icon: FontAwesomeIcons.hospital, apiType: "hospital"),
    const PlaceCategory(name: "Pharmacy", icon: FontAwesomeIcons.pills, apiType: "pharmacy"),
    const PlaceCategory(name: "Emergency Room", icon: FontAwesomeIcons.hospitalUser, apiType: "hospital_emergency"),
    const PlaceCategory(name: "Police Station", icon: FontAwesomeIcons.shieldAlt, apiType: "police"),
    const PlaceCategory(name: "Fire Station", icon: FontAwesomeIcons.fireExtinguisher, apiType: "fire_station"),
    const PlaceCategory(name: "Government Office", icon: FontAwesomeIcons.landmark, apiType: "government_office"),
    const PlaceCategory(name: "Courthouse", icon: FontAwesomeIcons.gavel, apiType: "courthouse"),
    const PlaceCategory(name: "Embassy", icon: FontAwesomeIcons.flag, apiType: "embassy"),
    const PlaceCategory(name: "Church", icon: FontAwesomeIcons.church, apiType: "church"),
    const PlaceCategory(name: "Temple", icon: FontAwesomeIcons.placeOfWorship, apiType: "hindu_temple"),
    const PlaceCategory(name: "Mosque", icon: FontAwesomeIcons.mosque, apiType: "mosque"),
    const PlaceCategory(name: "Shrine", icon: FontAwesomeIcons.pray, apiType: "shrine"),
    const PlaceCategory(name: "Synagogue", icon: FontAwesomeIcons.starOfDavid, apiType: "synagogue"),
    const PlaceCategory(name: "Food & Drink", icon: FontAwesomeIcons.utensils, apiType: "restaurant"),
    const PlaceCategory(name: "Fast Food", icon: FontAwesomeIcons.hamburger, apiType: "fast_food"),
    const PlaceCategory(name: "Cafe", icon: FontAwesomeIcons.coffee, apiType: "cafe"),
    const PlaceCategory(name: "Bar", icon: FontAwesomeIcons.beer, apiType: "bar"),
    const PlaceCategory(name: "Shopping", icon: FontAwesomeIcons.shoppingCart, apiType: "supermarket"),
    const PlaceCategory(name: "Pet Store", icon: FontAwesomeIcons.dog, apiType: "pet_store"),
    const PlaceCategory(name: "Gas Station", icon: FontAwesomeIcons.gasPump, apiType: "gas_station"),
    const PlaceCategory(name: "ATM", icon: FontAwesomeIcons.moneyBillWave, apiType: "atm"),
    const PlaceCategory(name: "Lodging", icon: FontAwesomeIcons.hotel, apiType: "lodging"),
    const PlaceCategory(name: "Finance", icon: FontAwesomeIcons.moneyCheckAlt, apiType: "bank"),
    const PlaceCategory(name: "Services", icon: FontAwesomeIcons.toolbox, apiType: "post_office"),
    const PlaceCategory(name: "Transit", icon: FontAwesomeIcons.train, apiType: "train_station"),
    const PlaceCategory(name: "Attractions", icon: FontAwesomeIcons.camera, apiType: "tourist_attraction"),
    const PlaceCategory(name: "Gym", icon: FontAwesomeIcons.dumbbell, apiType: "gym"),
    const PlaceCategory(name: "School", icon: FontAwesomeIcons.school, apiType: "school"),
    const PlaceCategory(name: "University", icon: FontAwesomeIcons.graduationCap, apiType: "university"),
  ];

  bool _isLoadingLocation = false;

  Future<void> _openGoogleMaps(BuildContext context, String type) async {
    if (!mounted) return;
    setState(() => _isLoadingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permission denied.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('Location permission permanently denied.');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final lat = position.latitude;
      final lng = position.longitude;

      final googleMapsAppUrl = Platform.isIOS
          ? 'comgooglemaps://?q=${Uri.encodeComponent(type)}&center=$lat,$lng'
          : 'geo:$lat,$lng?q=${Uri.encodeComponent(type)}';

      if (await canLaunchUrl(Uri.parse(googleMapsAppUrl))) {
        await launchUrl(Uri.parse(googleMapsAppUrl), mode: LaunchMode.externalApplication);
        return;
      }

      final webUrl = 'https://www.google.com/maps/search/${Uri.encodeComponent(type)}/@$lat,$lng,15z';
      if (await canLaunchUrl(Uri.parse(webUrl))) {
        await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not open Google Maps.');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _navigateToSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          allCategories: categories,
          onPlaceTap: _openGoogleMaps,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text(
          "Nearby Explorer",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 4,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _navigateToSearch,
            tooltip: 'Search',
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  "Discover essential places around you!",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _buildCategoryCard(context, category);
                  },
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
          if (_isLoadingLocation)
            Container(
              color: Colors.black.withOpacity(0.3),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.grey.shade200,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Finding your location...",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, PlaceCategory category) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _openGoogleMaps(context, category.apiType),
      borderRadius: BorderRadius.circular(25),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        shadowColor: Colors.black.withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(0.1),
                ),
                child: Icon(category.icon, size: 36, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  category.name,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}