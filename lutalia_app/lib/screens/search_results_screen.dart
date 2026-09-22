import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/product_storage.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;

  const SearchResultsScreen({super.key, required this.query});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  List<Map<String, dynamic>> results = [];
  Map<String, dynamic> foods = {};
  List<Map<String, dynamic>> products = [];

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadAllData();
  }

  Future<void> loadAllData() async {
    final jsonString = await rootBundle.loadString("assets/data/foods.json");
    foods = json.decode(jsonString);

    products = await ProductStorage.loadProducts();

    final List<Map<String, dynamic>> combined = [];

    // foods.json
    foods.forEach((key, value) {
      combined.add({
        "id": key,
        "source": "foods",
        "name": value["name"],
        "kcal": value["kcal"],
        "carbs": value["carbs"],
        "fat": value["fat"],
        "protein": value["protein"],
        "sugar": value["sugar"],
        "bild": value["bild"],
      });
    });

    // products.json
    for (var p in products) {
      combined.add({
        "id": p["id"],
        "source": "products",
        "name": p["name"],
        "kcal": p["kcal"],
        "carbs": p["carbs"],
        "fat": p["fat"],
        "protein": p["protein"],
        "sugar": p["sugar"],
        "image": p["image"] ?? "",
      });
    }

    final q = widget.query.toLowerCase();
    results = combined
        .where((item) => item["name"].toString().toLowerCase().contains(q))
        .toList();

    results.sort((a, b) => a["name"].compareTo(b["name"]));

    searchController.text = widget.query;

    setState(() {});
  }

  void _filterResults(String text) {
    final q = text.toLowerCase();

    final List<Map<String, dynamic>> combined = [];

    foods.forEach((key, value) {
      combined.add({
        "id": key,
        "source": "foods",
        "name": value["name"],
        "kcal": value["kcal"],
        "carbs": value["carbs"],
        "fat": value["fat"],
        "protein": value["protein"],
        "sugar": value["sugar"],
        "bild": value["bild"],
      });
    });

    for (var p in products) {
      combined.add({
        "id": p["id"],
        "source": "products",
        "name": p["name"],
        "kcal": p["kcal"],
        "carbs": p["carbs"],
        "fat": p["fat"],
        "protein": p["protein"],
        "sugar": p["sugar"],
        "image": p["image"] ?? "",
      });
    }

    setState(() {
      results = combined
          .where((item) =>
              item["name"].toString().toLowerCase().contains(q))
          .toList();

      results.sort((a, b) => a["name"].compareTo(b["name"]));
    });
  }

  Future<void> _selectFood(Map<String, dynamic> item) async {
    final gramsController = TextEditingController(text: "100");

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            item["name"],
            style: const TextStyle(fontFamily: "Cinzel"),
          ),
          content: TextField(
            controller: gramsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Gramm"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text(
                "Abbrechen",
                style: TextStyle(
                  color: Color(0xFF8C6F5A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final grams = double.tryParse(gramsController.text) ?? 100;

                // Basisdaten holen
                Map<String, dynamic> base;
                if (item["source"] == "foods") {
                  base = Map<String, dynamic>.from(foods[item["id"]] ?? {});
                } else {
                  base = Map<String, dynamic>.from(item);
                }

                final factor = grams / 100.0;

                // ⭐ FLACHES Lebensmittel-Objekt zurückgeben (MealBaseScreen-kompatibel)
                final food = {
                  "name": base["name"],
                  "grams": grams,
                  "kcal": (base["kcal"] ?? 0) * factor,
                  "carbs": (base["carbs"] ?? 0) * factor,
                  "fat": (base["fat"] ?? 0) * factor,
                  "protein": (base["protein"] ?? 0) * factor,
                  "sugar": (base["sugar"] ?? 0) * factor,
                  "image": base["bild"] ?? base["image"] ?? "",
                };

                Navigator.of(dialogContext).pop(food);
              },
              child: const Text(
                "Hinzufügen",
                style: TextStyle(
                  color: Color(0xFFF3C9D8),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result != null) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.4,
        title: TextField(
          controller: searchController,
          onChanged: _filterResults,
          decoration: const InputDecoration(
            hintText: "Lebensmittel suchen…",
            prefixIcon: Icon(Icons.search, color: Color(0xFF8C6F5A)),
            border: InputBorder.none,
          ),
        ),
      ),
      body: results.isEmpty
          ? const Center(
              child: Text(
                "Keine Ergebnisse gefunden",
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final item = results[index];

                final bool isFromFoods = item["source"] == "foods";
                Widget imageWidget;

                if (isFromFoods) {
                  final id = item["id"];
                  final food = foods[id] ?? {};
                  final bildPath = food["bild"]?.toString() ?? "";

                  if (bildPath.isNotEmpty) {
                    imageWidget = Image.asset(
                      bildPath,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    );
                  } else {
                    imageWidget = Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.fastfood, size: 30),
                    );
                  }
                } else {
                  final imageUrl = item["image"]?.toString() ?? "";
                  if (imageUrl.isNotEmpty) {
                    imageWidget = Image.network(
                      imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    );
                  } else {
                    imageWidget = Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.fastfood, size: 30),
                    );
                  }
                }

                return GestureDetector(
                  onTap: () => _selectFood(item),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: imageWidget,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item["name"],
                                style: const TextStyle(
                                  fontFamily: "Cinzel",
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "${item["kcal"]} kcal • KH ${item["carbs"]}g • F ${item["fat"]}g • E ${item["protein"]}g",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
