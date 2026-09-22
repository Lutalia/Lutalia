import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/lutalia_page.dart';
import 'login_screen.dart';
import 'journal_shell.dart';
import 'moodtracker_screen.dart';
import 'rituale_screen.dart';

class AchtsamkeitScreen extends StatelessWidget {
  final VoidCallback? onGoHome;

  const AchtsamkeitScreen({
    super.key,
    this.onGoHome,
  });

  Future<void> _openTagebuch(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const JournalShell()),
    );
  }

  Future<void> _openDankbarkeit(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    // ⭐ Dankbarkeit wird über JournalShell geöffnet,
    // damit Repository + Datum korrekt gesetzt werden.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const JournalShell(openGratitude: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LutaliaPage(
      title: "Achtsamkeit & Emotionen",
      showBack: true,
      onBackPressed: onGoHome,
      child: Column(
        children: [
          const SizedBox(height: 10),

          Image.asset(
            "assets/fee/balance.png",
            height: 180,
            fit: BoxFit.contain,
          ),

          const SizedBox(height: 20),

          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _item(context, "Tagebuch", () => _openTagebuch(context)),

                  _item(context, "Dankbarkeit", () {
                    _openDankbarkeit(context);
                  }),

                  _item(context, "Mood Tracker", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MoodTrackerScreen()),
                    );
                  }),

                  _item(context, "Rituale", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RitualeScreen()),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, String label, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB3AA97),
            surfaceTintColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          onPressed: onTap,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: "Cinzel",
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
