import 'package:flutter/material.dart';
import '../widgets/macro_ring_circle.dart';
import '../utils/add_food_flow.dart'; // ⭐ wichtig

class FoodDetailScreen extends StatelessWidget {
  final Map<String, dynamic> food;

  const FoodDetailScreen({super.key, required this.food});

  // ⭐ Flow starten → Ergebnis zurückgeben
  Future<void> _startAddFlow(BuildContext context) async {
    await addFoodFlow(
      context: context,
      food: food,
      onAdd: (meal, grams) {
        // ⭐ Ergebnis zurück an FoodTrackingScreen
        Navigator.pop(context, {
          "meal": meal,
          "grams": grams,
          "food": food,
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = const Color(0xFF8C6F5A);
    final Color bg = const Color(0xFFF7F2EC);
    final Color latte = const Color(0xFFF5EDE3);

    final portion = food["portionen"][0];
    final portionGramm = portion["gramm"];
    final portionKcal = ((food["kcal"] / 100) * portionGramm).round();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: accent),
        centerTitle: true,
        title: const SizedBox(),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [

            // ⭐ Titel
            Text(
              food["name"],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: "NewFirst",
                fontSize: 32,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 20),

            // ⭐ Kreis → Hinzufügen
            GestureDetector(
              onTap: () => _startAddFlow(context),
              child: MacroRingCircle(
                carbs: food["carbs"],
                fat: food["fat"],
                protein: food["protein"],
                sugar: food["sugar"],
                centerText: "$portionKcal kcal\npro Portion",
                size: 260,
              ),
            ),

            const SizedBox(height: 30),

            // ⭐ Bild
            ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Image.asset(
                food["bild"],
                width: double.infinity,
                height: 260,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 40),

            // ⭐ Makros
            const Text(
              "Makronährstoffe",
              style: TextStyle(
                fontFamily: "NewFirst",
                fontSize: 32,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            _macroCard("Kohlenhydrate", food["carbs"]),
            const SizedBox(height: 14),
            _macroCard("Fett", food["fat"]),
            const SizedBox(height: 14),
            _macroCard("Protein", food["protein"]),
            const SizedBox(height: 14),
            _macroCard("Zucker", food["sugar"]),

            const SizedBox(height: 40),

            // ⭐ Mikros
            const Text(
              "Mikronährstoffe",
              style: TextStyle(
                fontFamily: "NewFirst",
                fontSize: 32,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            ...food["micros"].entries.map((m) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  "${m.key}: ${m.value}",
                  style: const TextStyle(
                    fontFamily: "Cinzel",
                    fontSize: 20,
                    color: Colors.black87,
                  ),
                ),
              );
            }),

            const SizedBox(height: 40),

            // ⭐ Portionen
            const Text(
              "Portionen",
              style: TextStyle(
                fontFamily: "NewFirst",
                fontSize: 32,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ...food["portionen"].map<Widget>((p) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: latte,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      "${p["name"]}: ${p["gramm"]} g",
                      style: const TextStyle(
                        fontFamily: "Cinzel",
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                  );
                }),
              ],
            ),

            const SizedBox(height: 50),

            // ⭐ Button → Hinzufügen
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _startAddFlow(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  "Hinzufügen",
                  style: TextStyle(
                    fontFamily: "Cinzel",
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ⭐ Makro-Karte
  Widget _macroCard(String label, num value) {
    Color bgColor;

    if (label == "Kohlenhydrate") {
      bgColor = const Color(0xFFD9A679);
    } else if (label == "Fett") {
      bgColor = const Color(0xFFE8A8A1);
    } else if (label == "Protein") {
      bgColor = const Color(0xFFA8C9A1);
    } else if (label == "Zucker") {
      bgColor = const Color(0xFFE8C6A1);
    } else {
      bgColor = const Color(0xFFF5EDE3);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.35),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: "Cinzel",
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
          Text(
            "${value is int ? value : value.toStringAsFixed(1)} g",
            style: const TextStyle(
              fontFamily: "Cinzel",
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
