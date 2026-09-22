import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../theme/theme.dart';
import '../screens/lutalia_page.dart';
import 'add_food_options_screen.dart';
import 'add_food_manual_screen.dart';
import 'barcode_scanner_screen.dart';

class MealBaseScreen extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> foods;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  const MealBaseScreen({
    super.key,
    required this.title,
    required this.foods,
    required this.onChanged,
  });

  @override
  State<MealBaseScreen> createState() => _MealBaseScreenState();
}

class _MealBaseScreenState extends State<MealBaseScreen> {
  List<Map<String, dynamic>> get foods => widget.foods;

  void _notifyParent() {
    widget.onChanged(List<Map<String, dynamic>>.from(foods));
  }

  @override
  Widget build(BuildContext context) {
    final totalKcal =
        foods.fold<double>(0, (sum, f) => sum + (f["kcal"] ?? 0));
    final totalGrams =
        foods.fold<double>(0, (sum, f) => sum + (f["grams"] ?? 0));

    final totalCarbs =
        foods.fold<double>(0, (sum, f) => sum + (f["carbs"] ?? 0));
    final totalFat =
        foods.fold<double>(0, (sum, f) => sum + (f["fat"] ?? 0));
    final totalProtein =
        foods.fold<double>(0, (sum, f) => sum + (f["protein"] ?? 0));
    final totalSugar =
        foods.fold<double>(0, (sum, f) => sum + (f["sugar"] ?? 0));

    final allZero = totalCarbs == 0 &&
        totalFat == 0 &&
        totalProtein == 0 &&
        totalSugar == 0;

    final chartCarbs = allZero ? 1.0 : totalCarbs.toDouble();
    final chartFat = allZero ? 1.0 : totalFat.toDouble();
    final chartProtein = allZero ? 1.0 : totalProtein.toDouble();
    final chartSugar = allZero ? 1.0 : totalSugar.toDouble();

    return LutaliaPage(
      title: widget.title,
      showBack: true,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // ⭐ Add Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.qr_code_scanner,
                    size: 30,
                    color: LutaliaTheme.latte,
                  ),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BarcodeScannerScreen(),
                      ),
                    );

                    if (result != null) {
                      setState(() {
                        foods.add({
                          "name": result["name"] ?? "",
                          "kcal": result["kcal"] ?? 0,
                          "carbs": result["carbs"] ?? 0,
                          "fat": result["fat"] ?? 0,
                          "protein": result["protein"] ?? 0,
                          "sugar": result["sugar"] ?? 0,
                          "grams": 100,
                          "image": result["image"] ?? "",
                        });
                      });
                      _notifyParent();
                    }
                  },
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: Icon(
                    Icons.add,
                    size: 32,
                    color: LutaliaTheme.latte,
                  ),
                  onPressed: () async {
                    final result = await showDialog(
                      context: context,
                      builder: (_) => const AddFoodOptionsScreen(),
                    );

                    if (result != null) {
                      setState(() {
                        foods.add({
                          "name": result["name"] ?? "",
                          "kcal": result["kcal"] ?? 0,
                          "carbs": result["carbs"] ?? 0,
                          "fat": result["fat"] ?? 0,
                          "protein": result["protein"] ?? 0,
                          "sugar": result["sugar"] ?? 0,
                          "grams": result["grams"] ?? 100,
                          "image": result["image"] ?? "",
                        });
                      });
                      _notifyParent();
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ⭐ Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "${totalKcal.toStringAsFixed(0)} kcal",
                    style: const TextStyle(
                      fontFamily: "Cinzel",
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${totalCarbs.toStringAsFixed(0)} g KH   •   "
                    "${totalFat.toStringAsFixed(0)} g Fett   •   "
                    "${totalProtein.toStringAsFixed(0)} g Eiweiß   •   "
                    "${totalSugar.toStringAsFixed(0)} g Zucker",
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: "Cinzel",
                      color: Colors.black.withValues(alpha: 0.75),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${foods.length} Lebensmittel • ${totalGrams.toStringAsFixed(0)} g",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ⭐ PieChart
            SizedBox(
              height: 240,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 38,
                        sections: [
                          PieChartSectionData(
                            value: chartCarbs,
                            color: const Color(0xFFF3C9D8),
                            radius: 60,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: chartFat,
                            color: const Color(0xFFE8AFC4),
                            radius: 60,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: chartProtein,
                            color: const Color(0xFFD9A2B8),
                            radius: 60,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: chartSugar,
                            color: const Color(0xFFC98FA8),
                            radius: 60,
                            showTitle: false,
                          ),
                        ],
                      ),
                    ),

                    Positioned(
                      top: 10,
                      right: 0,
                      child: _macroLabel(
                        "${totalCarbs.toStringAsFixed(0)} g KH",
                        const Color(0xFFF3C9D8),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 0,
                      child: _macroLabel(
                        "${totalProtein.toStringAsFixed(0)} g Eiweiß",
                        const Color(0xFFD9A2B8),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      right: 0,
                      child: _macroLabel(
                        "${totalFat.toStringAsFixed(0)} g Fett",
                        const Color(0xFFE8AFC4),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 0,
                      child: _macroLabel(
                        "${totalSugar.toStringAsFixed(0)} g Zucker",
                        const Color(0xFFC98FA8),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ⭐ Food List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: foods.length,
              itemBuilder: (context, index) {
                final item = foods[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _buildImage(item["image"]),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item["name"] ?? "",
                              style: const TextStyle(
                                fontFamily: "Cinzel",
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "${(item["kcal"] ?? 0).toStringAsFixed(0)} kcal • ${(item["grams"] ?? 0).toStringAsFixed(0)} g",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, color: LutaliaTheme.latte),
                        onPressed: () async {
                          final edited = await showDialog(
                            context: context,
                            builder: (_) =>
                                AddFoodManualScreen(initial: item),
                          );

                          if (edited != null) {
                            setState(() {
                              foods[index] = edited;
                            });
                            _notifyParent();
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFFE8AFC4),
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Wirklich löschen?"),
                              content: Text(
                                "Möchtest du „${item["name"]}“ wirklich entfernen?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text("Abbrechen"),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text(
                                    "Löschen",
                                    style: TextStyle(
                                      color: Color(0xFFE8AFC4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            setState(() {
                              foods.removeAt(index);
                            });
                            _notifyParent();
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroLabel(String text, Color color) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontFamily: "Cinzel",
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 26,
          height: 1.4,
          color: color,
        ),
      ],
    );
  }

  Widget _buildImage(String? path) {
    if (path == null || path.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        color: Colors.grey.shade200,
        child: const Icon(Icons.fastfood),
      );
    }

    // Asset-Bild (z.B. aus foods.json: assets/images/obst/...)
    if (path.startsWith("assets/")) {
      return Image.asset(
        path,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 56,
            height: 56,
            color: Colors.grey.shade200,
            child: const Icon(Icons.fastfood),
          );
        },
      );
    }

    // Netzwerkbild
    if (path.startsWith("http")) {
      return Image.network(
        path,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 56,
            height: 56,
            color: Colors.grey.shade200,
            child: const Icon(Icons.fastfood),
          );
        },
      );
    }

    // Lokale Datei (falls du später mal Pfade speicherst)
    return Image.file(
      File(path),
      width: 56,
      height: 56,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 56,
          height: 56,
          color: Colors.grey.shade200,
          child: const Icon(Icons.fastfood),
        );
      },
    );
  }
}
