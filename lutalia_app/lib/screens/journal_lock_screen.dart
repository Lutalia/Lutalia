import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/theme.dart';
import '../screens/lutalia_page.dart';
import 'pin_change_screen.dart';
import 'pin_forgot_screen.dart';

class JournalLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const JournalLockScreen({super.key, required this.onUnlocked});

  @override
  State<JournalLockScreen> createState() => _JournalLockScreenState();
}

class _JournalLockScreenState extends State<JournalLockScreen> {
  final LocalAuthentication auth = LocalAuthentication();

  String enteredPin = "";
  String? error;
  String? savedPin;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadPinFromFirebase();
      setState(() {});

      if (savedPin != null) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _tryBiometric();
        });
      }
    });
  }

  Future<void> _loadPinFromFirebase() async {
    User? user;

    while (user == null) {
      await Future.delayed(const Duration(milliseconds: 100));
      user = FirebaseAuth.instance.currentUser;
    }

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (doc.exists && doc.data()!.containsKey("pin")) {
      savedPin = doc["pin"];
    }
  }

  // ⭐ Neue API für local_auth 3.x — nur noch localizedReason erlaubt
  Future<void> _tryBiometric() async {
    try {
      final didAuth = await auth.authenticate(
        localizedReason: "Entsperren",
      );

      if (didAuth && mounted) {
        widget.onUnlocked();
      }
    } catch (e) {
      print("Biometrie Fehler: $e");
    }
  }

  Future<void> _checkPin() async {
    if (enteredPin == savedPin) {
      widget.onUnlocked();
    } else {
      setState(() {
        error = "Falsche PIN";
        enteredPin = "";
      });
    }
  }

  void _tapNumber(String number) {
    if (enteredPin.length >= 4) return;

    setState(() {
      enteredPin += number;
      error = null;
    });

    if (enteredPin.length == 4) {
      Future.delayed(const Duration(milliseconds: 150), _checkPin);
    }
  }

  void _deleteNumber() {
    if (enteredPin.isEmpty) return;

    setState(() {
      enteredPin = enteredPin.substring(0, enteredPin.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LutaliaPage(
      title: "Willkommen zurück",
      showBack: false,
      showCalendar: false,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),

            const Text(
              "Bitte gib deine PIN ein",
              style: TextStyle(
                fontFamily: "Cinzel",
                fontSize: 18,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final filled = index < enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: filled ? LutaliaTheme.latte : Colors.transparent,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: LutaliaTheme.latte,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),

            if (error != null)
              Text(
                error!,
                style: const TextStyle(color: Colors.red),
              ),

            const SizedBox(height: 30),

            Column(
              children: [
                _row(["1", "2", "3"]),
                const SizedBox(height: 14),
                _row(["4", "5", "6"]),
                const SizedBox(height: 14),
                _row(["7", "8", "9"]),
                const SizedBox(height: 14),
                _row(["finger", "0", "⌫"]),
              ],
            ),

            const SizedBox(height: 40),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PinChangeScreen()),
                );
              },
              child: const Text(
                "PIN ändern",
                style: TextStyle(
                  fontFamily: "Cinzel",
                  fontSize: 16,
                  color: LutaliaTheme.espresso,
                ),
              ),
            ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PinForgotScreen()),
                );
              },
              child: const Text(
                "PIN vergessen?",
                style: TextStyle(
                  fontFamily: "Cinzel",
                  fontSize: 16,
                  color: LutaliaTheme.espresso,
                ),
              ),
            ),

            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _row(List<String> items) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items.map((item) {
        if (item == "finger") {
          return _button(icon: Icons.fingerprint, onTap: _tryBiometric);
        }
        if (item == "⌫") {
          return _button(icon: Icons.backspace, onTap: _deleteNumber);
        }
        return _button(label: item, onTap: () => _tapNumber(item));
      }).toList(),
    );
  }

  Widget _button({String? label, IconData? icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: LutaliaTheme.latte,
            width: 2,
          ),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: LutaliaTheme.espresso, size: 32)
              : Text(
                  label!,
                  style: const TextStyle(
                    fontFamily: "Cinzel",
                    fontSize: 26,
                    color: LutaliaTheme.espresso,
                  ),
                ),
        ),
      ),
    );
  }
}
