import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/theme.dart';
import '../screens/lutalia_page.dart';

class PinChangeScreen extends StatefulWidget {
  const PinChangeScreen({super.key});

  @override
  State<PinChangeScreen> createState() => _PinChangeScreenState();
}

class _PinChangeScreenState extends State<PinChangeScreen> {
  String oldPin = "";
  String newPin = "";
  String confirmPin = "";
  String? savedPin;

  bool enteringOld = true;
  bool enteringNew = false;
  bool confirming = false;

  String? error;

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  Future<void> _loadPin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (doc.exists && doc.data()!.containsKey("pin")) {
      savedPin = doc["pin"];
    }
  }

  void _tap(String n) {
    setState(() => error = null);

    if (enteringOld) {
      if (oldPin.length < 4) oldPin += n;
      if (oldPin.length == 4) _checkOldPin();
      return;
    }

    if (enteringNew) {
      if (newPin.length < 4) newPin += n;
      if (newPin.length == 4) {
        setState(() {
          enteringNew = false;
          confirming = true;
        });
      }
      return;
    }

    if (confirming) {
      if (confirmPin.length < 4) confirmPin += n;
      if (confirmPin.length == 4) _saveNewPin();
    }
  }

  void _delete() {
    setState(() {
      if (enteringOld && oldPin.isNotEmpty) {
        oldPin = oldPin.substring(0, oldPin.length - 1);
      } else if (enteringNew && newPin.isNotEmpty) {
        newPin = newPin.substring(0, newPin.length - 1);
      } else if (confirming && confirmPin.isNotEmpty) {
        confirmPin = confirmPin.substring(0, confirmPin.length - 1);
      }
    });
  }

  void _checkOldPin() {
    if (oldPin != savedPin) {
      setState(() {
        error = "Falsche alte PIN";
        oldPin = "";
      });
      return;
    }

    setState(() {
      enteringOld = false;
      enteringNew = true;
    });
  }

  Future<void> _saveNewPin() async {
    if (newPin != confirmPin) {
      setState(() {
        error = "PINs stimmen nicht überein";
        newPin = "";
        confirmPin = "";
        enteringNew = true;
        confirming = false;
      });
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
    String currentDots = enteringOld
        ? oldPin
        : enteringNew
            ? newPin
            : confirmPin;

    String title = enteringOld
        ? "Alte PIN eingeben"
        : enteringNew
            ? "Neue PIN eingeben"
            : "Neue PIN bestätigen";

    return LutaliaPage(
      title: "PIN ändern",
      showBack: true,
      child: Column(
        children: [
          const SizedBox(height: 20),

          Text(
            title,
            style: const TextStyle(
              fontFamily: "Cinzel",
              fontSize: 20,
              color: LutaliaTheme.espresso,
            ),
          ),

          const SizedBox(height: 30),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = i < currentDots.length;
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

          const SizedBox(height: 30),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _row(["1", "2", "3"]),
                const SizedBox(height: 14),
                _row(["4", "5", "6"]),
                const SizedBox(height: 14),
                _row(["7", "8", "9"]),
                const SizedBox(height: 14),
                _row(["", "0", "⌫"]),
              ],
            ),
          ),
        ],
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
