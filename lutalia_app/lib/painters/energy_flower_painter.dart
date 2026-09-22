import 'dart:math';
import 'package:flutter/material.dart';
import '../models/energy_petal.dart';

class EnergyFlowerPainter extends CustomPainter {
  final int carbs, fat, protein, sugar;
  final int carbsGoal, fatGoal, proteinGoal, sugarGoal;
  final double progress;

  EnergyFlowerPainter({
    required this.carbs,
    required this.fat,
    required this.protein,
    required this.sugar,
    required this.carbsGoal,
    required this.fatGoal,
    required this.proteinGoal,
    required this.sugarGoal,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.35;

    // Kategorien & Farben
    final categories = [
      _generatePetals(carbs, carbsGoal, Colors.amber.shade300),
      _generatePetals(fat, fatGoal, Colors.pink.shade200),
      _generatePetals(protein, proteinGoal, Colors.green.shade300),
      _generatePetals(sugar, sugarGoal, Colors.blue.shade200),
    ];

    // Alle Blätter zeichnen
    for (var petalList in categories) {
      for (var petal in petalList) {
        _drawPetal(canvas, center, radius, petal);
      }
    }

    // Kern der Blume
    final corePaint = Paint()
      ..color = const Color(0xFFF7F2EC)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawCircle(center, radius * 0.55, corePaint);
  }

  // Federblätter generieren
  List<EnergyPetal> _generatePetals(int value, int goal, Color color) {
    final List<EnergyPetal> petals = [];

    int count = max(1, (value / 10).round()); // 1 Blatt pro 10g
    double intensity = (value / goal).clamp(0.5, 1.4);

    for (int i = 0; i < count; i++) {
      petals.add(
        EnergyPetal(
          angle: (i / count) * 2 * pi,
          length: 40 * intensity * progress,
          width: 14 * intensity,
          color: color,
          opacity: 0.35 + (0.4 * progress),
        ),
      );
    }

    return petals;
  }

  // Federblatt zeichnen
  void _drawPetal(Canvas canvas, Offset center, double radius, EnergyPetal petal) {
    final angle = petal.angle;
    final dx = center.dx + radius * cos(angle);
    final dy = center.dy + radius * sin(angle);

    final path = Path();
    path.moveTo(dx, dy);

    // Federform (zwei Bézierkurven)
    path.quadraticBezierTo(
      dx + petal.width * cos(angle + 0.3),
      dy + petal.width * sin(angle + 0.3),
      dx + petal.length * cos(angle),
      dy + petal.length * sin(angle),
    );

    path.quadraticBezierTo(
      dx + petal.width * cos(angle - 0.3),
      dy + petal.width * sin(angle - 0.3),
      dx,
      dy,
    );

    final paint = Paint()
      ..color = petal.color.withOpacity(petal.opacity)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
