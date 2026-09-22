import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/theme.dart';
import 'lutalia_page.dart';
import 'login_screen.dart';

class LogoutFlowScreen extends StatelessWidget {
  const LogoutFlowScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    // ⭐ Nach dem Logout: kompletter Stack löschen → zurück zum Login
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LutaliaPage(
      title: "Abmelden",
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Möchtest du dich wirklich abmelden?",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: "Cinzel",
              fontSize: 20,
              color: LutaliaTheme.espresso,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _logout(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: LutaliaTheme.espresso,
            ),
            child: const Text(
              "Ja, abmelden",
              style: TextStyle(
                fontFamily: "Cinzel",
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
