import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PinService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static Future<bool> hasPin() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final doc = await _db
        .collection("users")
        .doc(uid)
        .collection("settings")
        .doc("journal")
        .get();

    return doc.exists && doc.data()?["pin"] != null;
  }

  static Future<String?> getPin() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _db
        .collection("users")
        .doc(uid)
        .collection("settings")
        .doc("journal")
        .get();

    return doc.data()?["pin"];
  }

  static Future<void> savePin(String pin) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db
        .collection("users")
        .doc(uid)
        .collection("settings")
        .doc("journal")
        .set({
      "pin": pin,
    });
  }
}
