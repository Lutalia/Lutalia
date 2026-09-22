import 'package:flutter/material.dart';

Future<void> addFoodFlow({
  required BuildContext context,
  required Map<String, dynamic> food,
  required Function(String meal, int grams) onAdd,
}) async {
  final grams = await _askAmount(context, food);
  if (grams == null) return;

  final meal = await _askMeal(context);
  if (meal == null) return;

  onAdd(meal, grams);
}

Future<int?> _askAmount(BuildContext context, Map<String, dynamic> food) async {
  final gramsController = TextEditingController();
  final portionController = TextEditingController();

  return showDialog<int>(
    context: context,
    builder: (_) {
      return Dialog(
        backgroundColor: const Color(0xFFF5EDE3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Wie viel möchtest du hinzufügen?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: "NewFirst",
                  fontSize: 26,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 26),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: gramsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Gramm",
                        labelStyle: TextStyle(fontFamily: "Cinzel", fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: TextField(
                      controller: portionController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Portionen",
                        labelStyle: TextStyle(fontFamily: "Cinzel", fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: () {
                  final grams = int.tryParse(gramsController.text);
                  final portions = int.tryParse(portionController.text);

                  int? finalGrams;

                  if (portions != null && portions > 0) {
                    // ⭐ Portionen → Gramm umrechnen
                    final portionen = List<Map<String, dynamic>>.from(food["portionen"]);
                    final firstPortion = portionen.first;
                    final portionGramm = int.parse(firstPortion["gramm"].toString());
                    finalGrams = portionGramm * portions;
                  } else if (grams != null && grams > 0) {
                    finalGrams = grams;
                  }

                  Navigator.pop(context, finalGrams);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8C6F5A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  "Weiter",
                  style: TextStyle(fontFamily: "Cinzel", fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<String?> _askMeal(BuildContext context) async {
  return showDialog<String>(
    context: context,
    builder: (_) {
      return Dialog(
        backgroundColor: const Color(0xFFF5EDE3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Hinzufügen zu…",
                style: TextStyle(
                  fontFamily: "NewFirst",
                  fontSize: 28,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 26),

              _mealButton(context, "Frühstück"),
              _mealButton(context, "Mittagessen"),
              _mealButton(context, "Abendessen"),
              _mealButton(context, "Snacks"),
            ],
          ),
        ),
      );
    },
  );
}

Widget _mealButton(BuildContext context, String meal) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: ElevatedButton(
      onPressed: () => Navigator.pop(context, meal),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8C6F5A),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Text(
        meal,
        style: const TextStyle(
          fontFamily: "Cinzel",
          fontSize: 20,
        ),
      ),
    ),
  );
}
