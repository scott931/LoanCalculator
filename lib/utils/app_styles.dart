import 'package:flutter/material.dart';

class AppStyles {
  // Border radius constants
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;

  // Common border radius
  static BorderRadius borderRadiusSmallRadius =
      BorderRadius.circular(borderRadiusSmall);
  static BorderRadius borderRadiusMediumRadius =
      BorderRadius.circular(borderRadiusMedium);
  static BorderRadius borderRadiusLargeRadius =
      BorderRadius.circular(borderRadiusLarge);

  // Common box shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.grey.withOpacity(0.1),
      spreadRadius: 1,
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  // Common text styles
  static TextStyle labelStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.grey,
  );

  static TextStyle titleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.grey[800],
  );

  static TextStyle subtitleStyle = TextStyle(
    fontSize: 14,
    color: Colors.grey[600],
  );

  // Common colors
  static Color primaryColor = Colors.blue[600]!;
  static Color backgroundColor = Colors.grey[50]!;
  static Color cardColor = Colors.white;
}
