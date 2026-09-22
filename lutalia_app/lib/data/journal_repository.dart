import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/journal_entry.dart';

class JournalRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("Kein eingeloggter User – JournalRepository benötigt einen User.");
    }
    return user.uid;
  }

  // ⭐ Eintrag speichern
  Future<void> addEntry(JournalEntry entry) async {
    await _firestore
        .collection("users")
        .doc(_uid)
        .collection("journal")
        .doc(entry.id)
        .set(entry.toMap());
  }

  // ⭐ Eintrag aktualisieren
  Future<void> updateEntry(JournalEntry entry) async {
    await _firestore
        .collection("users")
        .doc(_uid)
        .collection("journal")
        .doc(entry.id)
        .update(entry.toMap());
  }

  // ⭐ Eintrag löschen
  Future<void> deleteEntry(String id) async {
    await _firestore
        .collection("users")
        .doc(_uid)
        .collection("journal")
        .doc(id)
        .delete();
  }

  // ⭐ Einträge eines Tages laden
  Future<List<JournalEntry>> entriesForDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection("users")
        .doc(_uid)
        .collection("journal")
        .where("date", isGreaterThanOrEqualTo: start)
        .where("date", isLessThan: end)
        .orderBy("date", descending: false)
        .get();

    return snapshot.docs
        .map((doc) => JournalEntry.fromMap(doc.data()))
        .toList();
  }

  // ⭐ Alle Einträge eines Monats laden (für Kalender)
  Future<List<JournalEntry>> entriesForMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    final snapshot = await _firestore
        .collection("users")
        .doc(_uid)
        .collection("journal")
        .where("date", isGreaterThanOrEqualTo: start)
        .where("date", isLessThan: end)
        .orderBy("date", descending: false)
        .get();

    return snapshot.docs
        .map((doc) => JournalEntry.fromMap(doc.data()))
        .toList();
  }
}
