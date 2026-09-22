import 'package:flutter/material.dart';

class MealScreen extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final Function(int index) onDelete;

  const MealScreen({
    super.key,
    required this.title,
    required this.items,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = const Color(0xFFF7F2EC);
    final Color accent = const Color(0xFF8C6F5A);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: accent),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: "NewFirst",
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(22),
        child: items.isEmpty
            ? const Center(
                child: Text(
                  "Noch nichts hinzugefügt",
                  style: TextStyle(
                    fontFamily: "Cinzel",
                    fontSize: 20,
                    color: Colors.black54,
                  ),
                ),
              )
            : Column(
                children: [
                  // ⭐ Gesamtkalorien
                  _buildSummary(),

                  const SizedBox(height: 30),

                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final item = items[i];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "${item["name"]} – ${item["grams"]} g · ${item["kcal"]} kcal",
                                  style: const TextStyle(
                                    fontFamily: "Cinzel",
                                    fontSize: 18,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () => onDelete(i),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSummary() {
    num kcal = 0;
    num carbs = 0;
    num fat = 0;
    num protein = 0;

    for (var item in items) {
      kcal += item["kcal"];
      carbs += item["carbs"];
      fat += item["fat"];
      protein += item["protein"];
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "${kcal.round()} kcal gesamt",
            style: const TextStyle(
              fontFamily: "NewFirst",
              fontSize: 26,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "KH: ${carbs.toStringAsFixed(1)} g   ·   Fett: ${fat.toStringAsFixed(1)} g   ·   Protein: ${protein.toStringAsFixed(1)} g",
            style: const TextStyle(
              fontFamily: "Cinzel",
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
