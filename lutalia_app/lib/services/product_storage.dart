import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ProductStorage {
  static List<Map<String, dynamic>> _products = [];
  static bool _initialized = false;

  static const String _fileName = "products.json";

  // ⭐ Initialisieren (einmalig)
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/$_fileName");

    if (await file.exists()) {
      final content = await file.readAsString();
      _products = List<Map<String, dynamic>>.from(json.decode(content));
    } else {
      await file.writeAsString(json.encode([]));
      _products = [];
    }
  }

  // ⭐ Produkte laden (für SearchResultsScreen)
  static Future<List<Map<String, dynamic>>> loadProducts() async {
    await init();
    return List<Map<String, dynamic>>.from(_products);
  }

  // ⭐ Produkt hinzufügen / ersetzen
  static Future<void> addProduct(Map<String, dynamic> product) async {
    await init();

    _products.removeWhere((p) => p["id"] == product["id"]);
    _products.add(product);

    await _save();
  }

  // ⭐ Speichern
  static Future<void> _save() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/$_fileName");

    await file.writeAsString(json.encode(_products));
  }

  // ⭐ Einzelnes Produkt abrufen
  static Future<Map<String, dynamic>?> getProduct(String id) async {
    await init();
    try {
      return _products.firstWhere((p) => p["id"] == id);
    } catch (_) {
      return null;
    }
  }
}
