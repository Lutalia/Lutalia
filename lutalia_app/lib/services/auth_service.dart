import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ⭐ Registrierung – mit Firestore-Dokument
  Future<String?> register(String email, String password) async {
    try {
      // 1. User in Firebase Auth anlegen
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = cred.user!.uid;

      // 2. Firestore-Dokument anlegen (WICHTIG!)
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "firstname": "",
        "lastname": "",
        "nickname": "",
        "birthday": "",
        "gender": "",
        "email": email.trim(),
        "profileImage": null,
        "createdAt": DateTime.now(),
      });

      // 3. User reloaden
      await _auth.currentUser?.reload();

      return null; // Erfolg
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Ein unbekannter Fehler ist aufgetreten.";
    }
  }

  // ⭐ Login
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await _auth.currentUser?.reload();

      final user = _auth.currentUser;
      if (user == null) {
        return "Login fehlgeschlagen. Bitte versuche es erneut.";
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Ein unbekannter Fehler ist aufgetreten.";
    }
  }

  // ⭐ Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ⭐ Aktueller User
  User? get currentUser => _auth.currentUser;
}
