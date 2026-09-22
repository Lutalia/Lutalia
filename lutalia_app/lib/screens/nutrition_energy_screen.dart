import 'package:flutter/material.dart';
import '../widgets/lutalia_macro_flower.dart';
import 'food_tracking_screen.dart';

class NutritionEnergyScreen extends StatelessWidget {
  const NutritionEnergyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Ernährung & Energie",
          style: TextStyle(
            fontFamily: "NewFirst",
            fontSize: 22,
            color: Color(0xFF8C6F5A),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            _buildSearchBar(),
            const SizedBox(height: 20),

            _buildHealthCard(),
            const SizedBox(height: 30),

            // 🌸 LUTALIA MAKRO-BLUME
            Center(
              child: LutaliaMacroFlower(
                carbs: 180,
                fat: 60,
                protein: 90,
                sugar: 40,
                carbsGoal: 200,
                fatGoal: 50,
                proteinGoal: 100,
                sugarGoal: 50,
                size: 260,
              ),
            ),

            const SizedBox(height: 30),

            _buildTrackingButton(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, color: Color(0xFF8C6F5A)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              style: const TextStyle(fontFamily: "Cinzel"),
              decoration: const InputDecoration(
                hintText: "Lebensmittel suchen…",
                hintStyle: TextStyle(fontFamily: "Cinzel"),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF8C6F5A)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EDE6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _healthRow("Gewicht", "62 kg"),
          _healthRow("Größe", "168 cm"),
          _healthRow("Ziel", "Leichtes Defizit"),
          const SizedBox(height: 10),
          const Text(
            "Bearbeiten",
            style: TextStyle(
              fontFamily: "Cinzel",
              fontSize: 14,
              color: Color(0xFF8C6F5A),
            ),
          )
        ],
      ),
    );
  }

  Widget _healthRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontFamily: "NewFirst", fontSize: 14)),
          Text(value,
              style: const TextStyle(fontFamily: "Cinzel", fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTrackingButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FoodTrackingScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFF7F2EC),
              Color(0xFFF3D7D2),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFF3D7D2).withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Text(
          "Food Tracking",
          style: TextStyle(
            fontFamily: "Cinzel",
            fontSize: 18,
            color: Color(0xFF8C6F5A),
          ),
        ),
      ),
    );
  }
}
