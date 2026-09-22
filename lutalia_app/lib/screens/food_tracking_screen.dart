import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/lutalia_page.dart';
import 'barcode_scanner_screen.dart';
import 'search_results_screen.dart';
import 'breakfast_screen.dart';
import 'lunch_screen.dart';
import 'dinner_screen.dart';
import 'snacks_screen.dart';
import 'calendar_screen.dart';

class FoodTrackingScreen extends StatefulWidget {
  const FoodTrackingScreen({super.key});

  @override
  State<FoodTrackingScreen> createState() => _FoodTrackingScreenState();
}

class _FoodTrackingScreenState extends State<FoodTrackingScreen> {
  Map<String, dynamic> foods = {};

  List<Map<String, dynamic>> breakfast = [];
  List<Map<String, dynamic>> lunch = [];
  List<Map<String, dynamic>> dinner = [];
  List<Map<String, dynamic>> snacks = [];

  final TextEditingController searchController = TextEditingController();
  final Color accent = const Color(0xFF8C6F5A);

  late String todayKey;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    todayKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    loadFoods();
    loadSavedMeals();
  }

  // ------------------------------------------------------------
  // 🔥 LEBENSMITTEL-DATENBANK LADEN
  // ------------------------------------------------------------

  Future<void> loadFoods() async {
    final jsonString = await rootBundle.loadString("assets/data/foods.json");
    foods = json.decode(jsonString);
    setState(() {});
  }

  // ------------------------------------------------------------
  // 🔥 FIRESTORE LADEN
  // ------------------------------------------------------------

  Future<void> loadSavedMeals() async {
    final user = _auth.currentUser;

    if (user == null) {
      setState(() {
        breakfast = [];
        lunch = [];
        dinner = [];
        snacks = [];
      });
      return;
    }

    final doc = await _firestore
        .collection("users")
        .doc(user.uid)
        .collection("meals")
        .doc(todayKey)
        .get();

    if (!doc.exists) {
      setState(() {
        breakfast = [];
        lunch = [];
        dinner = [];
        snacks = [];
      });
      return;
    }

    final data = doc.data() ?? {};

    setState(() {
      breakfast = List<Map<String, dynamic>>.from(data["breakfast"] ?? []);
      lunch = List<Map<String, dynamic>>.from(data["lunch"] ?? []);
      dinner = List<Map<String, dynamic>>.from(data["dinner"] ?? []);
      snacks = List<Map<String, dynamic>>.from(data["snacks"] ?? []);
    });
  }

  // ------------------------------------------------------------
  // 🔥 FIRESTORE SPEICHERN
  // ------------------------------------------------------------

  Future<void> saveMeals() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection("users")
        .doc(user.uid)
        .collection("meals")
        .doc(todayKey)
        .set(
      {
        "breakfast": breakfast,
        "lunch": lunch,
        "dinner": dinner,
        "snacks": snacks,
        "updatedAt": DateTime.now(),
      },
      SetOptions(merge: true),
    );
  }

  // ------------------------------------------------------------
  // 🔥 HINZUFÜGEN / LÖSCHEN
  // ------------------------------------------------------------

  void addFoodToMeal(
    List<Map<String, dynamic>> meal,
    Map<String, dynamic> food,
    int grams,
  ) {
    final num kcalPer100 = num.parse(food["kcal"].toString());
    final int totalKcal = ((kcalPer100 / 100.0) * grams).round();

    final entry = {
      ...food,
      "grams": grams,
      "kcal": totalKcal,
    };

    setState(() {
      meal.add(entry);
    });

    saveMeals();
  }

  void removeFood(List<Map<String, dynamic>> meal, int index) {
    setState(() {
      meal.removeAt(index);
    });
    saveMeals();
  }

  // ------------------------------------------------------------
  // 🔥 BERECHNUNGEN
  // ------------------------------------------------------------

  int calculateTotalKcalFromMeals() {
    int total = 0;

    for (var meal in [breakfast, lunch, dinner, snacks]) {
      for (var food in meal) {
        final num kcal = num.parse(food["kcal"].toString());
        total += kcal.round();
      }
    }

    return total;
  }

  Map<String, double> calculateMacros() {
    double carbs = 0;
    double fat = 0;
    double protein = 0;
    double sugar = 0;

    for (var meal in [breakfast, lunch, dinner, snacks]) {
      for (var food in meal) {
        carbs += (food["carbs"] ?? 0).toDouble();
        fat += (food["fat"] ?? 0).toDouble();
        protein += (food["protein"] ?? 0).toDouble();
        sugar += (food["sugar"] ?? 0).toDouble();
      }
    }

    return {
      "KH": carbs,
      "Fett": fat,
      "Eiweiß": protein,
      "Zucker": sugar,
    };
  }

  // ------------------------------------------------------------
  // 🔥 UI
  // ------------------------------------------------------------

  String _formattedDate() {
    final now = DateTime.now();
    final weekdays = [
      "Montag",
      "Dienstag",
      "Mittwoch",
      "Donnerstag",
      "Freitag",
      "Samstag",
      "Sonntag"
    ];
    final months = [
      "Januar",
      "Februar",
      "März",
      "April",
      "Mai",
      "Juni",
      "Juli",
      "August",
      "September",
      "Oktober",
      "November",
      "Dezember"
    ];

    return "${weekdays[now.weekday - 1]}, ${now.day}. ${months[now.month - 1]} ${now.year}";
  }

  @override
  Widget build(BuildContext context) {
    final totalKcal = calculateTotalKcalFromMeals();
    final macros = calculateMacros();
    final screenHeight = MediaQuery.of(context).size.height;

    return LutaliaPage(
      title: "Nährwerte & Energie",
      showBack: true,
      onBackPressed: () => Navigator.pop(context),
      showCalendar: true,
      onCalendarPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CalendarScreen()),
        );
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
        child: Column(
          children: [
            // 🌸 1. BLUME + DATUM
            Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/flowers/blume.png',
                  width: double.infinity,
                  height: screenHeight * 0.40,
                  fit: BoxFit.contain,
                ),
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(seconds: 2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3C9D8).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _formattedDate(),
                      style: TextStyle(
                        fontFamily: "NewFirst",
                        fontSize: screenHeight * 0.030,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 🌸 2. KCAL-RING
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: screenHeight * 0.22,
                    height: screenHeight * 0.22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFF3C9D8),
                        width: 10,
                      ),
                    ),
                  ),
                  Container(
                    width: screenHeight * 0.17,
                    height: screenHeight * 0.17,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "$totalKcal KCAL",
                      style: TextStyle(
                        fontFamily: "Cinzel",
                        fontSize: screenHeight * 0.030,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 52),

            // 🌸 3. CALORIE BARS
            _buildCalorieBars(totalKcal),

            const SizedBox(height: 26),

            // 🌸 4. SUCHFELD
            _buildSearchBox(context),

            const SizedBox(height: 26),

            // 🌸 5. PIE CHART
            _buildPieChart(macros),

            const SizedBox(height: 26),

            // 🌸 6. MEAL ROWS
            _mealRow(
              title: "Frühstück",
              items: breakfast,
              icon: Icons.wb_sunny,
              fontSize: 26,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BreakfastScreen(
                      foods: breakfast,
                      onChanged: (updated) {
                        setState(() => breakfast = updated);
                        saveMeals();
                      },
                    ),
                  ),
                );
              },
            ),

            _mealRow(
              title: "Mittagessen",
              items: lunch,
              icon: Icons.lunch_dining,
              fontSize: 26,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LunchScreen(
                      foods: lunch,
                      onChanged: (updated) {
                        setState(() => lunch = updated);
                        saveMeals();
                      },
                    ),
                  ),
                );
              },
            ),

            _mealRow(
              title: "Abendessen",
              items: dinner,
              icon: Icons.nightlight_round,
              fontSize: 26,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DinnerScreen(
                      foods: dinner,
                      onChanged: (updated) {
                        setState(() => dinner = updated);
                        saveMeals();
                      },
                    ),
                  ),
                );
              },
            ),

            _mealRow(
              title: "Snacks",
              items: snacks,
              icon: Icons.cookie,
              fontSize: 26,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SnacksScreen(
                      foods: snacks,
                      onChanged: (updated) {
                        setState(() => snacks = updated);
                        saveMeals();
                      },
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 🔥 CALORIE BARS
  // ------------------------------------------------------------

  Widget _buildCalorieBars(int totalKcal) {
    int kcal(List<Map<String, dynamic>> meal) {
      int total = 0;
      for (var food in meal) {
        total += num.parse(food["kcal"].toString()).round();
      }
      return total;
    }

    double pct(int kcal) {
      if (totalKcal == 0) return 0;
      return kcal / totalKcal;
    }

    return Column(
      children: [
        _calorieBar("Frühstück", kcal(breakfast), pct(kcal(breakfast)), Icons.wb_sunny),
        const SizedBox(height: 12),
        _calorieBar("Mittagessen", kcal(lunch), pct(kcal(lunch)), Icons.lunch_dining),
        const SizedBox(height: 12),
        _calorieBar("Abendessen", kcal(dinner), pct(kcal(dinner)), Icons.nightlight_round),
        const SizedBox(height: 12),
        _calorieBar("Snacks", kcal(snacks), pct(kcal(snacks)), Icons.cookie),
      ],
    );
  }

  Widget _calorieBar(String title, int kcal, double pct, IconData icon) {
    final percentText = (pct * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: 8),
              Text(
                "$title – $kcal kcal  •  $percentText%",
                style: const TextStyle(
                  fontFamily: "Cinzel",
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 16,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              alignment: Alignment.centerLeft,
              widthFactor: pct.clamp(0, 1),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF3C9D8),
                      Color(0xFFE8AFC4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // 🔥 MEAL ROWS
  // ------------------------------------------------------------

  Widget _mealRow({
    required String title,
    required List<Map<String, dynamic>> items,
    required IconData icon,
    required VoidCallback onTap,
    required double fontSize,
  }) {
    int kcal = 0;
    for (var food in items) {
      kcal += num.parse(food["kcal"].toString()).round();
    }

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: accent, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: "NewFirst",
                      fontSize: fontSize,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Text(
                  "$kcal kcal",
                  style: const TextStyle(
                    fontFamily: "Cinzel",
                    fontSize: 20,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 1.2,
              color: Colors.black.withValues(alpha: 0.08),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 🔥 SEARCH BOX
  // ------------------------------------------------------------

  Widget _buildSearchBox(BuildContext context) {
    final accent = const Color(0xFF8C6F5A);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFF3C9D8),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: accent, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: searchController,
                textInputAction: TextInputAction.search,
                                onSubmitted: (value) async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SearchResultsScreen(query: value),
                    ),
                  );

                  if (result != null && result is Map<String, dynamic>) {
                    final mealName = result["meal"] as String?;
                    final grams = result["grams"] as int?;
                    final food =
                        Map<String, dynamic>.from(result["food"] ?? {});

                    if (mealName != null && grams != null) {
                      if (mealName == "Frühstück") {
                        addFoodToMeal(breakfast, food, grams);
                      } else if (mealName == "Mittagessen") {
                        addFoodToMeal(lunch, food, grams);
                      } else if (mealName == "Abendessen") {
                        addFoodToMeal(dinner, food, grams);
                      } else {
                        addFoodToMeal(snacks, food, grams);
                      }
                    }
                  }
                },
                decoration: const InputDecoration(
                  hintText: "Lebensmittel suchen",
                  hintStyle: TextStyle(
                    fontFamily: "Cinzel",
                    fontSize: 15,
                    color: Colors.black54,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () async {
                final scannedFood = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BarcodeScannerScreen(),
                  ),
                );

                if (scannedFood == null) return;

                _showAddFoodDialog(scannedFood);
              },
              child: Icon(
                Icons.qr_code_scanner,
                color: accent,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 🔥 ADD FOOD DIALOG
  // ------------------------------------------------------------

  void _showAddFoodDialog(Map<String, dynamic> food) {
    final gramsController = TextEditingController(text: "100");
    String selectedMeal = "Frühstück";

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(
            food["name"] ?? "",
            style: const TextStyle(fontFamily: "Cinzel"),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: selectedMeal,
                items: ["Frühstück", "Mittagessen", "Abendessen", "Snacks"]
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(m),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => selectedMeal = v);
                },
              ),
              TextField(
                controller: gramsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Gramm"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Abbrechen"),
            ),
            TextButton(
              onPressed: () {
                final grams = int.tryParse(gramsController.text) ?? 100;

                if (selectedMeal == "Frühstück") {
                  addFoodToMeal(breakfast, food, grams);
                } else if (selectedMeal == "Mittagessen") {
                  addFoodToMeal(lunch, food, grams);
                } else if (selectedMeal == "Abendessen") {
                  addFoodToMeal(dinner, food, grams);
                } else {
                  addFoodToMeal(snacks, food, grams);
                }

                Navigator.pop(context);
              },
              child: const Text("Hinzufügen"),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // 🔥 PIE CHART
  // ------------------------------------------------------------

  Widget _buildPieChart(Map<String, double> macros) {
    return SizedBox(
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: macros.values.every((v) => v == 0)
                  ? [
                      PieChartSectionData(
                        value: 100,
                        color: const Color(0xFFF3C9D8),
                        radius: 70,
                        showTitle: false,
                      ),
                    ]
                  : [
                      PieChartSectionData(
                        value: macros["KH"]!,
                        color: const Color(0xFFF3C9D8),
                        radius: 70,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: macros["Fett"]!,
                        color: const Color(0xFFE8AFC4),
                        radius: 70,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: macros["Eiweiß"]!,
                        color: const Color(0xFFD9A2B8),
                        radius: 70,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: macros["Zucker"]!,
                        color: const Color(0xFFC98FA8),
                        radius: 70,
                        showTitle: false,
                      ),
                    ],
            ),
          ),

          // KH oben rechts
          Positioned(
            top: 20,
            right: 10,
            child: Row(
              children: [
                Text(
                  "${macros["KH"]!.toStringAsFixed(0)} g KH",
                  style: const TextStyle(
                    fontFamily: "Cinzel",
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 30,
                  height: 1.4,
                  color: const Color(0xFFF3C9D8),
                ),
              ],
            ),
          ),

          // Eiweiß oben links
          Positioned(
            top: 20,
            left: 10,
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 1.4,
                  color: const Color(0xFFD9A2B8),
                ),
                const SizedBox(width: 6),
                Text(
                  "${macros["Eiweiß"]!.toStringAsFixed(0)} g Eiweiß",
                  style: const TextStyle(
                    fontFamily: "Cinzel",
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Fett unten rechts
          Positioned(
            bottom: 20,
            right: 10,
            child: Row(
              children: [
                Text(
                  "${macros["Fett"]!.toStringAsFixed(0)} g Fett",
                  style: const TextStyle(
                    fontFamily: "Cinzel",
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 30,
                  height: 1.4,
                  color: const Color(0xFFE8AFC4),
                ),
              ],
            ),
          ),

          // Zucker unten links
          Positioned(
            bottom: 20,
            left: 10,
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 1.4,
                  color: const Color(0xFFC98FA8),
                ),
                const SizedBox(width: 6),
                Text(
                  "${macros["Zucker"]!.toStringAsFixed(0)} g Zucker",
                  style: const TextStyle(
                    fontFamily: "Cinzel",
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
