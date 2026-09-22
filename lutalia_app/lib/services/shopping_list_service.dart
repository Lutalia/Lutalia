import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShoppingListMeta {
  final String id;
  final String title;
  final String date;

  ShoppingListMeta({
    required this.id,
    required this.title,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date,
      };

  factory ShoppingListMeta.fromJson(Map<String, dynamic> json) => ShoppingListMeta(
        id: json['id'] ?? '',
        title: json['title'] ?? 'Einkaufsliste',
        date: json['date'] ?? '',
      );

  factory ShoppingListMeta.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShoppingListMeta(
      id: doc.id,
      title: data['title'] ?? 'Einkaufsliste',
      date: data['date'] ?? '',
    );
  }
}

class ShoppingItem {
  final String id;
  final String name;
  bool isDone;

  ShoppingItem({
    required this.id,
    required this.name,
    this.isDone = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isDone': isDone,
      };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        isDone: json['isDone'] ?? false,
      );

  factory ShoppingItem.fromMap(Map<String, dynamic> map) => ShoppingItem(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        isDone: map['isDone'] ?? false,
      );
}

class ShoppingListService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get _userId => _auth.currentUser?.uid;

  static const String _metaKeyLocal = 'lutalia_shopping_lists_meta_local';
  static String _itemsKeyLocal(String listId) => 'lutalia_shopping_items_local_$listId';

  // 1. Alle Einkaufslisten-Metadaten laden (Keine automatische Erstellung mehr!)
  static Future<List<ShoppingListMeta>> getAllLists() async {
    final uid = _userId;

    if (uid != null) {
      try {
        final querySnapshot = await _firestore
            .collection('users')
            .doc(uid)
            .collection('shopping_lists')
            .orderBy('createdAt', descending: true)
            .get();

        // Gibt nun sauber eine leere Liste zurück, wenn noch keine angelegt wurde
        return querySnapshot.docs.map((doc) => ShoppingListMeta.fromFirestore(doc)).toList();
      } catch (e) {
        return _getLocalLists();
      }
    } else {
      return _getLocalLists();
    }
  }

  static Future<List<ShoppingListMeta>> _getLocalLists() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_metaKeyLocal);
    
    if (data == null) {
      return []; // Keine automatische Liste mehr
    }

    List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((item) => ShoppingListMeta.fromJson(item)).toList();
  }

  // 2. Neue Einkaufsliste erstellen
  static Future<ShoppingListMeta> createNewList(String title) async {
    final uid = _userId;
    final formattedDate = _getCurrentDateFormatted();
    final cleanTitle = title.trim().isEmpty ? 'Einkaufsliste' : title.trim();

    if (uid != null) {
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('shopping_lists')
          .doc();

      final newMeta = ShoppingListMeta(
        id: docRef.id,
        title: cleanTitle,
        date: formattedDate,
      );

      await docRef.set({
        'title': cleanTitle,
        'date': formattedDate,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return newMeta;
    } else {
      final prefs = await SharedPreferences.getInstance();
      final lists = await _getLocalLists();
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final newMeta = ShoppingListMeta(
        id: newId,
        title: cleanTitle,
        date: formattedDate,
      );

      lists.insert(0, newMeta);
      await prefs.setString(_metaKeyLocal, jsonEncode(lists.map((l) => l.toJson()).toList()));
      await prefs.setString(_itemsKeyLocal(newId), jsonEncode([]));

      return newMeta;
    }
  }

  // 3. Einkaufsliste mitsamt Items löschen (jetzt fehlerfrei)
  static Future<void> deleteList(String listId) async {
    final uid = _userId;

    if (uid != null) {
      final listDoc = _firestore
          .collection('users')
          .doc(uid)
          .collection('shopping_lists')
          .doc(listId);

      // Alle Unter-Items löschen
      final itemsSnapshot = await listDoc.collection('items').get();
      for (var doc in itemsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Hauptdokument löschen
      await listDoc.delete();
    } else {
      final prefs = await SharedPreferences.getInstance();
      List<ShoppingListMeta> lists = await _getLocalLists();
      lists.removeWhere((l) => l.id == listId);
      await prefs.setString(_metaKeyLocal, jsonEncode(lists.map((l) => l.toJson()).toList()));
      await prefs.remove(_itemsKeyLocal(listId));
    }
  }

  // 4. Items für eine spezifische Liste laden
  static Future<List<ShoppingItem>> getItemsForList(String listId) async {
    final uid = _userId;

    if (uid != null) {
      try {
        final querySnapshot = await _firestore
            .collection('users')
            .doc(uid)
            .collection('shopping_lists')
            .doc(listId)
            .collection('items')
            .orderBy('createdAt', descending: false)
            .get();

        return querySnapshot.docs
            .map((doc) => ShoppingItem.fromMap(doc.data()))
            .toList();
      } catch (e) {
        return _getLocalItems(listId);
      }
    } else {
      return _getLocalItems(listId);
    }
  }

  static Future<List<ShoppingItem>> _getLocalItems(String listId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_itemsKeyLocal(listId));
    if (data == null) return [];
    List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((item) => ShoppingItem.fromJson(item)).toList();
  }

  // 5. Zutat zu einer spezifischen Liste hinzufügen
  static Future<void> addItemToList(String listId, String name) async {
    if (name.trim().isEmpty) return;
    final uid = _userId;
    final itemId = DateTime.now().microsecondsSinceEpoch.toString();
    final cleanName = name.trim();

    if (uid != null) {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('shopping_lists')
          .doc(listId)
          .collection('items')
          .doc(itemId)
          .set({
        'id': itemId,
        'name': cleanName,
        'isDone': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      final prefs = await SharedPreferences.getInstance();
      List<ShoppingItem> current = await _getLocalItems(listId);
      current.add(ShoppingItem(id: itemId, name: cleanName));
      await prefs.setString(_itemsKeyLocal(listId), jsonEncode(current.map((i) => i.toJson()).toList()));
    }
  }

  // 6. Kompatibilität für Rezepte: Erstellt automatisch eine Liste, falls noch keine da ist
  static Future<void> addItem(String name) async {
    if (name.trim().isEmpty) return;
    final lists = await getAllLists();
    String targetListId;
    
    if (lists.isEmpty) {
      final newList = await createNewList('Rezepte & Einkäufe');
      targetListId = newList.id;
    } else {
      targetListId = lists.first.id;
    }

    await addItemToList(targetListId, name);
  }

  static Future<void> addIngredientsFromRecipe(List<String> ingredientNames) async {
    for (var name in ingredientNames) {
      await addItem(name);
    }
  }

  // 7. Item abhaken
  static Future<void> toggleItem(String itemId) async {
    final uid = _userId;
    final lists = await getAllLists();

    for (var list in lists) {
      List<ShoppingItem> items = await getItemsForList(list.id);
      for (var item in items) {
        if (item.id == itemId) {
          item.isDone = !item.isDone;

          if (uid != null) {
            await _firestore
                .collection('users')
                .doc(uid)
                .collection('shopping_lists')
                .doc(list.id)
                .collection('items')
                .doc(itemId)
                .update({'isDone': item.isDone});
          } else {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              _itemsKeyLocal(list.id),
              jsonEncode(items.map((i) => i.toJson()).toList()),
            );
          }
          return;
        }
      }
    }
  }

  // 8. Item löschen
  static Future<void> deleteItem(String itemId) async {
    final uid = _userId;
    final lists = await getAllLists();

    for (var list in lists) {
      List<ShoppingItem> items = await getItemsForList(list.id);
      int initialLength = items.length;
      items.removeWhere((item) => item.id == itemId);
      
      if (items.length < initialLength) {
        if (uid != null) {
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('shopping_lists')
              .doc(list.id)
              .collection('items')
              .doc(itemId)
              .delete();
        } else {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            _itemsKeyLocal(list.id),
            jsonEncode(items.map((i) => i.toJson()).toList()),
          );
        }
        return;
      }
    }
  }

  // 9. Erledigte Items in einer bestimmten Liste löschen
  static Future<void> clearDoneInList(String listId) async {
    final uid = _userId;
    final items = await getItemsForList(listId);

    for (var item in items) {
      if (item.isDone) {
        if (uid != null) {
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('shopping_lists')
              .doc(listId)
              .collection('items')
              .doc(item.id)
              .delete();
        }
      }
    }

    if (uid == null) {
      final prefs = await SharedPreferences.getInstance();
      items.removeWhere((item) => item.isDone);
      await prefs.setString(_itemsKeyLocal(listId), jsonEncode(items.map((i) => i.toJson()).toList()));
    }
  }

  static String _getCurrentDateFormatted() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
  }
}