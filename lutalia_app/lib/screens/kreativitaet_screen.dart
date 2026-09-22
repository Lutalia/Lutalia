import 'package:flutter/material.dart';
import 'lutalia_page.dart';
import 'recipes_screen.dart';
import 'shopping_lists_overview_screen.dart';

class KreativitaetScreen extends StatelessWidget {
  final VoidCallback onGoHome;
  final String userId; // Neu: Die User-ID wird hier ebenfalls entgegengenommen

  const KreativitaetScreen({
    super.key,
    required this.onGoHome,
    required this.userId, // Pflichtfeld gemacht
  });

  @override
  Widget build(BuildContext context) {
    return LutaliaPage(
      title: "Kreativität & Küche",
      showBack: true,
      onBackPressed: onGoHome,

      child: Column(
        children: [
          const SizedBox(height: 10),

          // ⭐ Bild oben
          Center(
            child: Image.asset(
              "assets/fee/küche.png",
              height: 150,
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 20),

          // ⭐ Buttons
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _tile(
                  label: "Rezepte",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // Hier wird die userId jetzt korrekt an den RecipesScreen übergeben
                        builder: (context) => RecipesScreen(userId: userId),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 14),

                _tile(
                  label: "Einkaufslisten",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ShoppingListsOverviewScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _tile({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFB3AA97),
            width: 1.4,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white,
              width: 1.4,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFB3AA97),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: "Cinzel",
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}