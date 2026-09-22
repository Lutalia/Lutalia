import 'package:flutter/material.dart';

class DetailScreen extends StatelessWidget {
  final int carbs;
  final int sugar;
  final int fiber;
  final int starch;

  final int fat;
  final int saturatedFat;
  final int unsaturatedFat;

  final int protein;
  final int salt;

  const DetailScreen({
    super.key,
    required this.carbs,
    required this.sugar,
    required this.fiber,
    required this.starch,
    required this.fat,
    required this.saturatedFat,
    required this.unsaturatedFat,
    required this.protein,
    required this.salt,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Nährwertdetails",
          style: TextStyle(
            fontFamily: "Cinzel",
            fontSize: 22,
            color: Color(0xFF8C6F5A),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _buildCategory(
              "Kohlenhydrate",
              {
                "Zucker": "$sugar g",
                "Stärke": "$starch g",
                "Ballaststoffe": "$fiber g",
                "Gesamt": "$carbs g",
              },
            ),

            const SizedBox(height: 20),

            _buildCategory(
              "Fett",
              {
                "Gesättigt": "$saturatedFat g",
                "Ungesättigt": "$unsaturatedFat g",
                "Gesamt": "$fat g",
              },
            ),

            const SizedBox(height: 20),

            _buildCategory(
              "Eiweiß",
              {
                "Gesamt": "$protein g",
              },
            ),

            const SizedBox(height: 20),

            _buildCategory(
              "Salz",
              {
                "Gesamt": "$salt g",
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Kategorie-Karte
  Widget _buildCategory(String title, Map<String, String> values) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EDE6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: "NewFirst",
              fontSize: 20,
              color: Color(0xFF8C6F5A),
            ),
          ),
          const SizedBox(height: 10),

          ...values.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key,
                        style: const TextStyle(
                            fontFamily: "Cinzel", fontSize: 15)),
                    Text(entry.value,
                        style: const TextStyle(
                            fontFamily: "Cinzel", fontSize: 15)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
