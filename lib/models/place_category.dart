import 'package:flutter/material.dart';

class PlaceCategory {
  final String name;
  final IconData icon;
  final String apiType;

  const PlaceCategory({
    required this.name,
    required this.icon,
    required this.apiType,
  });
}