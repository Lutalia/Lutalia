import 'package:flutter/material.dart';
import '../screens/lutalia_page.dart';
import '../screens/food_tracking_screen.dart';
import '../screens/schritte_screen.dart';
import 'wasser_screen.dart';

// ⭐ Schlaftracking-Screen importieren (Pfad ggf. anpassen)
import '../screens/schlaf_tracking_screen.dart';

class GesundheitScreen extends StatelessWidget {
  final VoidCallback onGoHome;

  const GesundheitScreen({
    super.key,
    required this.onGoHome,
  });

  @override
  Widget build(BuildContext context) {
    return LutaliaPage(
      title: "Gesundheit & Balance",
      showBack: true,
      onBackPressed: onGoHome,

      child: Column(
        children: [
          const SizedBox(height: 6),

          Center(
            child: Image.asset(
              "assets/fee/waage.png",
              height: 146,
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 18),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _tile("Intervallfasten"),
                const SizedBox(height: 12),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FoodTrackingScreen(),
                      ),
                    );
                  },
                  child: _tile("Nährwerte & Energie"),
                ),
                const SizedBox(height: 12),

                // ⭐ Neu: Schlaftracking statt FemBalance
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SchlafTrackingScreen(),
                      ),
                    );
                  },
                  child: _tile("Schlaftracking"),
                ),
                const SizedBox(height: 12),

                // ⭐ SchritteScreen öffnen
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SchritteScreen(
                          onGoHome: () => Navigator.pop(context),
                        ),
                      ),
                    );
                  },
                  child: _tile("Schrittzähler"),
                ),
                const SizedBox(height: 12),

                // ⭐ Wasser‑Screen öffnen
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WasserScreen(
                          selectedDate: DateTime.now(),
                        ),
                      ),
                    );
                  },
                  child: _tile("Wasser‑Trink‑Erinnerung"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _tile(String label) {
    return Container(
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
    );
  }
}