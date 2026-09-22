import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/theme.dart';
import 'lutalia_page.dart';

class PinSetupScreen extends StatefulWidget {
  final VoidCallback onPinCreated;

  const PinSetupScreen({
    super.key,
    required this.onPinCreated,
  });

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String pin = "";
  String confirmPin = "";
  bool isConfirming = false;
  String? error;

  void _tap(String n) {
    setState(() => error = null);

    if (!isConfirming) {
      if (pin.length < 4) pin += n;

      if (pin.length == 4) {
        setState(() => isConfirming = true);
      }
    } else {
      if (confirmPin.length < 4) confirmPin += n;

      if (confirmPin.length == 4) {
        _savePin();
      }
    }
  }

  void _delete() {
    setState(() {
      if (!isConfirming) {
        if (pin.isNotEmpty) pin = pin.substring(0, pin.length - 1);
      } else {
        if (confirmPin.isNotEmpty) {
          confirmPin = confirmPin.substring(0, confirmPin.length - 1);
        }
      }
    });
  }

  Future<void> _savePin() async {
    if (pin != confirmPin) {
      setState(() {
        error = "PINs stimmen nicht überein";
        pin = "";
        confirmPin = "";
        isConfirming = false;
      });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .set({"pin": pin}, SetOptions(merge: true));

    widget.onPinCreated();
  }

  @override
  Widget build(BuildContext context) {
    final current = isConfirming ? confirmPin : pin;

    return LutaliaPage(
      title: "PIN festlegen",
      showBack: false,
      child: Column(
        children: [
          const SizedBox(height: 20),

          Text(
            isConfirming ? "PIN bestätigen" : "Wähle eine 4-stellige PIN",
            style: const TextStyle(
              fontFamily: "Cinzel",
              fontSize: 20,
              color: LutaliaTheme.espresso,
            ),
          ),

          const SizedBox(height: 20),

          // ⭐ PIN DOTS (kompakt)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = i < current.length;
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
            Text(
              error!,
              style: const TextStyle(color: Colors.red),
            ),

          const SizedBox(height: 20),

          // ⭐ Kompaktes Zahlenfeld (kein Expanded)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _row(["1", "2", "3"]),
              const SizedBox(height: 12),
              _row(["4", "5", "6"]),
              const SizedBox(height: 12),
              _row(["7", "8", "9"]),
              const SizedBox(height: 12),
              _row(["", "0", "⌫"]),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _row(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: numbers.map((n) {
        if (n == "") return const SizedBox(width: 80);

        if (n == "⌫") {
          return _button(icon: Icons.backspace, onTap: _delete);
        }

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
