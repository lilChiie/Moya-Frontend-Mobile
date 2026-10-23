import 'package:flutter/material.dart';

IconData categoryIcon(String name) {
  final title = name.toLowerCase();
  if (['nature', 'gunung', 'pantai'].any(title.contains)) return Icons.park;
  if (['culture', 'history'].any(title.contains)) return Icons.theater_comedy;
  if (['shop', 'mall'].any(title.contains)) return Icons.shopping_bag;
  if (['food', 'culinary', 'restaurant'].any(title.contains)) {
    return Icons.restaurant;
  }
  if (['hotel', 'villa', 'resort'].any(title.contains)) return Icons.hotel;
  if (['religion', 'mosque'].any(title.contains)) return Icons.mosque;
  return Icons.attractions;
}
