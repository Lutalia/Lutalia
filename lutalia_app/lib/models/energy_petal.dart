import 'package:flutter/material.dart';

class EnergyPetal {
  final double angle;   // Position im Kreis
  final double length;  // Länge des Blattes
  final double width;   // Breite des Blattes
  final Color color;    // Farbe des Blattes
  final double opacity; // Transparenz

  EnergyPetal({
    required this.angle,
    required this.length,
    required this.width,
    required this.color,
    required this.opacity,
  });
}
