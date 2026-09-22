import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/theme.dart';
import 'journal_lock_screen.dart';
import 'journal_main_screen.dart';
import 'pin_setup_screen.dart';
import '../data/journal_repository.dart';
import 'dankbarkeit_screen.dart';

class JournalShell extends StatefulWidget {
  final bool openGratitude; // ⭐ NEU

  const JournalShell({
    super.key,
    this.openGratitude = false, // ⭐ Standard: aus
  });

  @override
  State<JournalShell> createState() => _JournalShellState();
}

class _JournalShellState extends State<JournalShell> {
  bool _unlocked = false;
  bool _loading = true;
  bool _hasPin = false;

  late final JournalRepository repository;

  @override
  void initState() {
    super.initState();
    repository = JournalRepository();
    _loadPinFromFirebase();
  }

  Future<void> _loadPinFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _loading = false;
        _hasPin = false;
      });
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final pin = doc.data()?["pin"];

    setState(() {
      _hasPin = pin != null && pin.toString().isNotEmpty;
      _loading = false;
    });
  }

  void _onUnlocked() {
    setState(() {
      _unlocked = true;
    });

    // ⭐ Wenn aus Achtsamkeit → Dankbarkeit öffnen
    if (widget.openGratitude) {
      Future.microtask(() {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DankbarkeitScreen(
              repository: repository,
              selectedDate: DateTime.now(),
            ),
          ),
        );
      });
    }
  }

  void _onPinCreated() {
    setState(() {
      _hasPin = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ⭐ Ladezustand
    if (_loading) {
      return const Scaffold(
        backgroundColor: LutaliaTheme.creme,
        body: Center(
          child: CircularProgressIndicator(color: LutaliaTheme.espresso),
        ),
      );
    }

    // ⭐ Noch keine PIN → Setup
    if (!_hasPin) {
      return PinSetupScreen(onPinCreated: _onPinCreated);
    }

    // ⭐ PIN vorhanden, aber noch nicht entsperrt → LockScreen
    if (!_unlocked) {
      return JournalLockScreen(onUnlocked: _onUnlocked);
    }

    // ⭐ ENTSPERRT → JournalMainScreen mit stabilem Back-Verhalten
    return WillPopScope(
      onWillPop: () async {
        // ⭐ Hardware-Zurück → zurück in AchtsamkeitScreen
        Navigator.of(context, rootNavigator: true).pop();
        return false;
      },
      child: Navigator(
        initialRoute: "/journalRoot",
        onGenerateRoute: (settings) {
          if (settings.name == "/journalRoot") {
            return MaterialPageRoute(
              builder: (_) => JournalMainScreen(repository: repository),
              settings: const RouteSettings(arguments: "journalRoot"),
            );
          }

          // ⭐ Dummy-Route für stabilen Back-Stack
          return MaterialPageRoute(
            builder: (_) => const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
