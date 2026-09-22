import 'package:flutter/material.dart';
import '../screens/lutalia_page.dart' as lutalia;
import 'todo_lists_screen.dart'; // ⭐ Falls todo_lists_screen.dart im selben Ordner (screens) liegt: einfach 'todo_lists_screen.dart'
import 'goals_habits_screen.dart';

class AlltagScreen extends StatelessWidget {
  final VoidCallback onGoHome;
  final String userId;

  const AlltagScreen({
    super.key,
    required this.onGoHome,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return lutalia.LutaliaPage(
      title: "Organisation & Alltag",
      showBack: true,
      onBackPressed: onGoHome,
      child: Column(
        children: [
          const SizedBox(height: 10),

          // ⭐ Bild oben
          Center(
            child: Image.asset(
              "assets/fee/alltag.png",
              height: 150,
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 20),

          // ⭐ Buttons perfekt verteilt, kein Scrollen
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TodoListsScreen(userId: userId),
                      ),
                    );
                  },
                  child: _tile("To‑Do‑Listen"),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GoalsHabitsScreen(userId: userId),
                      ),
                    );
                  },
                  child: _tile("Ziele & Gewohnheiten"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ⭐ Doppelrahmen + Buttonfarbe #b3aa97 + weiße Schrift
  Widget _tile(String label) {
    return Container(
      width: double.infinity,

      // ⭐ äußerer Rahmen (Buttonfarbe)
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFB3AA97),
          width: 1.4,
        ),
      ),

      child: Container(
        // ⭐ innerer weißer Rahmen
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