import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddFoodManualScreen extends StatefulWidget {
  final Map<String, dynamic>? initial;

  const AddFoodManualScreen({super.key, this.initial});

  @override
  State<AddFoodManualScreen> createState() => _AddFoodManualScreenState();
}

class _AddFoodManualScreenState extends State<AddFoodManualScreen> {
  late final TextEditingController name;
  late final TextEditingController grams;
  late final TextEditingController kcal;
  late final TextEditingController carbs;
  late final TextEditingController fat;
  late final TextEditingController protein;
  late final TextEditingController sugar;

  File? imageFile;
  String? imagePath;

  @override
  void initState() {
    super.initState();
    final data = widget.initial ?? {};

    name = TextEditingController(text: data["name"] ?? "");
    grams = TextEditingController(text: (data["grams"] ?? 100).toString());
    kcal = TextEditingController(text: (data["kcal"] ?? 0).toString());
    carbs = TextEditingController(text: (data["carbs"] ?? 0).toString());
    fat = TextEditingController(text: (data["fat"] ?? 0).toString());
    protein = TextEditingController(text: (data["protein"] ?? 0).toString());
    sugar = TextEditingController(text: (data["sugar"] ?? 0).toString());

    final img = data["image"]?.toString() ?? "";
    if (img.isNotEmpty) imagePath = img;
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
        imagePath = picked.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Lebensmittel",
                style: TextStyle(
                  fontFamily: "Cinzel",
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 20),

              // ⭐ Bildauswahl
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.grey.shade200,
                  ),
                  child: _buildImagePreview(),
                ),
              ),

              const SizedBox(height: 20),

              // ⭐ Eingabefelder
              _input(name, "Name"),
              _input(grams, "Gramm", number: true),
              _input(kcal, "Kalorien", number: true),
              _input(carbs, "Kohlenhydrate", number: true),
              _input(fat, "Fett", number: true),
              _input(protein, "Eiweiß", number: true),
              _input(sugar, "Zucker", number: true),

              const SizedBox(height: 20),

              // ⭐ Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text("Abbrechen"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text("Speichern"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 🔥 Bildanzeige
  // ------------------------------------------------------------

  Widget _buildImagePreview() {
    if (imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(imageFile!, fit: BoxFit.cover),
      );
    }

    if (imagePath != null && imagePath!.startsWith("http")) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(imagePath!, fit: BoxFit.cover),
      );
    }

    if (imagePath != null && File(imagePath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(File(imagePath!), fit: BoxFit.cover),
      );
    }

    return const Icon(Icons.add_a_photo, size: 40);
  }

  // ------------------------------------------------------------
  // 🔥 Speichern
  // ------------------------------------------------------------

  void _save() {
    Navigator.pop(context, {
      "name": name.text,
      "grams": double.tryParse(grams.text) ?? 100,
      "kcal": double.tryParse(kcal.text) ?? 0,
      "carbs": double.tryParse(carbs.text) ?? 0,
      "fat": double.tryParse(fat.text) ?? 0,
      "protein": double.tryParse(protein.text) ?? 0,
      "sugar": double.tryParse(sugar.text) ?? 0,
      "image": imagePath ?? "",
    });
  }

  // ------------------------------------------------------------
  // 🔥 Eingabefeld
  // ------------------------------------------------------------

  Widget _input(TextEditingController c, String label, {bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
