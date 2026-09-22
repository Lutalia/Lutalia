import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Prüfen, ob ein Rezept favorisiert ist
  static Future<bool> isFavorite(String userId, String recipeUrl) async {
    try {
      final docId = Uri.encodeComponent(recipeUrl);
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(docId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Favorit hinzufügen oder entfernen (Toggle)
  static Future<void> toggleFavorite(String userId, String recipeUrl, String recipeTitle) async {
    final docId = Uri.encodeComponent(recipeUrl);
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(docId);

    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.delete();
    } else {
      await docRef.set({
        'url': recipeUrl,
        'title': recipeTitle,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}