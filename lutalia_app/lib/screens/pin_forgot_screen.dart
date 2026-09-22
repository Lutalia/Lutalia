import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/theme.dart';
import '../screens/lutalia_page.dart';

class PinForgotScreen extends StatefulWidget {
  const PinForgotScreen({super.key});

  @override
  State<PinForgotScreen> createState() => _PinForgotScreenState();
}

class _PinForgotScreenState extends State<PinForgotScreen> {
  final passwordController = TextEditingController();

  String newPin = "";
  bool passwordVerified = false;
  String? error;

  Future<void> _verifyPassword() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: passwordController.text.trim(),
      );

      await user.reauthenticateWithCredential(cred);

      setState(() {
        passwordVerified = true;
        error = null;
      });
    } catch (_) {
      setState(() => error = "Falsches Passwort");
    }
  }

  void _tap(String n) {
    if (newPin.length >= 4) return;

    setState(() {
      newPin += n;
      error = null;
    });
  }

  void _delete() {
    if (newPin.isEmpty) return;

    setState(() {
      newPin = newPin.substring(0, newPin.length - 1);
    });
  }

  Future<void> _savePin() async {
    if (newPin.length != 4) {
      setState(() => error = "Bitte eine 4-stellige PIN eingeben");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .set({"pin": newPin}, SetOptions(merge: true));

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return LutaliaPage(
      title: "PIN vergessen",
      showBack: true,
      child: SingleChildScrollView(   // ⭐ Overflow-Fix
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ⭐ Schritt 1: Passwort eingeben
            if (!passwordVerified)
              Column(
                children: [
                  const Text(
                    "Bitte Passwort eingeben",
                    style: TextStyle(
                      fontFamily: "Cinzel",
                      fontSize: 20,
                      color: LutaliaTheme.espresso,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Passwort",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _verifyPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LutaliaTheme.latte,
                    ),
                    child: const Text(
                      "Weiter",
                      style: TextStyle(
                        fontFamily: "Cinzel",
                        color: LutaliaTheme.espresso,
                      ),
                    ),
                  ),

                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(error!, style: const TextStyle(color: Colors.red)),
                    ),
                ],
              ),

            // ⭐ Schritt 2: Neue PIN eingeben (nur 1×)
            if (passwordVerified)
              Column(
                children: [
                  const Text(
                    "Neue PIN eingeben",
                    style: TextStyle(
                      fontFamily: "Cinzel",
                      fontSize: 20,
                      color: LutaliaTheme.espresso,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ⭐ PIN Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      final filled = i < newPin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
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
                    Text(error!, style: const TextStyle(color: Colors.red)),

                  const SizedBox(height: 20),

                  _row(["1", "2", "3"]),
                  const SizedBox(height: 14),
                  _row(["4", "5", "6"]),
                  const SizedBox(height: 14),
                  _row(["7", "8", "9"]),
                  const SizedBox(height: 14),
                  _row(["", "0", "⌫"]),

                  const SizedBox(height: 20),

                  if (newPin.length == 4)
                    ElevatedButton(
                      onPressed: _savePin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LutaliaTheme.latte,
                      ),
                      child: const Text(
                        "PIN speichern",
                        style: TextStyle(
                          fontFamily: "Cinzel",
                          color: LutaliaTheme.espresso,
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: numbers.map((n) {
        if (n == "") return const SizedBox(width: 80);
        if (n == "⌫") return _button(icon: Icons.backspace, onTap: _delete);
        return _button(label: n, onTap: () => _tap(n));
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
              ? Icon(icon, color: LutaliaTheme.espresso)
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
