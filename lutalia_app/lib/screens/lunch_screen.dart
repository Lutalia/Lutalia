import 'package:flutter/material.dart';
import 'meal_base_screen.dart';

class LunchScreen extends StatelessWidget {
  final List<Map<String, dynamic>> foods;

  /// WICHTIG:
  /// FoodTrackingScreen gibt hier eine Funktion rein,
  /// die die aktualisierte Liste zurückbekommt.
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  const LunchScreen({
    super.key,
    required this.foods,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return MealBaseScreen(
      title: "Mittagessen",
      foods: foods,
      onChanged: onChanged,
    );
  }
}
