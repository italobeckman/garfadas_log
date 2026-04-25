import 'package:flutter/material.dart';

class AppLayout {
  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 15.0;
  static const double radiusLarge = 24.0;
  
  static BorderRadius borderSmall = BorderRadius.circular(radiusSmall);
  static BorderRadius borderMedium = BorderRadius.circular(radiusMedium);
  static BorderRadius borderLarge = BorderRadius.circular(radiusLarge);
  
  // Spacing (EdgeInsets)
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 16.0;
  static const double spaceL = 24.0;
  static const double spaceXL = 32.0;
  
  static const EdgeInsets paddingS = EdgeInsets.all(spaceS);
  static const EdgeInsets paddingM = EdgeInsets.all(spaceM);
  static const EdgeInsets paddingL = EdgeInsets.all(spaceL);
  
  // Cards
  static const double cardElevation = 3.0;
}
