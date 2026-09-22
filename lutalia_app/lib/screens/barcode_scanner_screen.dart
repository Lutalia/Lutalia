import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import '../services/product_storage.dart';
import 'dart:developer';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool isProcessing = false;

  // ------------------------------------------------------------
  // 🔥 UPC-A → EAN-13 konvertieren
  // ------------------------------------------------------------
  String normalizeBarcode(String code) {
    if (code.length == 12) return "0$code"; // UPC-A → EAN-13
    return code;
  }

  // ------------------------------------------------------------
  // 🔥 Nutriments sicher extrahieren
  // ------------------------------------------------------------
  double extract(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      if (json.containsKey(k)) {
        final v = json[k];
        if (v is num) return v.toDouble();
        return double.tryParse(v.toString()) ?? 0;
      }
    }
    return 0;
  }

  // ------------------------------------------------------------
  // 🔥 Barcode verarbeiten
  // ------------------------------------------------------------
  Future<void> _handleBarcode(String? raw) async {
    if (raw == null) return;
    if (isProcessing) return;

    isProcessing = true;

    final code = normalizeBarcode(raw);
    log("📦 Scanne: $code");

    final config = ProductQueryConfiguration(
      code,
      version: ProductQueryVersion.v3,
      language: OpenFoodFactsLanguage.GERMAN,
      fields: [ProductField.ALL],
    );

    final result = await OpenFoodAPIClient.getProductV3(config);

    if (!mounted) return;

    // ------------------------------------------------------------
    // 🔥 Produkt gefunden
    // ------------------------------------------------------------
    if (result.product != null) {
      final p = result.product!;
      final n = p.nutriments?.toJson() ?? {};

      final product = {
        "id": code,
        "name": p.productName ?? "Unbekannt",
        "kcal": extract(n, ["energy-kcal_100g", "energy-kcal"]),
        "carbs": extract(n, ["carbohydrates_100g", "carbohydrates"]),
        "fat": extract(n, ["fat_100g", "fat"]),
        "protein": extract(n, ["proteins_100g", "proteins"]),
        "sugar": extract(n, ["sugars_100g", "sugars"]),
        "image": p.imageFrontUrl ?? "",
      };

      await ProductStorage.addProduct(product);

      if (!mounted) return;
      Navigator.pop(context, product);
      return;
    }

    // ------------------------------------------------------------
    // ❌ Produkt NICHT gefunden → manuelle Eingabe
    // ------------------------------------------------------------
    _showManualDialog(code);
  }

  // ------------------------------------------------------------
  // 🔥 Manuelle Eingabe wenn Produkt nicht existiert
  // ------------------------------------------------------------
  void _showManualDialog(String code) {
    final name = TextEditingController();
    final kcal = TextEditingController();
    final carbs = TextEditingController();
    final fat = TextEditingController();
    final protein = TextEditingController();
    final sugar = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Produkt nicht gefunden"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _input(name, "Name"),
              _input(kcal, "kcal / 100g", number: true),
              _input(carbs, "KH / 100g", number: true),
              _input(fat, "Fett / 100g", number: true),
              _input(protein, "Eiweiß / 100g", number: true),
              _input(sugar, "Zucker / 100g", number: true),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Abbrechen"),
            ),
            TextButton(
              onPressed: () async {
                final product = {
                  "id": code,
                  "name": name.text,
                  "kcal": double.tryParse(kcal.text) ?? 0,
                  "carbs": double.tryParse(carbs.text) ?? 0,
                  "fat": double.tryParse(fat.text) ?? 0,
                  "protein": double.tryParse(protein.text) ?? 0,
                  "sugar": double.tryParse(sugar.text) ?? 0,
                  "image": "",
                };

                await ProductStorage.addProduct(product);

                if (!mounted) return;
                Navigator.pop(context); // Dialog schließen
                Navigator.pop(context, product); // Produkt zurückgeben
              },
              child: const Text("Speichern"),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // 🔥 Input-Feld
  // ------------------------------------------------------------
  Widget _input(TextEditingController c, String label, {bool number = false}) {
    return TextField(
      controller: c,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
    );
  }

  // ------------------------------------------------------------
  // 🔥 UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Barcode scannen")),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final barcode = capture.barcodes.first;
          final raw = barcode.rawValue ?? barcode.displayValue;
          _handleBarcode(raw);
        },
      ),
    );
  }
}
