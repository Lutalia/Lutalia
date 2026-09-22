import 'package:flutter/material.dart';
import 'meal_base_screen.dart';

class SnacksScreen extends StatelessWidget {
  final List<Map<String, dynamic>> foods;

  /// WICHTIG:
  /// FoodTrackingScreen gibt hier eine Funktion rein,
  /// die die aktualisierte Liste zurückbekommt.
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  const SnacksScreen({
    super.key,
    required this.foods,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return MealBaseScreen(
      title: "Snacks",
      foods: foods,
      onChanged: onChanged,
    );
  }
}
